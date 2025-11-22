provider "aws" {
  region = "us-east-1"
}

variables {
  prefix             = "test"
  cidr_block     = "10.0.0.0/18"
  subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24"]
}

run "validate_vpc" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/18"
    error_message = "Unexpected VPC CIDR block"
  }

  assert {
    condition     = aws_vpc.main.tags.Name == "test-vpc"
    error_message = "Unexpected name tag"
  }
}

run "validate_subnets" {
  command = plan

  assert {
    condition     = length(aws_subnet.main) == length(var.subnet_cidr_blocks)
    error_message = "Incorrect number of subnets"
  }

  assert {
    condition     = aws_subnet.main[0].cidr_block == var.subnet_cidr_blocks[0]
    error_message = "Incorrect CIDR block for subnet 0"
  }

  assert {
    condition     = aws_subnet.main[1].cidr_block == var.subnet_cidr_blocks[1]
    error_message = "Incorrect CIDR block for subnet 1"
  }

  assert {
    condition     = aws_subnet.main[0].availability_zone != aws_subnet.main[1].availability_zone
    error_message = "The su bnets should not be in the same AZ"
  }
}
