# task-insights — AI insights microservice

A small **TypeScript/Express** service that analyzes text with **Azure AI Language** and returns
**sentiment** and **key phrases**. It exists to demonstrate operating an AI workload like any
other service — its own scaling, health checks, secret, and cost awareness.

- [Run it](#run-it)
- [Environment variables](#environment-variables)
- [Endpoints](#endpoints)
- [Scripts](#scripts)
- [Deployment](#deployment)

## Run it

From the repository root, `docker compose up --build` starts it on **http://localhost:8081**.

Directly:

```sh
cd apps/task-insights
npm install
npm run dev          # hot-reload dev server on PORT (default 8080)
```

Without AI credentials the service still starts and `/health` returns `200`, but `/ready` returns
`503` and `/insights` will fail — that's intentional.

## Environment variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `AI_LANGUAGE_ENDPOINT` | yes | — | Azure AI Language endpoint, e.g. `https://<name>.cognitiveservices.azure.com/` |
| `AI_LANGUAGE_KEY` | yes | — | Azure AI Language API key |
| `PORT` | no | `8080` | Port the server listens on |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | no | — | Enables telemetry export; no-op otherwise |

Provision the AI Language resource with Terraform ([infra](../../infra/README.md)); in AKS the key
is delivered from Key Vault and the endpoint is passed as config.

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Liveness — `200` while the process is up |
| GET | `/ready` | Readiness — `200` only when AI credentials are configured, else `503` |
| POST | `/insights` | Analyze text — see below |

### `POST /insights`

Request:

```json
{ "text": "The new dashboard is fast and the team loves it." }
```

Response:

```json
{
  "sentiment": "positive",
  "confidenceScores": { "positive": 0.98, "neutral": 0.01, "negative": 0.01 },
  "keyPhrases": ["new dashboard", "team"]
}
```

- `400` if `text` is missing or not a string.
- `502` if the upstream Azure AI call fails.

Quick test:

```sh
curl -s -X POST localhost:8081/insights \
  -H 'content-type: application/json' \
  -d '{"text":"This release is great but the docs are confusing."}'
```

## Scripts

```sh
npm run dev         # hot-reload dev server
npm run build       # compile to dist/ (fails on type errors)
npm start           # run compiled server
npm run typecheck   # type-check only
```

## Deployment

This service **reuses the same generic Helm chart** as the api
([deploy/charts/api](../../deploy/README.md)) via the override file
`deploy/values/task-insights-dev.yaml` (sets `fullnameOverride`, its image, its Key Vault secret
mapping, and `AI_LANGUAGE_ENDPOINT`). It runs as its own workload identity with read access only
to the AI key.
