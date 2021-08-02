resource "aws_ecs_cluster" "linux" {
  name = var.cluster_name

  capacity_providers = [
    aws_ecs_capacity_provider.linux.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.linux.name
    weight = "100"
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.default_tags
}
resource "aws_ecs_capacity_provider" "linux" {
  name = "linux"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.linux.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      status = "ENABLED"
      target_capacity = 2
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
    }
  }
  tags = local.default_tags
}
resource "aws_launch_template" "linux" {
  name = "linux-cluster-node"
  description = "Launch template for Windows instances"

  image_id = "ami-0b9afce559a2ee58e"
  instance_type = var.cluster_instance_type
  update_default_version = true
  disable_api_termination = false
  user_data = base64encode(data.template_file.linux_startup.rendered)
  key_name = aws_key_pair.linux.key_name
  
  vpc_security_group_ids = [
    aws_security_group.ephemeral_ports.id,
    aws_security_group.postgres_client.id,
    aws_security_group.external.id]
  
  iam_instance_profile {
    arn = aws_iam_instance_profile.linux.arn
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.default_tags,
      {
        Name = var.cluster_name
      }
    )
  }
}
data "template_file" "linux_startup" {
  template = file("./templates/cluster-user-data.txt")
  vars = {
    cluster_name = var.cluster_name
  }
}
resource "aws_autoscaling_group" "linux" {
  name = "linux-cluster"

  protect_from_scale_in = true

  min_size = 2
  max_size = 10
  desired_capacity = 2
  default_cooldown = 300

  launch_template {
    name = aws_launch_template.linux.name
    version = aws_launch_template.linux.default_version
  }

  placement_group = aws_placement_group.default.id
  health_check_type = "EC2"

  force_delete = true
  termination_policies = [
    "OldestLaunchTemplate"]

  vpc_zone_identifier = module.vpc.private_subnets

  max_instance_lifetime = 1209600
  # number of seconds === 2 weeks

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"]

  tags = [
    {
      key = "ManagedBy"
      value = "Terraform"
      propagate_at_launch = true
    },
    {
      key = "Environment"
      value = title(var.environment)
      propagate_at_launch = true
    },
    {
      key = "Application"
      value = "Infrastructure"
      propagate_at_launch = true
    },
    {
      key = "Team"
      value = "Expensely"
      propagate_at_launch = true
    },
    {
      key = "AmazonECSManaged"
      value = ""
      propagate_at_launch = true
    }
  ]

  suspended_processes = []

  instance_refresh {
    strategy = "Rolling"
    triggers = [
      "tags"]
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      load_balancers,
      target_group_arns,
      desired_capacity
    ]
  }
}

// IAM
resource "aws_iam_instance_profile" "linux" {
  name = "${var.cluster_name}-ip"
  role = aws_iam_role.linux.name
}
resource "aws_iam_role" "linux" {
  name = "${var.cluster_name}-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "linux_ecs" {
  role = aws_iam_role.linux.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "linux_ssm_core" {
  role = aws_iam_role.linux.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"
}

// Reusable
resource "aws_placement_group" "default" {
  name = "default"
  strategy = "spread"
}
resource "aws_key_pair" "linux" {
  public_key = var.cluster_instance_public_key
  key_name = var.cluster_name
}

resource "aws_security_group" "ephemeral_ports" {
  name = "expensely-ephemeral-ports"
  description = "Allow ephemeral port range"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Ephemeral port range"
    from_port = 32768
    to_port = 61000
    protocol = "tcp"

    security_groups = [
      aws_security_group.alb.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = merge(
  local.default_tags,
  {
    Name = "expensely-ephemeral-ports"
  }
  )
}