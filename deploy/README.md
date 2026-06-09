# Deploy (Helm → AKS)

Helm chart for the api service. Deploys with **Workload Identity** (no secrets in the cluster)
and pulls config from **Key Vault via the Secrets Store CSI driver**.

```
deploy/
├── charts/api/        # the chart (Deployment, Service, Ingress, HPA, SA, SecretProviderClass)
└── values/
    └── dev.yaml       # per-environment overrides (staging/prod added in Phase 5)
```

## Cluster prerequisites

1. **Secrets Store CSI driver** — enabled by Terraform (`key_vault_secrets_provider` addon on AKS).
2. **Ingress controller** — install ingress-nginx (or enable the AKS app-routing addon):
   ```sh
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
   ```
3. **cert-manager** (for the TLS cert referenced in values) — install it and a `letsencrypt-prod`
   ClusterIssuer, or set `ingress.tls.enabled=false` to skip TLS while testing.

## Fill values from Terraform outputs

```sh
cd ../infra/envs/dev
terraform output -raw api_identity_client_id   # -> serviceAccount.clientId
terraform output -raw key_vault_name           # -> keyVault.name
terraform output -raw tenant_id                # -> keyVault.tenantId
terraform output -raw acr_login_server         # -> image.repository prefix
```

Put these into `deploy/values/dev.yaml`.

## Deploy

```sh
az aks get-credentials -g rg-workflo-dev -n aks-workflo-dev
helm upgrade --install workflo-api deploy/charts/api \
  --namespace workflo --create-namespace \
  --values deploy/values/dev.yaml \
  --set image.tag=<commit-sha> \
  --wait
```

In CI/CD this is automated by `pipelines/cd.yml`.

## Verify

```sh
kubectl -n workflo get pods,svc,hpa,ingress
kubectl -n workflo get secret workflo-api-secrets -o jsonpath='{.data}' | jq 'keys'   # DB_URL, JWT_SECRET
kubectl -n workflo port-forward svc/workflo-api 8080:80 &
curl localhost:8080/health   # 200
curl localhost:8080/ready    # 200 once Cosmos is reachable
```

## How the secret flow works

1. Terraform stores `DB-URL`, `JWT-SECRET` in Key Vault and grants the api's user-assigned
   identity the **Key Vault Secrets User** role.
2. The pod runs as a ServiceAccount annotated with that identity's client ID and labeled
   `azure.workload.identity/use: "true"`.
3. Mounting the CSI volume authenticates via Workload Identity, pulls the secrets, and the
   `secretObjects` block syncs them into the `workflo-api-secrets` Kubernetes Secret.
4. The Deployment consumes that Secret via `envFrom`, so the app sees `DB_URL` / `JWT_SECRET`
   as ordinary environment variables — exactly what `config.ts` reads.
