# Scalable AWS Infrastructure with Terraform

Infrastructure-as-code lab for provisioning a scalable web workload on AWS. The project separates networking and compute concerns into reusable Terraform modules and explores remote state, workspaces, automated scaling, load balancing, and native Terraform tests.

> This repository is an educational project developed during postgraduate studies. Review the security, cost, and environment-specific settings before using any part of it outside a sandbox account.

## Current status

The network module and its plan assertions represent the most complete part of the lab. The cluster integration path is still a work in progress: its output resource reference and some test inputs need alignment before the complete root configuration can be applied successfully. The commands below describe the intended workflow after those items are resolved.

## Architecture

```text
Internet
   |
Application Load Balancer
   |
Target Group
   |
Auto Scaling Group
   |
EC2 instances across public subnets

CloudWatch alarms -> scale-in / scale-out policies
Terraform state   -> pre-existing encrypted S3 backend
```

The infrastructure includes:

- VPC distributed across multiple availability zones
- Public subnets, internet gateway, route table, and associations
- Security group for HTTP and SSH access
- EC2 launch template with configurable user data
- Application Load Balancer and target group health checks
- Auto Scaling Group with CloudWatch CPU alarms
- Scale-in and scale-out policies
- Encrypted remote state stored in Amazon S3

## Repository structure

```text
.
|-- main.tf                         # Root module composition
|-- providers.tf                    # AWS provider and S3 backend
|-- variables.tf                    # Root input contract
|-- outputs.tf                      # S3 backend metadata
`-- modules
    |-- network                     # VPC, subnets, routes, gateway, and security group
    |   `-- tests                   # Terraform unit-style plan assertions
    `-- cluster                     # ALB, EC2 launch template, ASG, alarms, and policies
        |-- testing/http            # HTTP verification helper
        `-- tests                   # Integration-test experiment
```

## Technology

- Terraform `~> 1.9.6`
- HashiCorp AWS provider `~> 5.49`
- Amazon VPC, EC2, Auto Scaling, Elastic Load Balancing, CloudWatch, and S3

## Prerequisites

- Terraform 1.9.x
- AWS CLI with a configured `default` profile
- An AWS account with permissions to provision the listed resources
- A pre-existing S3 bucket named `terraform-mba` in `us-east-1` for remote state

Confirm the active AWS identity before provisioning:

```bash
aws sts get-caller-identity
```

## Configuration

Create a local `terraform.tfvars` file. Do not commit account-specific values or secrets.

```hcl
prefix             = "web-lab"
cidr_block         = "10.0.0.0/18"
subnet_cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24"]
instance_count     = 2

user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y nginx
  systemctl enable --now nginx
EOF

desired_capacity = 2
min_size         = 1
max_size         = 4

scale_out = {
  scaling_adjustment = 1
  cooldown           = 60
  threshold          = 70
}

scale_in = {
  scaling_adjustment = -1
  cooldown           = 120
  threshold          = 25
}
```

## Intended provisioning workflow

```bash
terraform init
terraform fmt -check -recursive
terraform validate

terraform workspace new dev || terraform workspace select dev
terraform plan -out=main.tfplan
terraform apply main.tfplan
```

Inspect the resulting state and outputs:

```bash
terraform show
terraform output
```

Destroy the sandbox resources when they are no longer needed:

```bash
terraform destroy
```

## Tests

The network module contains plan-based assertions for the VPC and subnet topology:

```bash
terraform -chdir=modules/network init
terraform -chdir=modules/network test
```

The cluster test directory is an integration-testing experiment that provisions real AWS resources and performs an HTTP check. It may incur costs and should be reviewed and completed before execution.

## Production-readiness considerations

This lab intentionally favors visibility over production hardening. Before adapting it to a real environment:

- Restrict SSH ingress instead of allowing `0.0.0.0/0`.
- Prefer private application subnets and controlled egress.
- Parameterize the AMI and validate it through SSM or an image pipeline.
- Use HTTPS, certificate management, and a dedicated health endpoint.
- Add state locking, least-privilege IAM, encryption policies, and centralized logs.
- Validate quotas, recovery objectives, scaling thresholds, and cost limits.
- Complete and continuously run the integration tests in an isolated account.

## Learning goals

- Compose infrastructure through focused Terraform modules.
- Keep environments isolated with workspaces and naming prefixes.
- Model horizontal scaling based on operational signals.
- Exercise infrastructure behavior through Terraform-native tests.
- Make security and reliability trade-offs explicit.
