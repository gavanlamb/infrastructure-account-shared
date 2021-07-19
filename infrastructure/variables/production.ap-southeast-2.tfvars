environment="Production"
region="ap-southeast-2"

alb_name="expensely"
alb_default_certificate_domain="*.expensely.com.au"

vpc_name="expensely"
vpc_cidr="10.12.128.0/17"
vpc_azs=["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
vpc_public_subnets=["10.12.128.0/22", "10.12.132.0/22", "10.12.136.0/22"]
vpc_application_subnets=["10.12.160.0/22", "10.12.164.0/22", "10.12.168.0/22"]
vpc_database_subnets=["10.12.192.0/22", "10.12.196.0/22", "10.12.200.0/22"]
