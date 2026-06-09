# ---- prod environment values ----
subscription_id = "00000000-0000-0000-0000-000000000000"
environment     = "prod"
location        = "eastus"

# GLOBALLY UNIQUE — change these:
acr_name            = "acrworkfloprod01"
key_vault_name      = "kv-workflo-prod-01"
cosmos_account_name = "cosmos-workflo-prod-01"
ai_language_name    = "lang-workflo-prod-01"

node_vm_size   = "Standard_D2s_v5"
node_min_count = 2
node_max_count = 5

alert_email = "oncall@example.com"

# export TF_VAR_jwt_secret="$(openssl rand -hex 32)"
