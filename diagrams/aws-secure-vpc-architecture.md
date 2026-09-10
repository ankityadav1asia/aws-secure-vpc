# AWS Secure VPC — Architecture Diagram

![Architecture diagram](./aws-secure-vpc-architecture.png)

## Logical flow

```text
Internet
   |
   v
AWS WAF
   |
   v
Public Application Load Balancer
   |
   +---------------------+
   |                     |
   v                     v
Private App EC2      Private App EC2
   |                     |
   +----------+----------+
              |
              v
        Private RDS MySQL

Private App EC2
   |
   v
NAT Gateway (per AZ)
   |
   v
Internet Gateway
   |
   v
Internet
```

## Observability path

```text
AWS API activity -> CloudTrail -> S3
VPC network traffic -> VPC Flow Logs -> CloudWatch Logs
```

## Security boundaries

- WAF is the web-layer perimeter in front of the ALB.
- The ALB is internet-facing; application EC2 instances are private.
- The application security group accepts application traffic from the ALB security group.
- The database security group accepts MySQL traffic from the application security group.
- RDS is configured as not publicly accessible.
- EC2 instances are managed through IAM + Systems Manager rather than public SSH.
