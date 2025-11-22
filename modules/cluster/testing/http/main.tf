terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }

  required_version = "~> 1.9.6"
}

data "aws_lb" "main" {
  arn = var.lb_arn
}

data "http" "lb" {
  url = "http://${data.aws_lb.main.dns_name}"
  #   request_timeout = 5000
  retry {
    attempts     = 5
    min_delay_ms = 1000
    max_delay_ms = 10000
  }
}
