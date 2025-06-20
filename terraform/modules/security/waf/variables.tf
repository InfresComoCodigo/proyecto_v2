variable "env" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to WAF resources"
  type        = map(string)
}
