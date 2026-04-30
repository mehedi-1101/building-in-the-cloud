variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project prefix used in all resource names"
  type        = string
  default     = "be13"
}

variable "owner" {
  description = "Owner suffix used in all resource names (your name)"
  type        = string
  default     = "mehedi"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets — one per AZ, must not overlap"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "asg_desired" {
  description = "ASG desired number of instances"
  type        = number
  default     = 2
}

variable "asg_min" {
  description = "ASG minimum number of instances"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "ASG maximum number of instances"
  type        = number
  default     = 4
}

variable "health_check_grace_period" {
  description = "Seconds ASG waits before checking health on new instances"
  type        = number
  default     = 180
}
