# Kind Kubernetes Project with Terraform, NGINX Ingress, and ArgoCD

## Overview

This repository provisions a local Kubernetes cluster using [Kind](https://kind.sigs.k8s.io/) and manages deployments via [Terraform](https://www.terraform.io/).

It includes:
- **NGINX Ingress Controller** (for HTTP routing)
- **ArgoCD** (for GitOps-based application deployments)

The setup is modular, with Terraform modules for each major component.

## Prerequisites
- Docker
- kubectl
- Kind
- Terraform
- make
- Optional: pre-commit

## Project Structure
```text
kind-project/
├── cluster/                  # Kind cluster configuration
├── modules/
│   ├── argocd/               # ArgoCD Terraform module
│   └── nginx-ingress/        # NGINX Ingress Terraform module
├── scripts/                  # Utility scripts
├── terraform/                # Terraform root configuration
├── Makefile                  # Automation commands
└── README.md
```

## Usage

### 1. Create the cluster and deploy infrastructure
```bash
make dev-up
```
This will:
- Create a Kind cluster
- Deploy NGINX Ingress Controller
- Deploy ArgoCD
- Output ArgoCD URL

### 2. Access ArgoCD

The default configuration exposes ArgoCD via `http://argocd.localhost`.

Login with:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Username: `admin`

### 3. Tear down the environment
```bash
make dev-down
```
This will destroy all Terraform-managed resources and delete the Kind cluster.

## Development Workflow
- **Terraform changes:** edit files in `modules/*` or `terraform/`
- **Scripts:** utility scripts are in `scripts/`
- **Make targets:** run `make help` for available commands


## License
MIT License
