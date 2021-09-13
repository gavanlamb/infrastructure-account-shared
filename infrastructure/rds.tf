module "postgres" {
  source = "terraform-aws-modules/rds-aurora/aws"
  version = "5.2.0"

  name = var.postgres_name
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
  name = "${var.postgres_name}-aurora-db-postgres-parameter-group"
  family = "aurora-postgresql10"
  description = "${var.postgres_name}-aurora-db-postgres-parameter-group"
  tags = local.default_tags
}
resource "aws_rds_cluster_parameter_group" "example_postgresql" {
  name = "${var.postgres_name}-aurora-postgres-cluster-parameter-group"
  family = "aurora-postgresql10"
  description = "${var.postgres_name}-aurora-postgres-cluster-parameter-group"
  tags = local.default_tags
}

resource "aws_secretsmanager_secret" "postgres_admin_password" {
  name = "Expensely/DatabaseInstance/Postgres/User/Expensely"
  description = "Admin password for RDS instance:${module.postgres.rds_cluster_id}"

  tags = local.default_tags
}
resource "aws_secretsmanager_secret_version" "postgres_admin_password" {
  secret_id = aws_secretsmanager_secret.postgres_admin_password.id
  secret_string = jsonencode({
    Username = module.postgres.rds_cluster_master_username,
    Password = module.postgres.rds_cluster_master_password,
    Port = module.postgres.rds_cluster_port,
    Endpoint = replace(module.postgres.rds_cluster_endpoint, ":${module.postgres.rds_cluster_port}", "")
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
  from_port = module.postgres.rds_cluster_port
  to_port = module.postgres.rds_cluster_port
  protocol = "tcp"
  source_security_group_id = aws_security_group.postgres_client.id
  description = "Allow traffic from ${aws_security_group.postgres_client.name} on port ${module.postgres.rds_cluster_port}"
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
  from_port = module.postgres.rds_cluster_port
  to_port = module.postgres.rds_cluster_port
  protocol = "tcp"
  source_security_group_id = aws_security_group.postgres_server.id
  description = "Allow traffic to ${aws_security_group.postgres_server.name} on port ${module.postgres.rds_cluster_port}"
}

resource "aws_ssm_document" "create_database" {
  name = "CreateDatabase-${var.postgres_name}"
  document_type = "Command"

  document_format = "YAML"

  tags = local.default_tags

  content = <<DOC
---
schemaVersion: '2.2'
description: aws:runShellScript
parameters:
  databaseName:
    type: String
    description: "(Required) Database name."
    allowedPattern: "^([a-zA-Z0-9_]+)+$"
  username:
    type: String
    description: "(Required) Name of user"
    allowedPattern: "^([a-zA-Z0-9_]+)+$"
  connectionStringParameterStoreName:
    type: String
    description: "(Required) Name of the connection string in parameter store"
    allowedPattern: "^([a-zA-Z0-9_/]+)+$"
mainSteps:
- action: aws:runShellScript
  name: runShellScript
  inputs:
    timeoutSeconds: '300'
    runCommand:
    - |
      Username=$(aws secretsmanager get-secret-value --region '${var.region}' --secret-id ${aws_secretsmanager_secret.postgres_admin_password.id} --query SecretString --output text | jq --raw-output '.Username')
      Password=$(aws secretsmanager get-secret-value --region '${var.region}' --secret-id ${aws_secretsmanager_secret.postgres_admin_password.id} --query SecretString --output text | jq --raw-output '.Password')
      Host=$(aws secretsmanager get-secret-value --region '${var.region}' --secret-id ${aws_secretsmanager_secret.postgres_admin_password.id} --query SecretString --output text | jq --raw-output '.Endpoint')
      Port=$(aws secretsmanager get-secret-value --region '${var.region}' --secret-id ${aws_secretsmanager_secret.postgres_admin_password.id} --query SecretString --output text | jq --raw-output '.Port')

      DatabaseConnectionString="postgresql://$Username:$Password@$Host:$Port/postgres"

      Value=$(psql $DatabaseConnectionString -tc "SELECT 1 FROM pg_database WHERE datname = '{{ databaseName }}'")
      
      if [ $Value = 1 ]
      then
        echo "Database already exists"
      else
        UserPassword=$(tr -dc 'A-Za-z0-9!"#' </dev/urandom | head -c 15)
        UserPassword=$UserPassword'88##'
  
        psql $DatabaseConnectionString --command="create database {{ databaseName }};"
        psql $DatabaseConnectionString --command="create user {{ username }} with encrypted password '$UserPassword';"
        psql $DatabaseConnectionString --command="grant all privileges on database {{ databaseName }} to {{ username }};"
  
        ConnectionString="Host=$Host;Port=$Port;Database={{ databaseName }};Username={{ username }};Password=$UserPassword;Keepalive=300;CommandTimeout=300;Timeout=300"
  
        aws ssm put-parameter --region '${var.region}' --name "{{ connectionStringParameterStoreName }}" --value "$ConnectionString" --type "SecureString"
      fi
DOC
}

resource "aws_ssm_document" "drop_database" {
  name = "DropDatabase-${var.postgres_name}"
  document_type = "Command"

  document_format = "YAML"

  tags = local.default_tags

  content = <<DOC
---
schemaVersion: '2.2'
description: aws:runShellScript
parameters:
  databaseName:
    type: String
    description: "(Required) Database name."
    allowedPattern: "^([a-zA-Z0-9_]+)+$"
  username:
    type: String
    description: "(Required) Name of user"
    allowedPattern: "^([a-zA-Z0-9_]+)+$"
  connectionStringParameterStoreName:
    type: String
    description: "(Required) Name of the connection string in parameter store"
    allowedPattern: "^([a-zA-Z0-9_/]+)+$"
mainSteps:
- action: aws:runShellScript
  name: runShellScript
  inputs:
    timeoutSeconds: '300'
    runCommand:
    - |
      Username=$(aws secretsmanager get-secret-value --region '${var.region}' --secret-id ${aws_secretsmanager_secret.postgres_admin_password.id} --query SecretString --output text | jq --raw-output '.Username')
      Password=$(aws secretsmanager get-secret-value --region '${var.region}' --secret-id ${aws_secretsmanager_secret.postgres_admin_password.id} --query SecretString --output text | jq --raw-output '.Password')
      Host=$(aws secretsmanager get-secret-value --region '${var.region}' --secret-id ${aws_secretsmanager_secret.postgres_admin_password.id} --query SecretString --output text | jq --raw-output '.Endpoint')
      Port=$(aws secretsmanager get-secret-value --region '${var.region}' --secret-id ${aws_secretsmanager_secret.postgres_admin_password.id} --query SecretString --output text | jq --raw-output '.Port')

      DatabaseConnectionString="postgresql://$Username:$Password@$Host:$Port/postgres"

      Value=$(psql $DatabaseConnectionString -qtc "SELECT 1 FROM pg_database WHERE datname = '{{ databaseName }}'")
      echo $Value
      
      if [ $Value = 1 ]
      then
        psql $DatabaseConnectionString --command="UPDATE pg_database SET datallowconn = 'false' WHERE datname = '{{ databaseName }}';"
        psql $DatabaseConnectionString --command="SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '{{ databaseName }}';"
        psql $DatabaseConnectionString --command="drop database {{ databaseName }};"
        psql $DatabaseConnectionString --command="drop user {{ username }};"

        aws ssm delete-parameter --region '${var.region}' --name "{{ connectionStringParameterStoreName }}"
      else
        echo "Database doesn't exist"
      fi
DOC
}
