# -------------------------------
# Kind Cluster & Terraform Tools
# -------------------------------

CLUSTER_NAME    = dev-cluster
ARGOCDFQDN      ?= argocd.localhost
ARGOCD_NS  ?= argocd
TF_DIR          = terraform

.PHONY: help
help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2}'

# -------------------------------
# Kind cluster lifecycle
# -------------------------------

setup: ## Create the kind cluster (fails if it already exists)
	./scripts/setup-kind-cluster.sh

setup-force: ## Delete and recreate the kind cluster
	./scripts/setup-kind-cluster.sh --force

teardown: ## Delete the kind cluster
	./scripts/teardown-kind-cluster.sh

restart: ## Force recreate the kind cluster
	$(MAKE) teardown
	$(MAKE) setup

# -------------------------------
# Cluster info / debugging
# -------------------------------

logs: ## Get cluster-wide pods & events
	kubectl get pods -A -o wide && \
	kubectl get events -A --sort-by=.metadata.creationTimestamp

status: ## Show cluster status and node info
	kubectl cluster-info
	kubectl get nodes -o wide

registry-status: ## Check if kind-registry is running
	docker ps --filter "name=kind-registry"

clean: ## Teardown cluster and prune Docker containers
	$(MAKE) teardown
	docker container prune -f

# -------------------------------
# Terraform operations
# -------------------------------

terraform-init:
	cd $(TF_DIR) && terraform init -upgrade

terraform-plan:
	cd $(TF_DIR) && terraform plan -var="argocd_host=$(ARGOCDFQDN)"

terraform-apply:
	cd $(TF_DIR) && terraform apply -auto-approve -var="argocd_host=$(ARGOCDFQDN)"

terraform-destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve -var="argocd_host=$(ARGOCDFQDN)"

# -------------------------------
# Argo CD helpers
# -------------------------------

argocd-password: ## Print Argo CD initial admin password
	@kubectl -n $(ARGOCD_NS) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

argocd-cli-check: ## Ensure argocd CLI is installed
	@command -v argocd >/dev/null 2>&1 || { \
	  echo >&2 "ERROR: 'argocd' CLI not found. Install from https://github.com/argoproj/argo-cd/releases and retry."; \
	  exit 1; \
	}

argocd-login: argocd-cli-check ## Log into Argo CD using admin + initial password
	@PASS="$$(kubectl -n $(ARGOCD_NS) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"; \
	echo "Logging into http://$(ARGOCDFQDN) ..."; \
	argocd login $(ARGOCDFQDN) --username admin --password "$$PASS" --insecure

argocd-open: ## Open Argo CD UI in browser (Linux xdg-open; macOS open; WSL tries Windows)
	@(command -v xdg-open >/dev/null 2>&1 && xdg-open "http://$(ARGOCDFQDN)") || \
	 (command -v open >/dev/null 2>&1 && open "http://$(ARGOCDFQDN)") || \
	 (command -v powershell.exe >/dev/null 2>&1 && powershell.exe start "http://$(ARGOCDFQDN)") || \
	 echo "Open http://$(ARGOCDFQDN) in your browser."

# -------------------------------
# Argo CD bootstrap (project + app)
# -------------------------------

ARGOCD_NS        ?= argocd
PROJECT_NAME     ?= demo
APP_NAME         ?= demo-guestbook
REPO_URL         ?= https://github.com/argoproj/argocd-example-apps.git
APP_PATH         ?= guestbook
DEST_SERVER      ?= https://kubernetes.default.svc
DEST_NAMESPACE   ?= demo

argocd-bootstrap: argocd-cli-check wait-argocd ## Create AppProject + Application and sync a sample app
	@echo ">>> Ensuring destination namespace '$(DEST_NAMESPACE)' exists..."
	@kubectl create ns $(DEST_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo ">>> Applying AppProject '$(PROJECT_NAME)'..."
	@cat <<'YAML' | envsubst | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: $(PROJECT_NAME)
  namespace: $(ARGOCD_NS)
spec:
  description: Demo project
  sourceRepos:
  - $(REPO_URL)
  destinations:
  - namespace: $(DEST_NAMESPACE)
    server: $(DEST_SERVER)
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
YAML
	@echo ">>> Applying Application '$(APP_NAME)'..."
	@cat <<'YAML' | envsubst | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $(APP_NAME)
  namespace: $(ARGOCD_NS)
spec:
  project: $(PROJECT_NAME)
  source:
    repoURL: $(REPO_URL)
    targetRevision: HEAD
    path: $(APP_PATH)
  destination:
    server: $(DEST_SERVER)
    namespace: $(DEST_NAMESPACE)
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
	@echo ">>> Waiting for Argo CD to pick up the app..."
	@argocd app wait $(APP_NAME) --health --sync --timeout 300 || { \
	  echo "argocd CLI wait failed (may still be syncing). Checking with kubectl..."; \
	  kubectl -n $(ARGOCD_NS) get application $(APP_NAME) -o jsonpath='{.status.health.status}{" / "}{.status.sync.status}{"\n"}' || true; \
	}
	@echo ">>> Syncing (idempotent)..."
	@argocd app sync $(APP_NAME) --timeout 300 || true
	@echo ">>> App status:"
	@argocd app get $(APP_NAME) || kubectl -n $(ARGOCD_NS) get application $(APP_NAME) -o yaml | sed -n '1,120p'
	@echo "✔ Bootstrap complete. Try:  kubectl -n $(DEST_NAMESPACE) get svc,deploy,pod"

argocd-bootstrap-delete: ## Remove the demo app + project + namespace
	-@kubectl -n $(ARGOCD_NS) delete application $(APP_NAME) --ignore-not-found
	-@kubectl -n $(ARGOCD_NS) delete appproject $(PROJECT_NAME) --ignore-not-found
	-@kubectl delete ns $(DEST_NAMESPACE) --ignore-not-found
	@echo "✔ Bootstrap resources removed."


# -------------------------------
# Readiness & verification
# -------------------------------

wait-ingress: ## Wait for ingress-nginx controller to be ready
	kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s

wait-argocd: ## Wait for Argo CD server to be ready
	kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

wait-ready: wait-ingress wait-argocd ## Wait for both ingress and Argo CD

verify: ## Show key services and ingress
	@echo "---- ingress-nginx ----"; \
	kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide || true; \
	echo "---- argocd pods ----"; \
	kubectl -n argocd get pods || true; \
	echo "---- argocd ingress ----"; \
	kubectl -n argocd get ingress || true; \
	echo "---- quick curl (host header) ----"; \
	curl -sI http://127.0.0.1 -H "Host: $(ARGOCDFQDN)" | head -n 1 || true

print-argocd-info: ## Show Argo CD URL and initial admin password command
	@echo ""
	@echo "Argo CD URL: http://$(ARGOCDFQDN)"
	@echo "Initial admin password (copy/paste):"
	@echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
	@echo ""

# -------------------------------
# /etc/hosts helpers (idempotent)
# -------------------------------

hosts-add: ## Add $(ARGOCDFQDN) to /etc/hosts (idempotent)
	@sudo sh -c "grep -q '^[0-9.]\+ $(ARGOCDFQDN)$$' /etc/hosts && exit 0 || echo '127.0.0.1 $(ARGOCDFQDN)' >> /etc/hosts"

hosts-remove: ## Remove $(ARGOCDFQDN) from /etc/hosts
	@sudo sh -c "cp /etc/hosts /etc/hosts.bak && grep -v ' $(ARGOCDFQDN)$$' /etc/hosts.bak > /etc/hosts && rm -f /etc/hosts.bak || true"

# -------------------------------
# Dev environment shortcuts
# -------------------------------

# Start local dev environment
# 1) Create cluster
# 2) Terraform init/apply (ingress-nginx + ArgoCD)
# 3) Wait for ingress + ArgoCD rollouts
# 4) Add hosts entry and print URL/password
# 5) Bootstrap demo project/app (waits on ArgoCD + argocd CLI)
# 6) Verify reachability
dev-up: setup terraform-init terraform-apply wait-ready hosts-add print-argocd-info argocd-bootstrap verify

# Tear down local dev environment (delete demo app/project first so ArgoCD CRDs aren’t busy)
dev-down: argocd-bootstrap-delete terraform-destroy teardown hosts-remove