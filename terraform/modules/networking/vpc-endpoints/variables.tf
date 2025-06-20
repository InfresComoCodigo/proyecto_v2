variable "vpc_id" {
  description = "VPC ID where endpoints will be created"
  type        = string
}

variable "private_route_table_ids" {
  description = "Route table IDs for private subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subnet IDs for private subnets"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to endpoints"
  type        = map(string)
}
