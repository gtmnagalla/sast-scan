# Create App server configuration

locals {
  userdata = templatefile("data.sh", {
    ssm_cloudwatch_config = aws_ssm_parameter.cw_agent.name
  })
}

# Create a Launch Template
resource "aws_launch_template" "ec2_template" {
    name_prefix        = "ec2-template"

    # Specify instance settings
    instance_type = "t3.micro"
    image_id      = "ami-05c13eab67c5d8861"  # Amazon Linux AMI ID
    vpc_security_group_ids = [aws_security_group.app-sg.id]
    iam_instance_profile {
        name = aws_iam_instance_profile.app.name  # configure instance profile
    }

    user_data = base64encode(local.userdata)  #user data from the local variables

    tag_specifications {
        resource_type = "instance"
        tags = {
        Name = "AppInstance"
        Environment = "Development"
        }
    }
}

# Create Autoscaling group
resource "aws_autoscaling_group" "app-asg" {
    name                 = "my-app"
    vpc_zone_identifier  = [aws_subnet.subnet-app-1a.id, aws_subnet.subnet-app-1b.id]
    target_group_arns    = [aws_lb_target_group.alb-tg.arn]
    desired_capacity     = 2
    max_size             = 2
    min_size             = 2
    health_check_type    = "EC2"

    launch_template {
        id      = aws_launch_template.ec2_template.id
        version = aws_launch_template.ec2_template.latest_version
    }
}

# Autoscaling policy based on CPU utilization
resource "aws_autoscaling_policy" "cpu_scaling_policy" {
    name                        = "cpu-scaling-policy"
    policy_type                 = "TargetTrackingScaling"
    estimated_instance_warmup   = 30
    autoscaling_group_name      = aws_autoscaling_group.app-asg.name

    target_tracking_configuration {
        predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
        }

    target_value = 50
  }
}

# Create SSM Parameter resource, and load its value from the file(cw_agent_config.json)
resource "aws_ssm_parameter" "cw_agent" {
  description = "Cloudwatch agent config to configure custom log"
  name        = "/cloudwatch-agent/config"
  type        = "String"
  value       = file("cw_agent_config.json") # Cloudwatch Agent Configuration file, the config will instruct the agent on how to pull the logs and metric.
}