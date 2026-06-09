terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Never auto-purge soft-deleted vaults in prod.
      purge_soft_delete_on_destroy = false
    }
  }
  subscription_id = var.subscription_id
}
