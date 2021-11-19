module "postgres" {
  source = "terraform-aws-modules/rds-aurora/aws"
  version = "5.2.0"
  create_security_group= false
  create_random_password = false
  create_monitoring_role = false
  create_db_subnet_group = false
  create_cluster = false

  name = "expensely"
  engine = "aurora-postgresql"
  engine_mode = "serverless"
  storage_encrypted = true

  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.database_subnets
  db_subnet_group_name = module.vpc.database_subnet_group_name
  create_security_group = false
  vpc_security_group_ids = [aws_security_group.postgres_server.id]
  allowed_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  replica_scale_enabled = false
  replica_count = 0

  monitoring_interval = 60

  apply_immediately = true
  skip_final_snapshot = true

  db_parameter_group_name = aws_db_parameter_group.example_postgresql.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.example_postgresql.id

  scaling_configuration = {
    auto_pause = true
    min_capacity = 2
    max_capacity = 4
    seconds_until_auto_pause = 300
    timeout_action = "ForceApplyCapacityChange"
  }
}
resource "aws_db_parameter_group" "example_postgresql" {
  name = "expensely-aurora-db-postgres-parameter-group"
  family = "aurora-postgresql10"
  description = "expensely-aurora-db-postgres-parameter-group"
}
resource "aws_rds_cluster_parameter_group" "example_postgresql" {
  name = "expensely-aurora-postgres-cluster-parameter-group"
  family = "aurora-postgresql10"
  description = "expensely-aurora-postgres-cluster-parameter-group"
}

// SECURITY GROUP
resource "aws_security_group" "postgres_server" {
  name = "expensely-rds-server"
  description = "Allow traffic into RDS:expensely"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "expensely-rds-server"
  }
}
resource "aws_security_group_rule" "postgres_server" {
  security_group_id = aws_security_group.postgres_server.id

  type = "ingress"
  from_port = module.postgres.rds_cluster_port
  to_port = module.postgres.rds_cluster_port
  protocol = "tcp"
  source_security_group_id = aws_security_group.postgres_client.id
  description = "Allow traffic from ${aws_security_group.postgres_client.name} on port ${module.postgres.rds_cluster_port}"
}

resource "aws_security_group" "postgres_client" {
  name = "expensely-rds-client"
  description = "Allow traffic to RDS:expensely"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "expensely-rds-client"
  }
}
resource "aws_security_group_rule" "postgres_client" {
  security_group_id = aws_security_group.postgres_client.id

  type = "egress"
  from_port = module.postgres.rds_cluster_port
  to_port = module.postgres.rds_cluster_port
  protocol = "tcp"
  source_security_group_id = aws_security_group.postgres_server.id
  description = "Allow traffic to ${aws_security_group.postgres_server.name} on port ${module.postgres.rds_cluster_port}"
}
