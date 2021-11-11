﻿resource "aws_s3_bucket" "test_results_bucket" {
  bucket = var.test_results_bucket_name
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
}
resource "aws_s3_bucket_public_access_block" "test_results_bucket" {
  bucket = aws_s3_bucket.test_results_bucket.id

  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}
resource "aws_iam_policy" "test_results_bucket" {
  name = var.test_results_policy_name
  description = "Policy for uploading object to test results bucket"
  policy = data.aws_iam_policy_document.test_results_bucket.json
}
data "aws_iam_policy_document" "test_results_bucket" {
  statement {
    sid = "1"

    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      aws_s3_bucket.test_results_bucket.arn,
      "${aws_s3_bucket.test_results_bucket.arn}/*"
    ]
  }
}