#Create a private key which can be used to login to the webserver
resource "tls_private_key" "Web-Key" {
  algorithm = "RSA"
}

#Save public key attributes from the generated key
resource "aws_key_pair" "App-Instance-Key" {
  key_name   = "Web-key"
  public_key = tls_private_key.Web-Key.public_key_openssh
}

#Save the key to your local system
resource "local_file" "Web-Key" {
    content     = tls_private_key.Web-Key.private_key_pem 
    filename = "Web-Key.pem"
}

// Creting Auto Scaling Group EC2 Instances Security Group

resource "aws_security_group" "asg-sg" {
  name        = "ASG_SG"
  description = "Allow inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups   = [var.security_group]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // It shoud be accessible from company IP add range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ASG-SG"
  }
}

// Creating ASG Launch Configuration

resource "aws_launch_configuration" "my-web-launch-config" {
  name = "My-ASG-Config"
  image_id        = var.image_id 
  instance_type   = var.instance_type 
  key_name = "Web-key"
  security_groups = [aws_security_group.asg-sg.id] 
  //associate_public_ip_address = true 
  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y install httpd php git 
              sudo rm -rf /var/www/html/*
              sudo git clone https://github.com/robiul-hub/Techtest.git  /var/www/html
              sudo systemctl start httpd
              chkconfig httpd on
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

// Creating ASG

resource "aws_autoscaling_group" "web_asg" {
  name = "My-ASG"
  launch_configuration = aws_launch_configuration.my-web-launch-config.name
  vpc_zone_identifier  = [var.subnet1,var.subnet2] 
  target_group_arns    = [var.target_group_arn]
  health_check_type    = "ELB"

  min_size = var.min_size
  desired_capacity = var.desired_capacity
  max_size = var.max_size

enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

   metrics_granularity = "1Minute" 

tags = [
    {
    key                 = "Name"
    value               = "WebServer"
    propagate_at_launch = true
  }
]
}

// Creating ASG Policy for scale out and scale in

resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "70" 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_up.arn ]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_down.arn ]
}
