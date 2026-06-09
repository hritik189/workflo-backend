# deploy — Helm (AKS)

Deploys the services to AKS using **Workload Identity** (no credentials in the cluster) and
**Key Vault via the Secrets Store CSI driver** for configuration.

- [Layout](#layout)
- [Cluster prerequisites](#cluster-prerequisites)
- [Step 1 — Fill values from Terraform](#step-1--fill-values-from-terraform)
- [Step 2 — Deploy](#step-2--deploy)
- [Step 3 — Verify](#step-3--verify)
- [Values reference](#values-reference)
- [How the secret flow works](#how-the-secret-flow-works)
- [Rollback](#rollback)

## Layout

```
deploy/
├── charts/api/        # one GENERIC chart: Deployment, Service, Ingress, HPA,
│                      # probes, ServiceAccount, Key Vault SecretProviderClass
└── values/
    ├── dev.yaml                  # api (dev)
    └── task-insights-dev.yaml    # task-insights reuses the same chart (fullnameOverride)
```

The chart is intentionally generic, so both services use it — `task-insights` just supplies a
different values file.

## Cluster prerequisites

1. **Secrets Store CSI driver** — enabled by Terraform (AKS `key_vault_secrets_provider` addon).
2. **Ingress controller** (for the api's ingress):
   ```sh
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
   ```
3. **cert-manager** (for the TLS cert referenced in values) + a `letsencrypt-prod` ClusterIssuer —
   or set `ingress.tls.enabled=false` while testing.

Get cluster access:

```sh
$(cd ../infra/envs/dev && terraform output -raw aks_get_credentials_cmd)
```

## Step 1 — Fill values from Terraform

From `infra/envs/dev`, read the outputs and put them into the values files:

| Terraform output | Goes into |
|---|---|
| `api_identity_client_id` | `dev.yaml` → `serviceAccount.clientId` |
| `task_insights_identity_client_id` | `task-insights-dev.yaml` → `serviceAccount.clientId` |
| `key_vault_name` | both → `keyVault.name` |
| `tenant_id` | both → `keyVault.tenantId` |
| `acr_login_server` | both → `image.repository` prefix |
| `ai_language_endpoint` | `task-insights-dev.yaml` → `env.AI_LANGUAGE_ENDPOINT` |

## Step 2 — Deploy

```sh
# api
helm upgrade --install workflo-api deploy/charts/api \
  --namespace workflo --create-namespace \
  --values deploy/values/dev.yaml \
  --set image.tag=<commit-sha>

# task-insights (same chart, different values)
helm upgrade --install workflo-task-insights deploy/charts/api \
  --namespace workflo \
  --values deploy/values/task-insights-dev.yaml \
  --set image.tag=<commit-sha>
```

In CI/CD this is automated by [`pipelines/cd.yml`](../pipelines/README.md).

## Step 3 — Verify

```sh
kubectl -n workflo get pods,svc,hpa,ingress
kubectl -n workflo get secret workflo-api-secrets -o jsonpath='{.data}' | jq 'keys'  # DB_URL, JWT_SECRET, …
kubectl -n workflo port-forward svc/workflo-api 8080:80 &
curl localhost:8080/health   # 200
curl localhost:8080/ready    # 200 once Cosmos is reachable
```

## Values reference

| Key | Purpose |
|---|---|
| `image.repository`, `image.tag` | Container image to run |
| `serviceAccount.name`, `serviceAccount.clientId` | Workload Identity binding |
| `keyVault.name`, `keyVault.tenantId` | Key Vault to pull secrets from |
| `keyVault.secrets[]` | Map of `secretName` (in Key Vault) → `envName` (in the pod) |
| `env` | Plain (non-secret) environment variables |
| `ingress.*` | Enable/host/TLS for the api; disabled for task-insights |
| `autoscaling.*` | HPA min/max replicas and CPU target |
| `resources`, `probes` | Limits and liveness/readiness probe settings |
| `fullnameOverride` | Used by task-insights to get its own resource names |

## How the secret flow works

1. Terraform stores secrets in Key Vault and grants the service's identity the **Key Vault Secrets
   User** role.
2. The pod runs as a ServiceAccount annotated with that identity's client ID and labeled
   `azure.workload.identity/use: "true"`.
3. Mounting the CSI volume authenticates via Workload Identity, pulls the secrets, and
   `secretObjects` syncs them into a Kubernetes Secret.
4. The Deployment consumes that Secret via `envFrom`, so the app sees them as environment
   variables. Nothing sensitive lives in the chart or in plaintext in the cluster.

## Rollback

```sh
helm history workflo-api -n workflo
helm rollback workflo-api <revision> -n workflo
```
