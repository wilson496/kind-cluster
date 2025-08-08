variable "namespace" {
  type        = string
  description = "Namespace for ingress-nginx"
  default     = "ingress-nginx"
}

variable "chart_version" {
  type        = string
  description = "ingress-nginx chart version"
  default     = "4.10.0"
}

variable "http_nodeport" {
  type        = number
  description = "Fixed NodePort for HTTP"
  default     = 30080
}

variable "https_nodeport" {
  type        = number
  description = "Fixed NodePort for HTTPS"
  default     = 30443
}

variable "admission_webhooks_enabled" {
  type        = bool
  description = "Enable admission webhooks (disable for simple local clusters)"
  default     = false
}
