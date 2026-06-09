// Azure Monitor (Application Insights) via OpenTelemetry.
//
// IMPORTANT: this module must be imported FIRST in server.ts — before express/http are
// loaded — so the OpenTelemetry auto-instrumentation can patch them. It is a no-op unless
// APPLICATIONINSIGHTS_CONNECTION_STRING is set (so local dev is unaffected); in AKS the
// connection string is delivered from Key Vault via the CSI driver.
import { useAzureMonitor } from "@azure/monitor-opentelemetry";

if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  // Reads the connection string from the environment; enables HTTP/Express tracing,
  // request/dependency metrics, and log collection, all exported to Application Insights.
  useAzureMonitor();
  console.log("Azure Monitor OpenTelemetry initialized");
}
