// k6 load test — ramps virtual users to drive CPU and trigger the HorizontalPodAutoscaler.
//
//   BASE_URL=https://workflo-dev.example.com k6 run load-test/k6-load-test.js
//
// Watch the autoscaler react in another terminal:
//   kubectl -n workflo get hpa workflo-api -w
import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://localhost:8080";

export const options = {
  stages: [
    { duration: "1m", target: 20 },  // warm up
    { duration: "3m", target: 100 }, // ramp — should push CPU past the 70% HPA target
    { duration: "2m", target: 100 }, // hold at peak
    { duration: "1m", target: 0 },   // ramp down — watch replicas scale back in
  ],
  thresholds: {
    http_req_failed: ["rate<0.01"],   // < 1% errors
    http_req_duration: ["p(95)<500"], // p95 under 500ms
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/health`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(0.2);
}
