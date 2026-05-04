variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "az" {
  description = "Availability zone — both subnets go in the same AZ for this challenge"
  default     = "ap-south-1a"
}

variable "project" {
  description = "Project prefix used in resource names"
  default     = "be5"
}

variable "owner" {
  description = "Owner initials used in resource names"
  default     = "mh"
}

# ─── VPC 1 ────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "Main VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR — instances here get public IPs and route via IGW"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR — no public IPs, outbound via NAT GW only"
  default     = "10.0.2.0/24"
}

# ─── VPC 2 (peering) ──────────────────────────────────────────────────────────

variable "vpc2_cidr" {
  description = "Second VPC CIDR — must not overlap with vpc_cidr"
  default     = "10.1.0.0/16"
}

variable "vpc2_subnet_cidr" {
  description = "Second VPC subnet CIDR"
  default     = "10.1.1.0/24"
}

# ─── EC2 ──────────────────────────────────────────────────────────────────────

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of existing key pair in AWS — must already exist in the region"
  # CHANGE THIS if your key pair has a different name
  default = "mh-key"
}

# ─── DYNAMIC — must set before applying ───────────────────────────────────────

variable "my_ip" {
  description = <<EOT
Your laptop's public IP in CIDR notation (e.g. 203.x.x.x/32).
Used to restrict SSH access on the public EC2 to your machine only.
Find your current IP: curl https://checkip.amazonaws.com
EOT
  # No default — you must supply this. Add to terraform.tfvars:
  # my_ip = "103.195.205.20/32"
}
