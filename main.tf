module "network" {
  source             = "./modules/network"
  cidr_block         = var.cidr_block
  subnet_cidr_blocks = var.subnet_cidr_blocks
  prefix             = var.prefix
}

module "cluster" {
  source            = "./modules/cluster"
  prefix            = var.prefix
  subnet_id         = module.network.subnet_id
  instance_count    = var.instance_count
  security_group_id = [module.network.security_group_id]
  vpc_id            = module.network.vpc_id
  user_data         = var.user_data
  desired_capacity  = var.desired_capacity
  min_size          = var.min_size
  max_size          = var.max_size
  scale_in          = var.scale_in
  scale_out         = var.scale_out
}
