// TODO remover secrets da aws secrets manager
resource "aws_launch_template" "main" {
  name          = "${var.prefix}-template"
  image_id      = "ami-0157af9aea2eef346"
  instance_type = "t3.micro"

  user_data = base64encode(
    <<EOF
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
systemctl enable nginx
public_ip=$(curl http://checkip.amazonaws.com)
echo "<html>
  <head><title>My Web Server</title></head>
  <body>
    <h1>Hello, World!</h1>
    <p>My public IP address is $public_ip</p>
  </body>
</html>" | tee /usr/share/nginx/html/index.html > /dev/null
systemctl restart nginx
EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = var.security_group_id
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-bastion-host"
    }
  }
}

resource "aws_autoscaling_group" "main" {
  name                = "${var.prefix}-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.subnet_id
  target_group_arns   = [aws_alb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "${var.prefix}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "${var.prefix}-scale-out-alarm"
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_out_policy.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "60"
  statistic           = "Average"
  evaluation_periods  = "3"
  period              = "30"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "${var.prefix}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "${var.prefix}-scale-in-alarm"
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_in_policy.arn]
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "20"
  statistic           = "Average"
  evaluation_periods  = "3"
  period              = "30"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
}

resource "aws_alb" "main" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_id
  subnets            = var.subnet_id

  enable_deletion_protection = false

  tags = {
    Name = "${var.prefix}-alb"
  }
}

resource "aws_alb_target_group" "main" {
  name     = "${var.prefix}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/" // TODO path especifico para o health check, no caso do spring, seria /actuator/health
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.prefix}-target-group"
  }
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main.arn
  }
}
