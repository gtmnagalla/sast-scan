# Create Application Loadbalancer for app servers

# Target group
resource "aws_lb_target_group" "alb-tg" {
    name     = "alb-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.app-vpc.id

    # Enable session stickiness settings(because phpmyadmin is a stateful application)
    stickiness {
        type          = "lb_cookie"
        enabled       = true
        cookie_duration = 3600  # Stickiness duration in seconds
    }
    
    health_check {
        path                = "/"
        port                = 80
        protocol            = "HTTP"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

# ALB
resource "aws_lb" "app-alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.subnet-web-1a.id, aws_subnet.subnet-web-1b.id]

  access_logs {
    bucket  = aws_s3_bucket.mybucket.id
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Environment = "dev"
  }
}

# alb listener
resource "aws_lb_listener" "alb-list" {
  load_balancer_arn = aws_lb.app-alb.arn
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"  # New ssl certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}
