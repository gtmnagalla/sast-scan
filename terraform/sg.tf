## Create Security Groups ##

# Create ALB Security Group
resource "aws_security_group" "alb-sg" {
    name        = "allow_http"
    description = "Allow HTTP inbound traffic"
    vpc_id      = aws_vpc.app-vpc.id

    ingress {
        description      = "HTTP from VPC"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "alb sg"
    }
}

# App Server Security Group
resource "aws_security_group" "app-sg" {
    name        = "app-sg"
    description = "Allow http inbound traffic from ALB"
    vpc_id      = aws_vpc.app-vpc.id

    ingress {
        description      = "HTTP from ALB"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        security_groups  = [aws_security_group.alb-sg.id]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "app sg"
    }
}

# RDS instance Security Group

resource "aws_security_group" "rds-sg" {
    name        = "rds-sg"
    description = "Allow MySql inbound traffic from app-server"
    vpc_id      = aws_vpc.app-vpc.id

    ingress {
        description      = "HTTP from ALB"
        from_port        = 3306
        to_port          = 3306
        protocol         = "tcp"
        security_groups  = [aws_security_group.app-sg.id]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "db sg"
    }
}
