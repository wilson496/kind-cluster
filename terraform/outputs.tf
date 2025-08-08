output "ingress_namespace" { value = module.nginx_ingress.namespace }
output "argocd_namespace" { value = module.argocd.namespace }
# output "argocd_url"        { value = "http://${var.argocd_host}" }
