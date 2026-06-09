# Workflo — DevOps Platform

A task-board REST API (**`apps/api`**) plus an AI insights microservice (**`apps/task-insights`**),
deployed to **Azure Kubernetes Service** — provisioned by **Terraform**, delivered through
**Azure Pipelines**, secured with **DevSecOps gates**, and observed with **Azure-native monitoring**.

The application is intentionally simple; the value is the platform around it. See
[`DEVOPS.md`](./DEVOPS.md) for the design rationale and phased roadmap.

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

## The stack

| Layer | Tech | Where |
|-------|------|-------|
| Services | Node 20 / TypeScript / Express | `apps/api`, `apps/task-insights` |
| Containers | Multi-stage Docker, distroless, non-root | `apps/*/Dockerfile`, `docker-compose.yml` |
| IaC | Terraform (`azurerm`), reusable modules + shared stack, remote state | `infra/` |
| Cloud | AKS, ACR, Cosmos DB (Mongo API), Key Vault, AI Language, Log Analytics, App Insights | `infra/modules`, `infra/stack` |
| CI/CD | Azure Pipelines (build/test/scan/push, gated Terraform, Helm deploy) | `pipelines/` |
| Delivery | Helm chart, HPA, probes, Workload Identity, Key Vault CSI | `deploy/` |
| Observability | App Insights (OpenTelemetry) + Container Insights, SLOs, alerts | `monitoring/`, `infra/modules/alerts` |
| Security | Trivy (images), Checkov (IaC), gitleaks (secrets), pre-commit | `pipelines/security.yml`, `.pre-commit-config.yaml` |
| FinOps | Per-environment cost budget + alerts | `infra/stack` |

## Quickstart (local)

```sh
docker compose up --build
curl localhost:8080/health     # api liveness
curl localhost:8080/ready      # api readiness (200 once Mongo is up)
curl localhost:8081/health     # task-insights liveness
```

Per service (from `apps/<service>`): `npm run dev | build | start | typecheck`.

## Deploy to Azure

1. **Provision** — `infra/` ([runbook](./infra/README.md)): `terraform init/plan/apply` per env.
2. **CI** — `pipelines/ci.yml` builds, scans (Trivy), and pushes images to ACR.
3. **Deploy** — `pipelines/cd.yml` / `deploy/` ([runbook](./deploy/README.md)): Helm release to AKS.

Environments: `dev`, `staging`, `prod` — thin wrappers over the shared `infra/stack` module.

## Docs

- [`DEVOPS.md`](./DEVOPS.md) — full plan, decisions, roadmap
- [`infra/README.md`](./infra/README.md) — Terraform runbook
- [`deploy/README.md`](./deploy/README.md) — Helm / AKS deploy
- [`monitoring/README.md`](./monitoring/README.md) + [`monitoring/slo.md`](./monitoring/slo.md) — observability & SLOs
- [`load-test/README.md`](./load-test/README.md) — k6 / HPA validation
- [`apps/api/README.md`](./apps/api/README.md) — API endpoints
