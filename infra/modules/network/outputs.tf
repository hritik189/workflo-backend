output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet (passed to the AKS node pool)."
  value       = azurerm_subnet.aks.id
}
