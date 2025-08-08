# variables.tf
variable "namespace" {
  default = "platform"
}

variable "argocd_hostname" {
  type        = string
  description = "Hostname for ArgoCD"
  default     = "argocd.localhost"
}

variable "argocd_host" {
  type    = string
  default = "argocd.localhost"
}

variable "ingress_nginx_chart_version" {
  type    = string
  default = "4.10.0"
}

variable "argocd_chart_version" {
  type    = string
  default = "8.2.5"
}

variable "ingress_http_nodeport" {
  type    = number
  default = 30080
}

variable "ingress_https_nodeport" {
  type    = number
  default = 30443
}

variable "ingress_admission_enabled" {
  type    = bool
  default = false
}
