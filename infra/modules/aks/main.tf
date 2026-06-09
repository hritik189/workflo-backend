# AKS cluster with:
#  - OIDC issuer + Workload Identity (secretless pod -> Azure auth, used by Key Vault CSI)
#  - Container Insights via the oms_agent addon -> Log Analytics
#  - autoscaling system node pool in the dedicated subnet
#  - Azure CNI + Calico network policy
resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                = "system"
    vm_size             = var.node_vm_size
    vnet_subnet_id      = var.subnet_id
    enable_auto_scaling = true
    min_count           = var.node_min_count
    max_count           = var.node_max_count
    orchestrator_version = var.kubernetes_version
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Secrets Store CSI driver addon — backs the Key Vault SecretProviderClass.
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }

  tags = var.tags
}
