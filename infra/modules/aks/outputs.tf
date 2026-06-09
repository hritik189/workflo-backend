output "cluster_name" {
  description = "AKS cluster name (used by `az aks get-credentials`)."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {
  description = "AKS cluster resource ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity (granted AcrPull on the registry)."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL — used for Workload Identity federated credentials."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "Auto-generated MC_ resource group holding the node infrastructure."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}
