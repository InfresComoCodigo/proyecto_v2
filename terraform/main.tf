provider "aws" {
  region = var.aws_region
}

module "auth" {
  source       = "./modules/auth"
  project_name = var.project_name
}