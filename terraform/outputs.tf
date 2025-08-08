output "ingress_namespace" { value = module.nginx_ingress.namespace }
output "argocd_namespace" { value = module.argocd.namespace }