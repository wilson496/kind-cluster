#!/bin/bash
set -euo pipefail

MC_ALIAS="localminio"
BUCKET="terraform-backups"
KEY="$1"  # e.g., kind-dev-20250806163430.tfstate

# Ensure alias exists
mc alias set ${MC_ALIAS} http://localhost:9000 admin changeme123 2>/dev/null || true

# Restore state
mc cp ${MC_ALIAS}/${BUCKET}/${KEY} terraform.tfstate
echo "✅ Restored terraform.tfstate from ${KEY}"
