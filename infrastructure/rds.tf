module "postgres" {
  source = "terraform-aws-modules/rds-aurora/aws"
  version = "5.2.0"
  create_security_group = false
  create_random_password = false
  create_monitoring_role = false
  create_cluster = false

  name = "expensely"
  engine = "aurora-postgresql"
  engine_mode = "serverless"
  storage_encrypted = true

  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.database_subnets
  db_subnet_group_name = module.vpc.database_subnet_group_name
  allowed_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  replica_scale_enabled = false
  replica_count = 0

  monitoring_interval = 60

  apply_immediately = true
  skip_final_snapshot = true

  scaling_configuration = {
    auto_pause = true
    min_capacity = 2
    max_capacity = 4
    seconds_until_auto_pause = 300
    timeout_action = "ForceApplyCapacityChange"
  }
}
