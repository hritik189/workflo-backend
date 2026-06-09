# Alerting as code: an action group (email) plus two alerts wired to Application Insights.
resource "azurerm_monitor_action_group" "this" {
  name                = "ag-${var.name}"
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  email_receiver {
    name          = "oncall"
    email_address = var.alert_email
  }
}

# Average server response time over threshold (metric alert).
resource "azurerm_monitor_metric_alert" "response_time" {
  name                = "alert-${var.name}-response-time"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_insights_id]
  description         = "Average server response time exceeded threshold."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/duration"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.response_time_threshold_ms
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# 5xx error rate over a 5-minute window (scheduled log-query alert).
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "error_rate" {
  name                 = "alert-${var.name}-5xx-rate"
  resource_group_name  = var.resource_group_name
  location             = var.location
  severity             = 1
  scopes               = [var.app_insights_id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  criteria {
    query                   = <<-KQL
      requests
      | where toint(resultCode) >= 500
    KQL
    time_aggregation_method = "Count"
    threshold               = var.error_count_threshold
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.this.id]
  }
}
