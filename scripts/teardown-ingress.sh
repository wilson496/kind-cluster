#!/bin/bash
set -euo pipefail

echo "[INFO] Stopping port forwarding containers..."

docker stop kind-socat-8080 || true
docker stop kind-socat-8443 || true

echo "[INFO] Port forwarding stopped."
