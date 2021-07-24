﻿variable "environment" {
  type = string
  description = "Name of the environment the infrastructure is for."
}
variable "region" {
  type = string
  description = "Name of the AWS region to deploy resources to"
}

variable "alb_name" {
  type = string
  description = "Name of the application load balancer"
}

variable "bastion_name" {
  type = string
  description = "Bastion name"
}
variable "bastion_bucket_name" {
  type = string
  description = "Name of the bucket for the bastion service"
}
variable "bastion_instance_size" {
  type = string
  description = "Instance size of the bastion host"
}
variable "bastion_public_key" {
  type = string
  description = "Public key for the bastion host."
}

variable "cluster_name" {
  type = string
  description = "Name of the ECS cluster"
}
variable "cluster_instance_type" {
  type = string
  description = "Name of the ECS cluster"
}
variable "cluster_instance_public_key" {
  type = string
  description = "Name of the ECS cluster"
}

variable "code_deploy_role_name" {
  type = string
  description = "Name of the role for CodeDeploy"
}
variable "code_deploy_bucket_name" {
  type = string
  description = "Bucket name for CodeDeploy artifacts."
}

variable "postgres_name" {
  type = string
  description = "Name of the postgres instance"
}

variable "vpc_name" {
  description = "The name of the VPC for the given environment and region."
  type        = string
}
variable "vpc_cidr" {
  description = "The VPC-level CIDR block for a given VPC."
  type        = string
}
variable "vpc_azs" {
  description = "The Availability Zones to activate for a given VPC."
  type        = list(string)
}
variable "vpc_public_subnets" {
  description = "The subnet-level CIDR block for a given public subnet."
  type        = list(string)
}
variable "vpc_application_subnets" {
  description = "The subnet-level CIDR block for a given private/application subnet."
  type        = list(string)
}
variable "vpc_database_subnets" {
  description = "The subnet-level CIDR block for a given database subnet."
  type        = list(string)
}

variable "expensely_io_name" {
  type = string
}
variable "expensely_io_records" {
  type = list(any)
  default = null
}

locals {
  create_expensely_io_route53_records = var.expensely_io_records != null ? true : false

  default_tags = {
    Application = "Expensely"
    Team        = "Expensely"
  }
}
