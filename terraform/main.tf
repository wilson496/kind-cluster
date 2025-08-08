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
