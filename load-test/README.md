# load-test — k6

Drives traffic at the api to demonstrate the **HorizontalPodAutoscaler** scaling out and back in,
and to populate the Application Insights dashboards/SLIs.

## Install k6

See [k6.io/docs/get-started/installation](https://k6.io/docs/get-started/installation/) (e.g.
`brew install k6`, or the Docker image `grafana/k6`).

## Run

```sh
# Against the deployed ingress:
BASE_URL=https://workflo-dev.example.com k6 run k6-load-test.js

# Or against a local port-forward:
kubectl -n workflo port-forward svc/workflo-api 8080:80 &
k6 run k6-load-test.js          # defaults to http://localhost:8080
```

## Watch the autoscaler react

```sh
kubectl -n workflo get hpa workflo-api -w
kubectl -n workflo get pods -w
```

As CPU crosses the 70% target the HPA adds replicas (up to `autoscaling.maxReplicas`); after the
ramp-down it scales back toward `minReplicas`.

## Profile & thresholds

The script ramps virtual users 20 → 100 → hold → 0 over ~7 minutes, and asserts:

| Threshold | Meaning |
|---|---|
| `http_req_failed: rate<0.01` | under 1% errors |
| `http_req_duration: p(95)<500` | p95 latency under 500 ms |

Edit the `stages` and `thresholds` in `k6-load-test.js` to change the load profile. Pair this with
the panels in [`monitoring/`](../monitoring/README.md) to watch rate, latency, and replica count
move together.
