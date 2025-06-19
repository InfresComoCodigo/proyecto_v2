
provider "aws" {
  region = var.region
}

module "networking_vpc" {
  source         = "../../modules/networking/vpc"
  env            = var.env
  cidr_block     = var.cidr_block
  azs            = var.azs
  public_subnets = var.public_subnets
  private_subnets= var.private_subnets
  tags           = var.tags
}

module "networking_endpoints" {
  source                  = "../../modules/networking/vpc-endpoints"
  vpc_id                  = module.networking_vpc.vpc_id
  private_route_table_ids = module.networking_vpc.private_route_table_ids
  private_subnet_ids      = module.networking_vpc.private_subnets
  region                  = var.region
  tags                    = var.tags
}

module "security_waf" {
  source = "../../modules/security/waf"
  env    = var.env
  tags   = var.tags
}

module "security_firewall" {
  source = "../../modules/security/firewall"
  env    = var.env
  tags   = var.tags
}
