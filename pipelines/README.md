# pipelines — Azure Pipelines

CI/CD and security automation. Four pipelines plus reusable step templates.

- [Pipelines](#pipelines)
- [Reusable templates](#reusable-templates)
- [Required Azure DevOps setup](#required-azure-devops-setup)
- [Creating the pipelines](#creating-the-pipelines)
- [Variables to update](#variables-to-update)

## Pipelines

| File | Trigger | What it does |
|---|---|---|
| `ci.yml` | PRs & main (app changes) | For both services: install → typecheck → test → build; on **main** also build, **Trivy-scan**, and push images to ACR. |
| `cd.yml` | main (deploy changes) / after CI | `helm upgrade --install` to AKS through the `workflo-dev` environment. |
| `infra.yml` | PRs & main (`infra/**`) | `terraform fmt`/`validate`/`plan` on PRs; **gated `apply`** on main via the `workflo-infra-dev` environment. |
| `security.yml` | PRs & main | **gitleaks** (secret scan) + **Checkov** (Terraform/IaC scan). |

Images are tagged with the commit SHA and never published from PR builds.

## Reusable templates

| Template | Used by | Purpose |
|---|---|---|
| `templates/node-ci-steps.yml` | `ci.yml` | Node setup, install, typecheck, test, build (parameterized by `workingDir`) |
| `templates/docker-build-scan-push-steps.yml` | `ci.yml` | Build → Trivy scan (fail on HIGH/CRITICAL) → push to ACR |

## Required Azure DevOps setup

1. **Service connections** (Project Settings → Service connections):
   - `workflo-acr` — *Docker Registry* connection to your ACR.
   - `workflo-azure` — *Azure Resource Manager* connection (workload-identity federation preferred).
2. **Secret variable**: `JWT_SECRET` (mapped to `TF_VAR_jwt_secret` in `infra.yml`). Store it as a
   secret pipeline variable or in a variable group.
3. **Environments** (Pipelines → Environments), each with an **Approval** check for gating:
   - `workflo-dev` — used by `cd.yml`
   - `workflo-infra-dev` — used by `infra.yml` apply stage
4. The `workflo-azure` identity needs **AcrPush** on the registry and **Azure Kubernetes Service
   Cluster User** on the cluster.

## Creating the pipelines

In Azure DevOps: **Pipelines → New pipeline → (your repo) → Existing Azure Pipelines YAML file**,
then select each YAML (`pipelines/ci.yml`, `cd.yml`, `infra.yml`, `security.yml`). Name the CI
pipeline `ci` so `cd.yml`'s pipeline-completion trigger resolves.

## Variables to update

Match these to your Terraform outputs / names before the first run:

| Variable | In | Set to |
|---|---|---|
| `acrLoginServer` | `ci.yml` | `terraform output -raw acr_login_server` |
| `acrServiceConnection` | `ci.yml` | your Docker registry service connection name |
| `azureServiceConnection` | `cd.yml`, `infra.yml` | your ARM service connection name |
| `resourceGroup`, `aksCluster` | `cd.yml` | `rg-workflo-dev`, `aks-workflo-dev` |
| `imageRepository` | `cd.yml` | `<acrLoginServer>/workflo-api` |

> Local equivalent of the security gates: `.pre-commit-config.yaml` runs gitleaks + `terraform fmt`
> on commit. Install with `pip install pre-commit && pre-commit install`.
