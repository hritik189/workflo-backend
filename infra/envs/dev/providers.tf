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
      # Lets `terraform destroy` fully remove soft-deleted vaults in dev.
      purge_soft_delete_on_destroy = true
    }
  }
  subscription_id = var.subscription_id
}
