variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.nano"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "migration-lab"
}
variable "ami_id" {
  description = "EC2 AWS Image type"
  type        = string
  default     = "ami-08e7e754b2c895da7"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
  default     = "migration_key"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
