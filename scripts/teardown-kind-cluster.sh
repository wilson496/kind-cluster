#!/bin/bash

CLUSTER_NAME="dev-cluster"

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "🗑  Deleting kind cluster '${CLUSTER_NAME}'..."
  kind delete cluster --name "${CLUSTER_NAME}"
else
  echo "✅ No existing kind cluster '${CLUSTER_NAME}' found."
fi
