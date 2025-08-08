# terraform {
#   required_providers {
#     helm = {
#       source  = "hashicorp/helm"
#       version = "~> 2.12"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~> 2.30"
#     }
#   }
# }

# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config"
#   }
# }

# module "nginx_ingress" {
#   source = "./modules/nginx_ingress"
#   # any variables needed here
# }



# # 1) Wait until the webhook is actually reachable
# resource "null_resource" "wait_ingress_webhook" {
#   depends_on = [module.nginx_ingress]

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command = <<-EOT
#       set -euo pipefail
#       ns=ingress-nginx

#       # wait for admission endpoints
#       for i in {1..30}; do
#         ep=$(kubectl -n "$ns" get endpoints ingress-nginx-controller-admission -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null || true)
#         [ -n "$ep" ] && echo "Admission endpoints ready: $ep" && break
#         echo "Waiting for admission endpoints... ($i/30)"; sleep 5
#       done

#       # wait for non-empty caBundle
#       for i in {1..30}; do
#         n=$(kubectl get validatingwebhookconfiguration ingress-nginx-admission -o jsonpath='{.webhooks[*].clientConfig.caBundle}' 2>/dev/null | wc -c)
#         [ "$n" -gt 0 ] && echo "caBundle present (bytes: $n)" && break
#         echo "Waiting for admission caBundle... ($i/30)"; sleep 5
#       done
#     EOT
#   }
# }

# # 2) Temporarily relax the webhook for bootstrap
# resource "null_resource" "patch_ingress_webhook_ignore" {
#   depends_on = [null_resource.wait_ingress_webhook]

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command = <<-EOT
#       set -euo pipefail

#       # wait until the VWC exists
#       for i in {1..30}; do
#         if kubectl get validatingwebhookconfiguration ingress-nginx-admission >/dev/null 2>&1; then
#           break
#         fi
#         echo "Waiting for validatingwebhookconfiguration/ingress-nginx-admission... ($i/30)"
#         sleep 2
#       done

#       # set failurePolicy=Ignore and timeoutSeconds=30
#       kubectl patch validatingwebhookconfiguration ingress-nginx-admission \
#         --type='json' \
#         -p='[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Ignore"}]'

#       kubectl patch validatingwebhookconfiguration ingress-nginx-admission \
#         --type='json' \
#         -p='[{"op":"replace","path":"/webhooks/0/timeoutSeconds","value":30}]'

#       echo "Patched ingress-nginx-admission to failurePolicy=Ignore, timeoutSeconds=30"
#     EOT
#   }
# }

# # 3) Your ArgoCD module should depend on the patch
# module "argocd" {
#   source     = "./modules/argocd"
#   depends_on = [null_resource.patch_ingress_webhook_ignore]
#   # keep your existing inputs...
#   argocd_hostname = var.argocd_hostname
# }

# # 4) Restore the webhook back to Fail after ArgoCD is up
# resource "null_resource" "restore_ingress_webhook_fail" {
#   depends_on = [module.argocd]

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command = <<-EOT
#       set -euo pipefail

#       kubectl patch validatingwebhookconfiguration ingress-nginx-admission \
#         --type='json' \
#         -p='[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Fail"}]'

#       kubectl patch validatingwebhookconfiguration ingress-nginx-admission \
#         --type='json' \
#         -p='[{"op":"replace","path":"/webhooks/0/timeoutSeconds","value":10}]'

#       echo "Restored ingress-nginx-admission to failurePolicy=Fail, timeoutSeconds=10"
#     EOT
#   }
# }

locals { argocd_host = var.argocd_host }

module "nginx_ingress" {
  source                     = "./modules/nginx_ingress"
  namespace                  = "ingress-nginx"
  chart_version              = var.ingress_nginx_chart_version
  http_nodeport              = var.ingress_http_nodeport
  https_nodeport             = var.ingress_https_nodeport
  admission_webhooks_enabled = var.ingress_admission_enabled
}

module "argocd" {
  source             = "./modules/argocd"
  namespace          = "argocd"
  chart_version      = var.argocd_chart_version
  hostname           = local.argocd_host
  ingress_class_name = "nginx"
  server_insecure    = true
  depends_on         = [module.nginx_ingress]
}

output "argocd_url" { value = "http://${local.argocd_host}" }
