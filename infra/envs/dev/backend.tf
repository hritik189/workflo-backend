# Remote state in Azure Storage, with state locking via blob lease.
# Non-secret values are supplied at init time so they aren't committed:
#   terraform init -backend-config=backend.hcl
terraform {
  backend "azurerm" {}
}
