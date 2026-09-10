# Deployment Guide — AWS Secure VPC

This document explains how to reproduce the project on another machine.

## 1. Install prerequisites

Install:

- Git
- AWS CLI v2
- Terraform >= 1.6

Verify:

```bash
git --version
aws --version
terraform --version
```

## 2. Configure an AWS identity

Use a dedicated IAM identity for the lab. Do not hard-code keys in Terraform files.

```bash
aws configure
```

Set the default region to `ap-south-1`.

Verify:

```bash
aws sts get-caller-identity
```

## 3. Clone the repository

```bash
git clone https://github.com/ankityadav1asia/aws-secure-vpc.git
cd aws-secure-vpc
```

## 4. Configure Terraform

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
```

Create a local `terraform.tfvars` file. It is intentionally excluded from Git:

```hcl
aws_region   = "ap-south-1"
project_name = "ankit-secure-vpc"
environment  = "dev"
db_password  = "REPLACE_WITH_A_STRONG_PASSWORD"
```

Review the plan:

```bash
terraform plan
```

Deploy:

```bash
terraform apply
```

## 5. Verify the deployment

### EC2

```powershell
aws ec2 describe-instances --filters "Name=tag:Name,Values=ankit-secure-vpc-app-server" --query "Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress,PublicIpAddress]" --output table
```

Expected: two running instances with no public IPs.

### ALB

```powershell
aws elbv2 describe-load-balancers --names ankit-secure-vpc-alb --query "LoadBalancers[0].[DNSName,State.Code]" --output table
```

### RDS

```powershell
aws rds describe-db-instances --db-instance-identifier ankit-secure-vpc-mysql --query "DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,PubliclyAccessible]" --output table
```

Expected: `available` and `False`.

### WAF

```powershell
aws wafv2 get-web-acl-for-resource --resource-arn $(aws elbv2 describe-load-balancers --names ankit-secure-vpc-alb --query "LoadBalancers[0].LoadBalancerArn" --output text) --region ap-south-1 --query "WebACL.[Name,ARN]" --output table
```

### VPC Flow Logs

```powershell
aws ec2 describe-flow-logs --query "FlowLogs[].[FlowLogId,FlowLogStatus,ResourceId]" --output table
```

Expected: `ACTIVE`.

### CloudTrail

```powershell
aws cloudtrail get-trail --name ankit-secure-vpc-trail --query "Trail.[Name,IsMultiRegionTrail,LogFileValidationEnabled,S3BucketName]" --output table
```

## 6. Cross-platform notes

### Windows

Use PowerShell. Replace Bash-specific path syntax as needed. AWS CLI and Terraform behave the same way once installed and configured.

### Linux / macOS

Use a shell such as Bash or Zsh. The Terraform workflow is the same:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

## 7. Teardown

From `terraform/`:

```bash
terraform destroy
```

Review the resources carefully and confirm destruction.

For a lab, destroying the whole stack is safer than trying to remember every billable component individually.

## 8. Rebuild

After destruction, the environment can be recreated from code:

```bash
terraform init
terraform plan
terraform apply
```

Terraform will provision the declared architecture again.
