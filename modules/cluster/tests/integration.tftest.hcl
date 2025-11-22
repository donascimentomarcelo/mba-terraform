provider "aws" {
  region = "us-east-1"
}

variables {
  prefix = "test"
}

run "network" {
  command = apply

  variables {
    vpc_cidr_block     = "10.0.0.0/18"
    subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24"]
  }

  module {
    source = "../network"
  }

  assert {
    condition     = length(output.subnet_id) == 2
    error_message = "There should have been created 2 subnets"
  }
}

run "cluster" {
  command = apply

  variables {
    prefix = run.network.subnet_id
    # cidr_block         = "10.0.0.0/16"
    subnet_cidr_blocks = [run.network.secutiry_group_id]
    # instance_count     = 2
    vpc_id           = run.network.vpc_id
    user_data        = <<EOF
#!/bin/bash
yum update -y
yum install -y nginx
systemctl start nginx
EOF
    desired_capacity = 1
    min_size         = 1
    max_size         = 1
    scale_in = {
      scaling_adjustment = -1
      cooldown           = 60
      threshold          = 20
    }
    scale_out = {
      scaling_adjustment = 1
      cooldown           = 60
      threshold          = 20
    }
  }

  assert {
    condition     = aws_lb.main.dns_name != null
    error_message = "Invalid DNS name"
  }

  assert {
    condition     = output.lb_arn != null
    error_message = "Invalid LB ARN"
  }
}

run "verify_http" {
  command = apply

  variables {
    lb_arn = run.cluster.lb_arn
  }

  module {
    source = "./testing/http"
  }

  assert {
    condition     = data.http.lb.status_code == 200
    error_message = "HTTP request failed"
  }
}
