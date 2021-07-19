module "postgres" {
  source = "terraform-aws-modules/rds/aws"
  create_db_instance = true
  create_db_option_group = true
  create_db_parameter_group = false
  create_db_subnet_group = false
  create_monitoring_role = true
  create_random_password = true

  identifier = var.postgres_name

  engine = "postgres"
  engine_version = "13.3"
  family = "postgres13"

  major_engine_version = "13"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  max_allocated_storage = 100
  storage_type = "gp2"
  storage_encrypted = true

  name = "Expensely"
  username = "Expensely"
  port = 5432

  multi_az = true
  subnet_ids = module.vpc.database_subnets
  vpc_security_group_ids = [
    aws_security_group.postgres_server.id]

  maintenance_window = "Sat:15:01-Sat:16:00"
  backup_window = "14:00-15:00"
  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"]

  backup_retention_period = 0
  skip_final_snapshot = true
  deletion_protection = false #TODO later

  performance_insights_enabled = true
  performance_insights_retention_period = 7
  monitoring_interval = 60

  parameters = [
    {
      name = "autovacuum"
      value = 1
    },
    {
      name = "client_encoding"
      value = "utf8"
    }
  ]
  db_parameter_group_tags = local.default_tags

  tags = local.default_tags

  timeouts = {
    create = "80m"
    update = "80m"
    delete = "80m"
  }
}
resource "aws_secretsmanager_secret" "postgres_admin_password" {
  name = "Expensely/DatabaseInstance/Postgres/User/Expensely"
  description = "Admin password for RDS instance:${module.postgres.db_instance_id}"

  tags = local.default_tags
}
resource "aws_secretsmanager_secret_version" "postgres_admin_password" {
  secret_id = aws_secretsmanager_secret.postgres_admin_password.id
  secret_string = jsonencode({
    Username = module.postgres.db_instance_username,
    Password = module.postgres.db_instance_password,
    Port = module.postgres.db_instance_port,
    Endpoint = module.postgres.db_instance_endpoint
  })
}

// SECURITY GROUP
resource "aws_security_group" "postgres_server" {
  name = "${var.postgres_name}-rds-server"
  description = "Allow traffic into RDS:expensely"
  vpc_id = module.vpc.vpc_id

  tags = merge(
    local.default_tags,
    {
      Name = "${var.postgres_name}-rds-server"
    }
  )
}
resource "aws_security_group_rule" "postgres_server" {
  security_group_id = aws_security_group.postgres_server.id

  type = "ingress"
  from_port = module.postgres.db_instance_port
  to_port = module.postgres.db_instance_port
  protocol = "tcp"
  source_security_group_id = aws_security_group.postgres_client.id
  description = "Allow traffic from ${aws_security_group.postgres_client.name} on port ${module.postgres.db_instance_port}"
}

resource "aws_security_group" "postgres_client" {
  name = "${var.postgres_name}-rds-client"
  description = "Allow traffic to RDS:${var.postgres_name}"
  vpc_id = module.vpc.vpc_id

  tags = merge(
    local.default_tags,
    {
      Name = "${var.postgres_name}-rds-client"
    }
  )
}
resource "aws_security_group_rule" "postgres_client" {
  security_group_id = aws_security_group.postgres_client.id

  type = "egress"
  from_port = module.postgres.db_instance_port
  to_port = module.postgres.db_instance_port
  protocol = "tcp"
  source_security_group_id = aws_security_group.postgres_server.id
  description = "Allow traffic to ${aws_security_group.postgres_server.name} on port ${module.postgres.db_instance_port}"
}
