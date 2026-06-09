# monitoring — Observability (Azure-native)

Everything observability, as code.

```
monitoring/
├── slo.md         # SLO/SLI definitions, error budget, alert mapping
└── queries/       # reusable KQL for App Insights / Log Analytics
```

## Where each piece lives

| Concern | Implementation |
|---|---|
| App traces + request/dependency metrics | `@azure/monitor-opentelemetry` in each service's `src/telemetry.ts` → Application Insights |
| Cluster/node/pod metrics & logs | Container Insights (AKS `oms_agent` addon → Log Analytics), in `infra/modules/aks` |
| App Insights + Log Analytics workspace | `infra/modules/monitoring` |
| Alerts + action group | `infra/modules/alerts` (wired in `infra/stack`) |
| SLOs / SLIs | `slo.md` + `queries/` |
| Load/scale validation | [`load-test/`](../load-test/README.md) (k6) |

## SLOs (see `slo.md` for detail)

| SLO | Target | Measured by |
|---|---|---|
| Availability | 99.5% | share of requests with `resultCode < 500` |
| Latency | p95 < 300 ms | `percentile(duration, 95)` over `requests` |

## Using the queries

The files in `queries/` are ready-to-run KQL. In the Azure portal open your **Application
Insights → Logs** (or the Log Analytics workspace), paste a query, and run it. Pin results to an
Azure Dashboard or add them to a Workbook to build a panel set.

| Query | Shows |
|---|---|
| `request-rate.kql` | requests per minute |
| `latency.kql` | p50/p95/p99 latency |
| `error-rate.kql` | 5xx error rate (%) |
| `top-failing-routes.kql` | routes with the most 5xx |

## Alerts

Defined as code in `infra/modules/alerts` and deployed with the stack:

| Alert | Condition | Severity |
|---|---|---|
| response-time | avg `requests/duration` > 2000 ms over 5 min | Sev 2 |
| 5xx-rate | > 5 responses with `resultCode >= 500` in 5 min | Sev 1 |

Both notify the action group (email set via `alert_email`). Extend the action group with
Teams/PagerDuty receivers as needed.

## Telemetry wiring

`APPLICATIONINSIGHTS_CONNECTION_STRING` is stored in Key Vault by Terraform and delivered to pods
via the CSI driver (same path as other secrets). Each service initializes the exporter only when
that variable is present, so local runs stay quiet.
