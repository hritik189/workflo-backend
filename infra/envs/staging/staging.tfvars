# ---- staging environment values ----
subscription_id = "00000000-0000-0000-0000-000000000000"
environment     = "staging"
location        = "eastus"

# GLOBALLY UNIQUE — change these:
acr_name            = "acrworkflostg01"
key_vault_name      = "kv-workflo-stg-01"
cosmos_account_name = "cosmos-workflo-stg-01"
ai_language_name    = "lang-workflo-stg-01"

node_vm_size   = "Standard_B2s"
node_min_count = 1
node_max_count = 4

alert_email = "you@example.com"

# export TF_VAR_jwt_secret="$(openssl rand -hex 32)"
