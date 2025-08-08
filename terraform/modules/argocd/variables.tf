# variable "argocd_hostname" {
#   type        = string
#   description = "Hostname to expose ArgoCD Ingress"
# }


variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  type    = string
  default = "8.2.5"
}

variable "hostname" {
  type    = string
  default = "argocd.localhost"
}

variable "ingress_class_name" {
  type    = string
  default = "nginx"
}

variable "server_insecure" {
  type    = bool
  default = true
}
