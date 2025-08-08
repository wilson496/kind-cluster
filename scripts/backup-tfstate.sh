#!/bin/bash
set -euo pipefail

MC_ALIAS="localminio"
BUCKET="terraform-backups"
KEY="kind-dev-$(date +%Y%m%d%H%M%S).tfstate"

# Ensure alias exists
mc alias set ${MC_ALIAS} http://localhost:9000 admin changeme123 2>/dev/null || true

# Create backup bucket if missing
mc mb ${MC_ALIAS}/${BUCKET} 2>/dev/null || true

# Export current state
cp terraform.tfstate tmp.tfstate
mc cp tmp.tfstate ${MC_ALIAS}/${BUCKET}/${KEY}
rm tmp.tfstate

echo "✅ Backup saved to ${BUCKET}/${KEY}"
