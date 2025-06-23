provider "aws" {
  region = var.region
}


module "auth" {
  source       = "../../modules/auth"  # Ruta al módulo `auth` donde definimos Cognito
  project_name = var.project_name  # Nombre del proyecto para prefijar los recursos (de terraform.tfvars)
}

module "s3_storage" {
  source = "../../modules/storage"  # Esta es la ruta correcta hacia el módulo storage

  bucket_name = var.frontend_bucket_name
  tags        = var.common_tags
}

module "cdn_distribution" {
  source = "../../modules/cdn"  # Esta es la ruta correcta hacia el módulo cdn

  s3_origin_id          = module.s3_storage.s3_bucket_id
  s3_origin_domain_name = module.s3_storage.s3_bucket_regional_domain_name
  tags                  = var.common_tags

  depends_on = [module.s3_storage]
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

module "database" {
  source             = "../../modules/database"
  project            = "reservas"
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  engine_version     = "8.0"
  instance_class     = "db.t3.medium"
  allocated_storage  = 20
  private_subnet_ids = module.networking_vpc.private_subnets
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
