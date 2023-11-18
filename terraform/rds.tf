# Create a RDS database(Primary and Read Replica)
# db subnet group
resource "aws_db_subnet_group" "db-group" {
    name       = "db-subnet-group"
    subnet_ids = [aws_subnet.subnet-db-1a.id, aws_subnet.subnet-db-1b.id]

    tags = {
        Name = "DB subnet group"
    }
}

## configure ssm parameter store for db password ##

# random password. cryptographic random number generator
resource "random_password" "random-password1" {
  length           = 16
  special          = true
  override_special = "!#$%&*"
}


# SSM parameter store for db1 secret (saved as a secure string)
resource "aws_ssm_parameter" "rds1_secret" {
  name  = "/database/rds1/secret"  # Adjust the path as needed
  type  = "SecureString"
  value = random_password.random-password1.result
}

# Primary mysql db instance
resource "aws_db_instance" "primary_db" {
    allocated_storage               = 22
    storage_type                    = "gp2"
    identifier                      = "db-pri"
    engine                          = "mysql"
    engine_version                  = "8.0.33"
    instance_class                  = "db.t3.micro"
    parameter_group_name            = "default.mysql8.0"
    username                        = "admin"
    password                        = aws_ssm_parameter.rds1_secret.value  # Use the secret value stored in ssm
    skip_final_snapshot             = true
    backup_retention_period         = 7       # backup retention period:7days. Note: AWS takes automatic backup of the RDS db.
    vpc_security_group_ids          = [aws_security_group.rds-sg.id]
    db_subnet_group_name            = aws_db_subnet_group.db-group.name
    storage_encrypted               = true
    kms_key_id                      = aws_kms_key.rds_key.arn  # Use the custom KMS key
    enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery", "general"]  # enable cloudwatch logging
    multi_az                        = true

    tags = {
        Name = "primary db"
    }
}

# Create the db read replica
resource "aws_db_instance" "read_replica" {
    depends_on                      = [aws_db_instance.primary_db]  # Ensure the primary DB is created first
    identifier                      = "db-replica"
    instance_class                  = "db.t3.micro"
    parameter_group_name            = "default.mysql8.0"
    replicate_source_db             = aws_db_instance.primary_db.identifier  # Specify the primary DB here
    skip_final_snapshot             = true
    backup_retention_period         = 7
    storage_encrypted               = true
    kms_key_id                      = aws_kms_key.rds_key.arn  # Use the custom KMS key
    enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery", "general"]  # enable CloudWatch logging
    multi_az                        = true

    tags = {
        Name = "db read replica"
    }
}