# Load test (k6)

Drives traffic at the api to demonstrate the HPA scaling out and back in, and to populate the
Application Insights dashboards/SLIs.

## Run

```sh
# Against the deployed ingress:
BASE_URL=https://workflo-dev.example.com k6 run k6-load-test.js

# Or against a local port-forward:
kubectl -n workflo port-forward svc/workflo-api 8080:80 &
k6 run k6-load-test.js
```

## Watch the autoscaler

```sh
kubectl -n workflo get hpa workflo-api -w
kubectl -n workflo get pods -w
```

As CPU crosses the 70% target the HPA adds replicas (up to `autoscaling.maxReplicas`); after the
ramp-down it scales back toward `minReplicas`. The corresponding request-rate and latency panels
are in `monitoring/queries/`.
