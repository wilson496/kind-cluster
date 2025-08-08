#!/bin/bash
set -euo pipefail

echo "[INFO] Forwarding ports 8080 -> 80 and 8443 -> 443 on kind-control-plane..."

# Check if ports are available
if lsof -i :8080 > /dev/null 2>&1 || lsof -i :8443 > /dev/null 2>&1; then
  echo "[ERROR] Ports 8080 or 8443 are already in use. Please free them or use different ports."
  exit 1
fi

docker run -d --rm \
  --name kind-socat-8080 \
  -p 8080:80 \
  --network kind \
  alpine/socat tcp-listen:80,fork,reuseaddr tcp-connect:kind-control-plane:80

docker run -d --rm \
  --name kind-socat-8443 \
  -p 8443:443 \
  --network kind \
  alpine/socat tcp-listen:443,fork,reuseaddr tcp-connect:kind-control-plane:443

echo "[INFO] Port forwarding started. Access via http://localhost:8080 or https://localhost:8443"
