module "network" {
  source             = "./modules/network"
  cidr_block         = var.cidr_block
  subnet_cidr_blocks = var.subnet_cidr_blocks
  prefix             = var.prefix
}

module "cluster" {
  source            = "./modules/cluster"
  prefix            = var.prefix
  subnet_id         = module.network.subnet_id[0]
  instance_count    = var.instance_count
  security_group_id = [module.network.security_group_id]
}
