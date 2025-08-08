#!/bin/bash
set -euo pipefail

LOCK_KEY="terraform/kind/dev-lock"
CONSUL_ADDR="http://localhost:8500"
WHO=$(whoami)@$(hostname)
TTL_SECONDS=600

# Acquire lock
existing_lock=$(curl -s "${CONSUL_ADDR}/v1/kv/${LOCK_KEY}?raw" || true)

if [[ -n "$existing_lock" ]]; then
  echo "❌ Terraform is locked by: $existing_lock"
  exit 1
fi

echo "🔐 Locking Terraform as ${WHO}"
curl -X PUT -d "${WHO}" "${CONSUL_ADDR}/v1/kv/${LOCK_KEY}"

# Run terraform (args passed to script)
terraform "$@"

# Release lock
echo "🔓 Releasing lock"
curl -X DELETE "${CONSUL_ADDR}/v1/kv/${LOCK_KEY}"
