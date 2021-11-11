###################################################
# NETWORKING RESOURCES
###################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.vpc_azs
  public_subnets = var.vpc_public_subnets
  private_subnets = var.vpc_application_subnets
  database_subnets = var.vpc_database_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Tier = "public"
  }
  private_subnet_tags = {
    Tier = "private"
  }
  database_subnet_tags = {
    Tier = "database"
  }
}

// Security groups
/// External access
resource "aws_security_group" "external" {
  name = "external"
  description = "Allow all outbound traffic"
  vpc_id = module.vpc.vpc_id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Name = "external"
  }
}