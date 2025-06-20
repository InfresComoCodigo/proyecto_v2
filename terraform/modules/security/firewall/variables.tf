variable "env" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security groups"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}