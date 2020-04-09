#
# Create IAM Role
#

data "aws_iam_policy_document" "bigip_role" {
  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bigip_role" {
  name               = format("%s-bigip-role", var.owner)
  assume_role_policy = data.aws_iam_policy_document.bigip_role.json

  tags = {
    Name        = format("%s-bigip-role-%s", var.owner, var.random_id)
    Terraform   = "true"
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "bigip_profile" {
  name = format("%s-bigip-profile", var.owner)
  role = aws_iam_role.bigip_role.name
}

data "aws_iam_policy_document" "bigip_policy" {
  version = "2012-10-17"
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      data.aws_secretsmanager_secret.password.arn
    ]
  }
}

resource "aws_iam_role_policy" "bigip_policy" {
  name   = format("%s-bigip-policy", var.owner)
  role   = aws_iam_role.bigip_role.id
  policy = data.aws_iam_policy_document.bigip_policy.json
}
