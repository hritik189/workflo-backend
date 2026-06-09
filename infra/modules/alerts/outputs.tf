output "action_group_id" {
  description = "Resource ID of the action group (reusable for budget/cost alerts)."
  value       = azurerm_monitor_action_group.this.id
}
