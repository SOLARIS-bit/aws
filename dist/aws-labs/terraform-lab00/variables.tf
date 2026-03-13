variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "EC2 instance name"
  type        = string
  default     = "lab00-ec2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS key pair name and generated pem filename prefix"
  type        = string
  default     = "lab00-key"
}

variable "security_group_name" {
  description = "Security group name for SSH"
  type        = string
  default     = "lab00-ssh-sg"
}

variable "instance_profile_name" {
  description = "Existing IAM instance profile name in AWS Academy"
  type        = string
  default     = "LabInstanceProfile"
}

variable "ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}
