# Workflo API — SLOs

Service level objectives for the api service, measured in Application Insights (data also in
Log Analytics). SLIs are defined as KQL in `monitoring/queries/`; alerts are codified in
`infra/modules/alerts/`.

## Objectives (28-day rolling window)

| SLO | Target | SLI (how it's measured) |
|-----|--------|-------------------------|
| **Availability** | 99.5% | share of requests with `resultCode < 500` (excludes 4xx client errors) |
| **Latency** | p95 < 300 ms | `percentile(duration, 95)` over `requests` |

> The 404→500 fix in Phase 0 matters here: misclassified 404s would have counted against the
> availability SLI and burned error budget for ordinary not-found responses.

## Error budget

- Availability 99.5% ⇒ **0.5%** of requests may fail per window.
- Two consecutive 5-minute windows breaching the error-rate alert ⇒ page; sustained burn ⇒
  freeze risky deploys until the budget recovers.

## SLIs

```kusto
// Availability (%)
requests
| summarize total = count(), good = countif(toint(resultCode) < 500)
| extend availabilityPct = 100.0 * good / total

// Latency p95 (ms)
requests
| summarize p95 = percentile(duration, 95) by bin(timestamp, 5m)
```

## Alert mapping (infra/modules/alerts)

| Alert | Condition | Severity |
|-------|-----------|----------|
| `alert-*-response-time` | avg `requests/duration` > 2000 ms over 5 min | Sev 2 |
| `alert-*-5xx-rate` | > 5 requests with `resultCode >= 500` in 5 min | Sev 1 |

Both notify the action group (email); extend the action group with PagerDuty/Teams as needed.
