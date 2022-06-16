resource "aws_kms_key" "secretsmanager" {
  description = "KMS key for secrets manager"
  deletion_window_in_days = 10
  policy = data.aws_iam_policy_document.secretsmanager.json
}

resource "aws_kms_alias" "secretsmanager" {
  name = "alias/expensely/${lower(var.environment)}/secretsmanager"
  target_key_id = aws_kms_key.secretsmanager.key_id
}

data "aws_iam_policy_document" "secretsmanager" {
  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [
      "*"
    ]
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [
        "secretsmanager.${var.region}.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [
      "*"
    ]
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = [
        "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:*"
      ]
    }
  }
}