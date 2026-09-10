# Troubleshooting

## `InvalidClientTokenId` from AWS CLI

The AWS CLI is using invalid or expired credentials.

```bash
aws configure
aws sts get-caller-identity
```

Never paste secret keys into the repository or chat.

## Terraform provider initialization fails

Run:

```bash
terraform init
terraform validate
```

If provider versions were changed, re-run `terraform init`.

## RDS reports `Invalid master user name`

Use an RDS-compatible administrator username such as `dbadmin` and re-run `terraform plan` before applying.

## CloudTrail reports `InsufficientS3BucketPolicyException`

CloudTrail requires an S3 bucket policy that allows `s3:GetBucketAcl` and `s3:PutObject` to the expected `AWSLogs/<account-id>/` path. A first create attempt can fail while a newly created policy is propagating; retrying the Terraform apply after the policy exists can succeed.

## ALB times out

Check:

1. The browser is using `http://` while only the HTTP listener exists.
2. The target group reports healthy EC2 targets.
3. The ALB security group permits TCP/80.
4. The application security group allows TCP/80 from the ALB security group.

Check target health:

```powershell
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names ankit-secure-vpc-app-tg --query "TargetGroups[0].TargetGroupArn" --output text) --query "TargetHealthDescriptions[].[Target.Id,TargetHealth.State,TargetHealth.Reason]" --output table
```

## EC2 instances have no public IP

This is expected. The application tier is private. Outbound internet access is provided through NAT Gateways.

## RDS is not publicly accessible

This is expected and required by the design. Verify:

```powershell
aws rds describe-db-instances --db-instance-identifier ankit-secure-vpc-mysql --query "DBInstances[0].PubliclyAccessible" --output text
```

Expected output:

```text
False
```
