# output "helm_release" {
#   description = "The Helm release resource for ingress-nginx"
#   value       = helm_release.ingress_nginx
# }

output "namespace" { value = var.namespace }
output "release_name" { value = helm_release.ingress_nginx.name }
