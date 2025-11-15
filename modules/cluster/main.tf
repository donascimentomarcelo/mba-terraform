data "aws_secretsmanager_secret" "main" {
  arn = "arn:aws:secretsmanager:us-east-1:462839258964:secret:prod/Terraform/Db-qbASJq"
}

data "aws_secretsmanager_secret_version" "main" {
  secret_id = data.aws_secretsmanager_secret.main.id
}

resource "aws_launch_template" "main" {
  name          = "${var.prefix}-template"
  image_id      = "ami-0157af9aea2eef346"
  instance_type = "t3.micro"

  user_data = base64encode(
    <<EOF
      #!/bin/bash
      DB_STRING="Server=${jsondecode(data.aws_secretsmanager_secret_version.main.secret_string)["Host"]};DB=${jsondecode(data.aws_secretsmanager_secret_version.main.secret_string)["DB"]};

      echo $DB_STRING > test.txt
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
