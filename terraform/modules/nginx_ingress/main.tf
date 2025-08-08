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
