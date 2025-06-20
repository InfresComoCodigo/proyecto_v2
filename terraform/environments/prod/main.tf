provider "aws" {
  region = var.region
}

module "networking_vpc" {
  source          = "../../modules/networking/vpc"
  env             = var.env
  cidr_block      = var.cidr_block
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  tags            = var.tags
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
  vpc_id = module.networking_vpc.vpc_id  # Añadido
  tags   = var.tags
}

module "compute" {
  source          = "../../modules/compute"
  env             = var.env
  private_subnets = module.networking_vpc.private_subnets
  ec2_sg_id       = module.security_firewall.ec2_sg_id
  ami_id          = "ami-0f3f13f145e66a0a3"  # AMI especificado
  instance_type   = "t3.micro"
  tags            = var.tags
}

module "monitoring" {
  source   = "../../modules/monitoring"
  env      = var.env
  asg_name = module.compute.asg_name
}