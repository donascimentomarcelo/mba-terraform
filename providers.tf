terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }

  required_version = "~> 1.9.6"
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}
