variable "env" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to Firewall Manager resources"
  type        = map(string)
}
