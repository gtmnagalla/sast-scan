# Configure AWS backup for RDS(optional)

# IAM role for aws backup

locals {
  backup_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  ]
}

resource "aws_iam_role" "backup-role" {
  name = "backup-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "backup.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "backup-role-policy" {
  count      = length(local.backup_policy_arns)
  role       = aws_iam_role.backup-role.name
  policy_arn = element(local.backup_policy_arns, count.index)
}

# backup vault
resource "aws_backup_vault" "backup-vault" {
  name = "backup-vault"
}

# backup plan
resource "aws_backup_plan" "backup-plan" {
  name = "backup-plan"
  rule {
    rule_name = "backup-rule"
    target_vault_name = aws_backup_vault.backup-vault.name
    schedule = "cron(0 12 * * ? *)"
    start_window = 60
    completion_window = 120
  }
}

# backup resource selection(RDS- primary database)
resource "aws_backup_selection" "backup-selection" {
  name = "backup-selection-rds"
  iam_role_arn = aws_iam_role.backup-role.arn
  resources = [aws_db_instance.primary_db.arn]
  plan_id = aws_backup_plan.backup-plan.id
}