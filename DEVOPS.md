# Workflo — DevOps Platform Project

> A task-board API plus an AI insights microservice, deployed to **Azure Kubernetes Service** —
> provisioned by **Terraform**, delivered through **Azure Pipelines**, with **Azure-native
> observability** and **DevSecOps gates**.

This document captures the architecture, decisions, and build order. The application is
intentionally simple — the value is the platform around it.

---

## 1. The narrative (what this project proves)

> *"I can take an application from source code to a secured, observable, auto-scaling
> production deployment on Azure — with infrastructure as code, automated delivery,
> secret management, cost awareness, and the ability to operationalize an AI workload."*

The task-board API is just the **workload**; its business logic does not grow. One small AI
microservice is added — not for features, but to justify multi-service Kubernetes and to
demonstrate **AI-Ops + FinOps**.

### Decisions locked in
| Decision | Choice | Rationale |
|---|---|---|
| Database | **Azure Cosmos DB for MongoDB** | Fully Azure-native, Terraform-provisioned, **zero app code change** — the API already reads a `DB_URL` connection string, injected from Key Vault. |
| Monitoring | **Azure-native** | App Insights + Container Insights + Azure Monitor/Log Analytics. Tightest fit with the all-Azure story, least to self-operate. |
| AI | **One** microservice via **Azure AI Language** | Operationalized properly (Key Vault secret, own scaling, cost alerts) rather than features sprinkled into the main API. |

---

## 2. Architecture

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

**No pod holds a static credential** — Key Vault CSI + Workload Identity supply secrets; ACR
pulls use the cluster's managed identity.

---

## 3. Repository structure

```
workflo-backend/
├── apps/
│   ├── api/                  # task-board API (Express/TS) + Dockerfile
│   └── task-insights/        # AI microservice (Azure AI Language) + Dockerfile
├── infra/                    # Terraform
│   ├── modules/              # network, acr, aks, cosmosdb, keyvault, ai_language, monitoring, alerts
│   ├── stack/                # shared composition consumed by every environment
│   └── envs/{dev,staging,prod}  # thin per-env wrappers + tfvars + backend
├── deploy/                   # Helm
│   ├── charts/api/           # one generic chart
│   └── values/               # dev.yaml, task-insights-dev.yaml
├── pipelines/                # Azure Pipelines: ci, cd, infra, security + templates/
├── monitoring/               # SLOs + KQL queries
├── load-test/                # k6
└── docker-compose.yml        # local: api + Mongo + task-insights
```

---

## 4. Azure resources (provisioned by Terraform)

| Resource | Purpose | Notes |
|---|---|---|
| AKS | Run the two services | Workload Identity, Container Insights, Key Vault CSI addon, autoscaling node pool |
| ACR | Private image registry | AKS pulls via kubelet managed identity (no admin creds) |
| Cosmos DB for MongoDB | App database | Connection string → Key Vault → pod env (`DB_URL`) |
| Key Vault | All secrets | RBAC-authorized; surfaced via CSI driver |
| Azure AI Language | task-insights backend | Cognitive Services account; key in Key Vault |
| Log Analytics + App Insights | Central telemetry | App instrumented via OpenTelemetry |
| VNet + subnet + NSG | Network isolation | AKS in a dedicated subnet, Calico network policy |
| Storage Account | Terraform remote state | Versioned container + blob-lease locking |
| Cost budget | FinOps | Per-environment budget with email alerts |

---

## 5. Component breakdown

- **Docker** — multi-stage builds → distroless, non-root images; `docker-compose` runs the full
  stack locally.
- **Terraform** — reusable modules composed in a shared `stack/`, with thin `dev/staging/prod`
  wrappers differing only by sizing/hardening; remote state with locking.
- **Azure Pipelines** — `ci.yml` (install → typecheck → test → build → Trivy scan → push to ACR);
  `cd.yml` (Helm deploy through a gated environment); `infra.yml` (terraform `plan` on PR, gated
  `apply` on main); `security.yml` (gitleaks + Checkov). Reusable step templates.
- **Kubernetes (Helm)** — Deployment/Service/Ingress, HPA, resource limits, liveness/readiness
  probes, hardened securityContext; secretless via Key Vault CSI + Workload Identity.
- **Observability** — App Insights (OpenTelemetry) + Container Insights; alerts-as-code
  (response-time + 5xx rate); a published SLO with KQL SLIs; k6 load test to exercise the HPA.
- **DevSecOps** — Trivy (images), Checkov (IaC), gitleaks (secrets), plus local pre-commit hooks.

---

## 6. Environments

Three environments, identical topology, differing only by `tfvars` and Helm values:

| Env | Shape |
|-----|-------|
| **dev** | Smallest/cheapest SKUs, single node, low budget |
| **staging** | Prod-like, mid sizing, gated deploy |
| **prod** | Zone-capable sizing, Premium ACR, 90-day log retention, Key Vault purge protection, larger budget |

---

## 7. Build order (phased)

Each phase is committable and demoable on its own:

0. **App-ready** — mono-repo restructure, `/health` + `/ready`, build pipeline, Docker, compose.
1. **IaC** — Terraform modules + shared stack + remote state.
2. **CI** — build, test, scan, push to ACR.
3. **CD** — Helm chart, Key Vault CSI secrets, ingress, probes, HPA.
4. **Observability** — App Insights + Container Insights, dashboards/SLO, alerts, load test.
5. **DevSecOps + AI + multi-env** — security gates, the `task-insights` service, cost budget,
   staging/prod.

After Phase 3 the system is deployed and demoable; everything after is depth.

---

## 8. Out of scope (deliberately)
- Growing the task-board feature set — the app is the workload, not the project.
- More than one Cognitive Service — one AI microservice, done well, beats several done shallowly.

---

## Note on local validation

`terraform`, `helm`, `az`, and `kubectl` were not available in the authoring sandbox, so those
layers are validated by structure and by the services' builds — run `terraform validate`,
`helm lint`, and the pipelines in your own environment before deploying.
