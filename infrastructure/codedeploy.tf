resource "aws_iam_role" "codedeploy_role" {
  name = var.code_deploy_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "codedeploy_role_ecs_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_s3_bucket" "codedeploy_bucket" {
  bucket = var.code_deploy_bucket_name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true
  }
}
resource "aws_s3_bucket_public_access_block" "codedeploy_bucket" {
  bucket = aws_s3_bucket.codedeploy_bucket.id
  
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}
resource "aws_iam_policy" "codedeploy_bucket" {
  name = var.code_deploy_policy_name
  description = "Policy for uploading object to code deploy results bucket"
  policy = data.aws_iam_policy_document.codedeploy_bucket.json
}
data "aws_iam_policy_document" "codedeploy_bucket" {
  statement {
    sid = "1"

    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      aws_s3_bucket.codedeploy_bucket.arn,
      "${aws_s3_bucket.codedeploy_bucket.arn}/*"
    ]
  }
}