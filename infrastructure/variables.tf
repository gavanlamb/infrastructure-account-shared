variable "environment" {
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
variable "alb_default_certificate_domain" {
  type = string
  description = "Domain name that has a certificate. The found cert will be the default for the load balancer."
}

locals {
  default_tags = {
    Application = "Expensely"
    Team        = "Expensely"
  }
}
