data "aws_caller_identity" "current" {}

locals {
    account_id     = data.aws_caller_identity.current.account_id
}

# Create KMS key for RDS
resource "aws_kms_key" "rds_key" {
  description             = "Custom KMS key for RDS storage encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "rds_key_policy" {
  key_id = aws_kms_key.rds_key.id
  policy = jsonencode({
    Id        = "rds-kms",
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*",
      },
      {
        Sid       = "Allow use of KMS via RDS",
        Effect    = "Allow",
        Principal = { AWS = "*" },
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:DescribeKey",
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:ViaService" = "rds.us-east-1.amazonaws.com",
          },
        },
      },
    ],
  })
}

resource "aws_kms_alias" "rds_kms_alias" {
  name          = "alias/rds-key"
  target_key_id = aws_kms_key.rds_key.key_id
}