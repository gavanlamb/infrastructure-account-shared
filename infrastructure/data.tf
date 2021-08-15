data "aws_caller_identity" "current" {}

data "aws_kms_alias" ssm_default_key{
  name = "alias/aws/ssm"
}
