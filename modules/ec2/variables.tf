variable "name" {
description = "EC2 instance name"
type        = string
}

variable "ami_id" {
description = "AMI ID"
type        = string
}

variable "instance_type" {
description = "EC2 instance type"
type        = string
}

variable "subnet_id" {
description = "Subnet ID"
type        = string
}

variable "security_group_ids" {
description = "Security group IDs"
type        = list(string)
}

variable "key_name" {
description = "EC2 key pair name"
type        = string
}

variable "role" {
description = "Instance role"
type        = string
}

variable "user_data" {
description = "User data script to run on instance launch"
type        = string
default     = null
}
