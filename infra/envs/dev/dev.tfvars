# ---- dev environment values ----
# Replace the subscription ID and the four globally-unique names before applying.
subscription_id = "00000000-0000-0000-0000-000000000000"
environment     = "dev"
location        = "eastus"

# GLOBALLY UNIQUE — change these:
acr_name            = "acrworkflodev01"       # 5-50 alphanumeric, no hyphens
key_vault_name      = "kv-workflo-dev-01"     # 3-24 chars
cosmos_account_name = "cosmos-workflo-dev-01" # 3-44 lowercase
ai_language_name    = "lang-workflo-dev-01"

# AKS sizing (small/cheap for dev)
node_vm_size   = "Standard_B2s"
node_min_count = 1
node_max_count = 3

# Email for monitoring alerts
alert_email = "you@example.com"

# jwt_secret is intentionally NOT set here (it's sensitive). Supply it at plan/apply:
#   export TF_VAR_jwt_secret="$(openssl rand -hex 32)"
