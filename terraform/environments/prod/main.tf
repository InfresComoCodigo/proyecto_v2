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

provider "aws" {
  region = var.region
}