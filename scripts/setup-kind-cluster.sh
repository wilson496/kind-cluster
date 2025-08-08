#!/bin/bash

set -euo pipefail

CLUSTER_NAME="dev-cluster"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5000"
CONFIG_PATH="cluster/cluster.yaml"

# Handle optional --force flag
FORCE=false
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

# Verify the config file exists
if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "❌ Cluster config file '${CONFIG_PATH}' not found."
  exit 1
fi

# Check if registry is running
echo "🔍 Checking if '${REGISTRY_NAME}' container is running..."
if ! docker ps --format '{{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
  echo "❌ Dependency '${REGISTRY_NAME}' is not running. Start it with:"
  echo "   docker-compose up -d ${REGISTRY_NAME}"
  exit 1
fi

# Check if cluster exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  if [ "$FORCE" = true ]; then
    echo "🗑  Deleting existing kind cluster '${CLUSTER_NAME}'..."
    kind delete cluster --name "${CLUSTER_NAME}"
  else
    echo "❌ Cluster '${CLUSTER_NAME}' already exists."
    echo "   Use '--force' to delete and recreate it, or run:"
    echo "   kind delete cluster --name ${CLUSTER_NAME}"
    exit 1
  fi
fi

# Create the cluster
echo "🚀 Creating kind cluster '${CLUSTER_NAME}' using '${CONFIG_PATH}'..."
kind create cluster --name "${CLUSTER_NAME}" --config="${CONFIG_PATH}"

# Connect registry to kind network
echo "🔗 Connecting registry container '${REGISTRY_NAME}' to kind network..."
docker network connect "kind" "${REGISTRY_NAME}" 2>/dev/null || echo "⚠️  '${REGISTRY_NAME}' already connected."

echo "✅ kind cluster '${CLUSTER_NAME}' is ready."
