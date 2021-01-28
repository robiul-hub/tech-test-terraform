
# Creating Target Group

resource "aws_lb_target_group" "my-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "ALB-tg" 
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

# Creating Application Load Balancer

resource "aws_lb" "my-aws-alb" {
  name     = "my-alb"
  internal = false
  
  security_groups = [var.security_group]
  
  subnets = [
    "var.subnet1,
    var.subnet2
  ]

  tags = {
    Name = "My-ALB" 
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

# Creating Listener

resource "aws_lb_listener" "my-test-alb-listner" {
  load_balancer_arn = aws_lb.my-aws-alb.arn 
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-target-group.arn 
  }
}

