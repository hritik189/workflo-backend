// Azure Monitor (Application Insights) via OpenTelemetry. Must be imported first.
// No-op unless APPLICATIONINSIGHTS_CONNECTION_STRING is set.
import { useAzureMonitor } from "@azure/monitor-opentelemetry";

if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  useAzureMonitor();
  console.log("Azure Monitor OpenTelemetry initialized");
}
