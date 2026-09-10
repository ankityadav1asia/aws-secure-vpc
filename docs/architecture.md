# AWS Secure VPC — Architecture Explained

## 1. Goal

This project implements a secure, multi-AZ, three-tier AWS environment using Terraform.

The design separates the workload into:

- **Public tier:** internet-facing Application Load Balancer and public networking
- **Private application tier:** EC2 instances managed by an Auto Scaling Group
- **Private database tier:** RDS MySQL

Security and observability are added through AWS WAF, IAM/SSM, CloudTrail, S3, VPC Flow Logs, and CloudWatch Logs.

## 2. High-level request flow

```text
Client
  |
  v
Internet
  |
  v
AWS WAF
  |
  v
Application Load Balancer
  |
  +-----------------------+
  |                       |
  v                       v
EC2 App AZ-A          EC2 App AZ-B
  |                       |
  +-----------+-----------+
              |
              v
         RDS MySQL
       Private DB Tier
```

The ALB is the public entry point. The EC2 application tier is private, so users do not connect directly to the instances. The database is private and should only accept database traffic from the application tier.

## 3. VPC and subnet layout

The VPC uses `10.0.0.0/16` and spans two Availability Zones in `ap-south-1`.

### Public subnets

- `10.0.1.0/24` — Availability Zone A
- `10.0.2.0/24` — Availability Zone B

These provide the public networking needed by the internet-facing ALB and route internet traffic through the Internet Gateway.

### Private application subnets

- `10.0.11.0/24` — Availability Zone A
- `10.0.12.0/24` — Availability Zone B

EC2 instances run here. They have private addresses and use NAT Gateways when they need outbound internet access.

### Private database subnets

- `10.0.21.0/24` — Availability Zone A
- `10.0.22.0/24` — Availability Zone B

RDS MySQL is placed in the DB subnet group using these private subnets.

## 4. Why the tiers are separated

If an internet-facing component is compromised, the attacker should not automatically gain direct network access to the database.

The intended path is:

```text
Internet
   ↓
WAF
   ↓
ALB
   ↓
Application Security Group
   ↓
Database Security Group
   ↓
RDS
```

This is a core defense-in-depth pattern: exposure is concentrated at the perimeter while internal tiers remain restricted.

## 5. Internet Gateway vs NAT Gateway

### Internet Gateway

The Internet Gateway provides internet connectivity for resources in public subnets.

### NAT Gateway

A NAT Gateway allows private-subnet resources to initiate outbound internet connections without making those resources directly reachable from the internet.

This project uses one NAT Gateway per Availability Zone.

```text
Private EC2
    |
    v
NAT Gateway
    |
    v
Internet Gateway
    |
    v
Internet
```

The connection is outbound from the private workload; the private EC2 instances are not assigned public IP addresses.

## 6. Application tier

The EC2 application tier uses a Launch Template and Auto Scaling Group.

The current deployment creates two application instances, one in each private application subnet.

The instances install NGINX using user data and expose the application through the ALB target group.

## 7. Load balancing

The Application Load Balancer is internet-facing and deployed across the public subnets.

The listener forwards requests to the private application target group.

This gives users a stable public endpoint without exposing the EC2 instances directly.

## 8. AWS WAF

AWS WAF is associated with the ALB.

It provides a web-layer control point before requests reach the application tier. The Terraform configuration includes managed-rule protection and rate-based protection.

## 9. RDS MySQL

The database is deliberately isolated in private database subnets.

The deployment was verified with:

```text
PubliclyAccessible = False
Status              = available
Engine              = mysql
```

The database security group should permit MySQL traffic only from the application security group rather than from the public internet.

## 10. IAM and Systems Manager

EC2 uses an IAM instance profile with Systems Manager permissions.

This allows administrative access through AWS Systems Manager instead of requiring an SSH port exposed to the internet.

That is a better operational model for private instances.

## 11. CloudTrail

CloudTrail records AWS API activity.

The project sends CloudTrail logs to an S3 bucket named `ankit-secure-vpc-cloudtrail-logs`.

The trail was verified as logging and configured as a multi-region trail with log-file validation enabled.

## 12. VPC Flow Logs

VPC Flow Logs capture network traffic metadata from the VPC.

The project sends the logs to:

```text
/aws/vpc/ankit-secure-vpc/flow-logs
```

The configured CloudWatch retention is 7 days.

Flow Logs are useful when troubleshooting connectivity, investigating unexpected traffic, and validating network behavior.

## 13. Terraform file responsibilities

| File | Responsibility |
|---|---|
| `provider.tf` | AWS provider configuration |
| `variables.tf` | Input variables |
| `vpc.tf` | VPC, subnets, route tables and associations |
| `nat.tf` | Elastic IPs and NAT Gateways |
| `security.tf` | Security groups |
| `iam.tf` | IAM roles, policies and instance profile |
| `ec2.tf` | EC2/Launch Template configuration |
| `asg.tf` | Auto Scaling Group |
| `alb.tf` | ALB, target group and listener |
| `rds.tf` | RDS subnet group and MySQL instance |
| `waf.tf` | WAF Web ACL and ALB association |
| `cloudtrail.tf` | CloudTrail and S3 logging |
| `flow-logs.tf` | VPC Flow Logs and CloudWatch |

## 14. Deployment workflow on Windows

```powershell
# Clone
git clone https://github.com/ankityadav1asia/aws-secure-vpc.git
cd aws-secure-vpc

# Configure AWS
aws configure
aws sts get-caller-identity

# Terraform
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

## 15. Deployment workflow on Linux/macOS

The Terraform commands are the same. Only shell-specific commands differ.

```bash
git clone https://github.com/ankityadav1asia/aws-secure-vpc.git
cd aws-secure-vpc

aws configure
aws sts get-caller-identity

cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

For secrets, keep `terraform.tfvars` local and never commit it.

## 16. Verification checklist

After deployment, verify:

- VPC exists
- Two public subnets exist
- Two private application subnets exist
- Two private DB subnets exist
- NAT Gateways are available
- Two EC2 application instances are running
- EC2 instances have no public IPs
- ALB is reachable
- ALB target health is healthy
- RDS status is `available`
- RDS `PubliclyAccessible` is `False`
- WAF is associated with the ALB
- CloudTrail status is logging
- VPC Flow Logs are `ACTIVE`
- CloudWatch flow-log retention is 7 days

## 17. Teardown

For a lab environment, remove the infrastructure when finished:

```bash
cd terraform
terraform destroy
```

This is especially important because NAT Gateways, RDS, ALB, WAF and other AWS services can generate charges while provisioned.

## 18. Production improvements

This lab is intentionally focused and reproducible. A production evolution could add:

- HTTPS with ACM and a real domain
- Route 53 DNS
- Secrets Manager for database credentials
- KMS encryption policies
- S3 lifecycle policies
- CloudWatch alarms and dashboards
- VPC endpoints for AWS services
- AWS Config / Security Hub
- CI/CD with GitHub Actions
- Remote Terraform state in S3 with state locking
- Separate Terraform environments/workspaces
- Private RDS credentials managed by Secrets Manager
