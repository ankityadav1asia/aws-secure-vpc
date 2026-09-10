variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ankit-secure-vpc"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "RDS database administrator username"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "db_password" {
  description = "RDS database administrator password"
  type        = string
  sensitive   = true
}