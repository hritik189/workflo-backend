# Workflo — DevOps Platform

A small **task-board REST API** and an **AI insights microservice**, taken all the way from
source code to a **secured, observable, auto-scaling deployment on Azure Kubernetes Service** —
provisioned with **Terraform**, delivered through **Azure Pipelines**, and monitored with
**Azure-native observability**.

The applications are deliberately simple. **The project is the platform around them**: how the
code is containerized, provisioned, deployed, secured, observed, and scaled.

---

## Table of contents

- [What this demonstrates](#what-this-demonstrates)
- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Quickstart — run locally](#quickstart--run-locally)
- [Deploy to Azure](#deploy-to-azure)
- [Configuration reference](#configuration-reference)
- [How the secret flow works](#how-the-secret-flow-works)
- [Documentation index](#documentation-index)

---

## What this demonstrates

| Capability | How |
|---|---|
| Containerization | Multi-stage, distroless, non-root images for both services |
| Infrastructure as Code | Terraform — reusable modules, a shared composition, and 3 environments, with remote state |
| CI/CD | Azure Pipelines: build → test → scan → push, gated Terraform, Helm deploy |
| Kubernetes | AKS with HPA, health probes, Workload Identity, Key Vault CSI |
| Observability | App Insights + Container Insights, SLOs, alerts-as-code, load testing |
| DevSecOps | Image, IaC, and secret scanning in CI + local pre-commit hooks |
| FinOps | Per-environment cost budgets with alerts |
| AI-Ops | An Azure AI Language microservice, operationalized like any other workload |

---

## Architecture

```
                              Internet
                                 │  HTTPS
                        ┌────────▼─────────┐
                        │  Ingress (NGINX) │   TLS via cert-manager
                        └────────┬─────────┘
                ┌────────────────┴─────────────────┐
        ┌───────▼────────┐                  ┌───────▼─────────┐
        │  api  (K8s Svc)│ ── internal ───▶ │ task-insights   │
        │  Express / TS  │                  │ (AI microservice)│
        │  + HPA + probes│                  │ + HPA + probes  │
        └───────┬────────┘                  └───────┬─────────┘
                │                                   │
       ┌────────▼──────────┐              ┌─────────▼──────────┐
       │ Cosmos DB         │              │ Azure AI Language  │
       │ (MongoDB API)     │              │ (Cognitive Service)│
       └───────────────────┘              └────────────────────┘

  Secrets   :  Key Vault ──(CSI driver + Workload Identity)──▶ pods
  Images    :  ACR ──(kubelet managed-identity pull)──▶ AKS
  Telemetry :  pods ──▶ App Insights + Container Insights ──▶ Log Analytics ──▶ Alerts
  IaC state :  Terraform ──▶ Azure Storage backend (remote state + lock)
```

**In words:** traffic enters through an ingress controller and reaches the **api** service, which
stores data in **Cosmos DB** (via the MongoDB API). The api can call **task-insights**, which
analyzes text with **Azure AI Language**. Pods authenticate to Azure with **Workload Identity**
(no stored credentials) and read secrets from **Key Vault** through the CSI driver. Telemetry
flows to **Application Insights / Log Analytics**, where alerts and SLOs live.

---

## Tech stack

| Layer | Technology |
|---|---|
| Language / runtime | TypeScript, Node.js 20, Express |
| Data | Azure Cosmos DB (MongoDB API) |
| AI | Azure AI Language (Cognitive Services) |
| Containers | Docker (multi-stage, distroless), docker-compose |
| Orchestration | Azure Kubernetes Service (AKS), Helm |
| IaC | Terraform (`azurerm`) |
| CI/CD | Azure Pipelines |
| Observability | Application Insights, Container Insights, Log Analytics (OpenTelemetry) |
| Security | Trivy, Checkov, gitleaks, pre-commit |

---

## Repository layout

Each directory has its own README with full detail — start there for anything specific.

| Path | What's inside | README |
|---|---|---|
| `apps/api/` | Task-board REST API | [apps/api/README.md](apps/api/README.md) |
| `apps/task-insights/` | AI insights microservice | [apps/task-insights/README.md](apps/task-insights/README.md) |
| `infra/` | Terraform (modules, shared stack, environments) | [infra/README.md](infra/README.md) |
| `deploy/` | Helm chart + per-environment values | [deploy/README.md](deploy/README.md) |
| `pipelines/` | Azure Pipelines (CI/CD, Terraform, security) | [pipelines/README.md](pipelines/README.md) |
| `monitoring/` | SLOs and KQL queries | [monitoring/README.md](monitoring/README.md) |
| `load-test/` | k6 load test | [load-test/README.md](load-test/README.md) |
| `docker-compose.yml` | Local stack: api + MongoDB + task-insights | — |
| `DEVOPS.md` | Design rationale, decisions, build order | [DEVOPS.md](DEVOPS.md) |

---

## Prerequisites

| To do this | You need |
|---|---|
| Run locally | [Docker](https://docs.docker.com/get-docker/) (with Compose), or Node.js 20 + a MongoDB |
| Provision Azure | [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), [Terraform ≥ 1.5](https://developer.hashicorp.com/terraform/install), an Azure subscription |
| Deploy to AKS | [kubectl](https://kubernetes.io/docs/tasks/tools/), [Helm 3](https://helm.sh/docs/intro/install/) |
| Run CI/CD | An Azure DevOps organization/project |

---

## Quickstart — run locally

The fastest way to see both services running, with a real MongoDB, using only Docker:

```sh
git clone https://github.com/hritik189/workflo-backend.git
cd workflo-backend

docker compose up --build
```

Then, in another terminal:

```sh
curl localhost:8080/health     # api liveness        -> {"status":"ok",...}
curl localhost:8080/ready      # api readiness        -> ready once Mongo is connected
curl localhost:8081/health     # task-insights liveness
```

`task-insights`'s `/insights` endpoint needs Azure AI Language credentials; set
`AI_LANGUAGE_ENDPOINT` and `AI_LANGUAGE_KEY` in `docker-compose.yml` to exercise it (otherwise
`/ready` returns 503 by design). See [apps/task-insights/README.md](apps/task-insights/README.md).

### Or run a single service directly

```sh
cd apps/api          # or apps/task-insights
npm install
npm run dev          # hot-reload dev server
# other scripts: npm run build | npm start | npm run typecheck
```

---

## Deploy to Azure

A high-level walkthrough; each step links to a detailed runbook.

1. **Provision infrastructure** — [`infra/`](infra/README.md)
   Bootstrap remote state, set your values in `infra/envs/dev/dev.tfvars`, then:
   ```sh
   cd infra/envs/dev
   terraform init -backend-config=backend.hcl
   terraform apply -var-file=dev.tfvars
   ```
   This creates AKS, ACR, Cosmos DB, Key Vault, monitoring, and AI Language.

2. **Set up pipelines** — [`pipelines/`](pipelines/README.md)
   Create the Azure DevOps service connections, the `JWT_SECRET` variable, and the gated
   environments, then point pipelines at `ci.yml`, `cd.yml`, `infra.yml`, `security.yml`.

3. **Build & push images** — CI (`ci.yml`) builds, scans (Trivy), and pushes both images to ACR.

4. **Deploy to AKS** — [`deploy/`](deploy/README.md)
   Fill the Helm values from `terraform output`, then `helm upgrade --install` (or let `cd.yml`
   do it).

5. **Observe** — [`monitoring/`](monitoring/README.md) — dashboards, SLOs, alerts;
   [`load-test/`](load-test/README.md) to watch the HPA scale.

---

## Configuration reference

### Application environment variables

| Variable | Service | Required | Description |
|---|---|---|---|
| `DB_URL` | api | yes | MongoDB / Cosmos connection string (DB name is `workflo_DB`) |
| `JWT_SECRET` | api | yes | Secret used to sign JWTs |
| `PORT` | both | no | Listen port (default `8080`) |
| `ORIGIN` | api | no | Allowed CORS origin |
| `NODE_ENV` | both | no | `production` enables secure cookies |
| `AI_LANGUAGE_ENDPOINT` | task-insights | yes | Azure AI Language endpoint URL |
| `AI_LANGUAGE_KEY` | task-insights | yes | Azure AI Language API key |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | both | no | Enables telemetry export (no-op if unset) |

In Azure, the secret values come from **Key Vault**, not from files — see below.

### Terraform variables (per environment, in `infra/envs/<env>/<env>.tfvars`)

| Variable | Description |
|---|---|
| `subscription_id` | Target Azure subscription |
| `acr_name`, `key_vault_name`, `cosmos_account_name`, `ai_language_name` | **Globally-unique** resource names |
| `alert_email` | Where monitoring/budget alerts go |
| `jwt_secret` | Supplied out-of-band: `export TF_VAR_jwt_secret="$(openssl rand -hex 32)"` |

### Azure DevOps (pipelines)

Service connections `workflo-acr` (Docker registry) and `workflo-azure` (ARM), a secret variable
`JWT_SECRET`, and gated environments — full setup in [pipelines/README.md](pipelines/README.md).

---

## How the secret flow works

No secret is ever stored in the cluster or in a file in Azure:

1. **Terraform** writes `DB_URL`, `JWT_SECRET`, the AI key, and the App Insights connection string
   into **Key Vault**, and grants each service's managed identity read access.
2. Each pod runs as a Kubernetes **ServiceAccount** federated to that identity (**Workload
   Identity**) — so it gets Azure tokens with no client secret.
3. The **Key Vault CSI driver** pulls the secrets at pod start and syncs them into a Kubernetes
   Secret, which the Deployment exposes as ordinary environment variables.

So the app just reads `process.env.DB_URL`, while the actual value lives only in Key Vault.

---

## Documentation index

- [DEVOPS.md](DEVOPS.md) — design rationale, decisions, and build order
- [apps/api/README.md](apps/api/README.md) — task-board API: endpoints, run, configure
- [apps/task-insights/README.md](apps/task-insights/README.md) — AI service: `/insights`, configure
- [infra/README.md](infra/README.md) — Terraform: provision Azure step by step
- [deploy/README.md](deploy/README.md) — Helm: deploy to AKS step by step
- [pipelines/README.md](pipelines/README.md) — Azure Pipelines: set up CI/CD
- [monitoring/README.md](monitoring/README.md) — SLOs, KQL, alerts
- [load-test/README.md](load-test/README.md) — k6 + HPA validation

## License

MIT.
