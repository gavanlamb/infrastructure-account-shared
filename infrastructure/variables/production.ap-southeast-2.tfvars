environment="Production"
region="ap-southeast-2"

alb_name="expensely"
alb_default_certificate_domain="*.expensely.com.au"

bastion_name="expensely-bastion"
bastion_bucket_name="expensely-bastion-production"
bastion_instance_size="t3.micro"
bastion_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuTD8qcTvusT9E2mGEXHleaGToGCSK654a4Rr5s/IOdIgBt6ffbmGeI4KZxjTq6hIGGnkGQogwuyWN3EmvQ5+/Uf4cVBMnVhDtN9Km10FtNYr1bAi+tWhK2s6ucoyrPtmkBpUv4/eoH/CygYroI76CeXgTgbz5twfBC7UP58IPR5ZbvVMr7Mo7Cx0gm+AOxhV3WLZFmRFcLAsv6hW69URg5TlATHYYNngxNgoyTj/Vcz6DuuzWjySfXyuKcXfURG9vrLKdxEX2v4DKQzZtVJeqxiE4RZ5SxNUTNZEpOuzcGFEow14/JWeNfmK/Tg96Fz2NsJ0hvq4zxV7lzDnoyEjre8B9qAibCYGQD7rJrWgJgjbM5M3dlsCYltno4PlgIx0wq8LR5CeLpFeocNBorF5XypSXP+ourBgP37a495cXA/YxhCQuEh1hn2T2PpSwE/Tt2dhq3zEkBviJvG7NRjTsSR7rLmM6KKKVEkCgoP3My4bybrdoMn+A6WbyJjFirmE= ec2-user"

code_deploy_role_name="expensely-code-deploy"
code_deploy_bucket_name="expensely-code-deploy-production"

vpc_name="expensely"
vpc_cidr="10.12.128.0/17"
vpc_azs=["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
vpc_public_subnets=["10.12.128.0/22", "10.12.132.0/22", "10.12.136.0/22"]
vpc_application_subnets=["10.12.160.0/22", "10.12.164.0/22", "10.12.168.0/22"]
vpc_database_subnets=["10.12.192.0/22", "10.12.196.0/22", "10.12.200.0/22"]
