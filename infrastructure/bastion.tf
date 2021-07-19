resource "aws_key_pair" "bastion" {
  key_name = "bastion"
  public_key = var.bastion_public_key
}

module "bastion" {
  source = "Guimove/bastion/aws"

  bastion_launch_template_name = var.bastion_name
  bastion_instance_count = 1
  auto_scaling_group_subnets = module.vpc.public_subnets
  bastion_iam_policy_name = var.bastion_name
  bastion_host_key_pair = aws_key_pair.bastion.key_name
  bucket_name = var.bastion_bucket_name
  create_dns_record = false
  elb_subnets = module.vpc.public_subnets
  instance_type = var.bastion_instance_size
  is_lb_private = false
  region = var.region
  vpc_id = module.vpc.vpc_id
  tags = local.default_tags
}

resource "aws_s3_bucket_public_access_block" "bastion" {
  bucket = module.bastion.bucket_name
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}
