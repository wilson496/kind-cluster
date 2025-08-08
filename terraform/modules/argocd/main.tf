resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.namespace
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  create_namespace = true
  timeout          = 600

  values = [yamlencode({
    configs = { params = { "server.insecure" = tostring(var.server_insecure) } }
    server = { ingress = {
      enabled          = true
      ingressClassName = var.ingress_class_name
      hostname         = var.hostname
    } }
  })]
}

resource "null_resource" "wait_argocd" {
  depends_on = [helm_release.argocd]
  provisioner "local-exec" {
    command     = "kubectl -n ${var.namespace} rollout status deploy/argocd-server --timeout=300s"
    interpreter = ["/bin/bash", "-c"]
  }
}
