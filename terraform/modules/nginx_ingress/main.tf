# resource "helm_release" "ingress_nginx" {
#   name       = "ingress-nginx"
#   namespace  = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   version    = "4.10.0"

#   create_namespace = true

#   # Keep the module simple: values here are targeted for MetalLB
#   values = [file("${path.module}/values.yaml")]

#   # Optionally pin a specific MetalLB IP inside your pool
#   # set {
#   #   name  = "controller.service.loadBalancerIP"
#   #   value = "172.20.255.200"
#   # }
# }

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = var.namespace
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  create_namespace = true
  timeout          = 600

  values = [yamlencode({
    controller = {
      kind           = "Deployment"
      publishService = { enabled = true }
      service = {
        type      = "NodePort"
        nodePorts = { http = var.http_nodeport, https = var.https_nodeport }
      }
      admissionWebhooks = { enabled = var.admission_webhooks_enabled }
    }
  })]
}
