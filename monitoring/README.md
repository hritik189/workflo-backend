# Monitoring (Azure-native)

Observability for Workflo, all as code.

```
monitoring/
├── slo.md         # SLO/SLI definitions, error budget, alert mapping
└── queries/       # reusable KQL for App Insights / Log Analytics dashboards
```

## Pieces and where they live

| Concern | Implementation |
|--------|----------------|
| App telemetry (traces, request/dependency metrics) | `@azure/monitor-opentelemetry` in `apps/api/src/telemetry.ts`, exported to App Insights |
| Cluster/node/pod metrics & logs | Container Insights (AKS `oms_agent` addon → Log Analytics, in `infra/modules/aks`) |
| App Insights + Log Analytics workspace | `infra/modules/monitoring` |
| Alerts + action group | `infra/modules/alerts` (wired in `infra/envs/dev`) |
| SLOs / SLIs | `slo.md` + `queries/` |
| Load/scale validation | `load-test/` (k6) |

## Dashboards

Paste the `queries/*.kql` into an Application Insights **Logs** blade, or pin them to an Azure
Workbook / Dashboard. They cover request rate, latency percentiles, 5xx error rate, and top
failing routes — the four panels that back the SLOs in `slo.md`.

## Telemetry wiring

`APPLICATIONINSIGHTS_CONNECTION_STRING` is stored in Key Vault by Terraform and delivered to the
pod via the CSI driver (same path as `DB_URL`). The app initializes the exporter only when that
variable is present, so local runs stay quiet.
