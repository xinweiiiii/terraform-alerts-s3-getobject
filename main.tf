module "getobject-alerts" {
  source = "./modules"
  account_id = var.account_id
  environment = var.environment
  project = var.project
  region = var.region
  webhook_url = var.webhook_url
}