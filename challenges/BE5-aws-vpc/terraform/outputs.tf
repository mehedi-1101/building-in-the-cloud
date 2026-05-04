output "public_ec2_public_ip" {
  description = "SSH target for public EC2. Use: ssh -A -i mh-key.pem ec2-user@<this-ip>"
  value       = aws_instance.public.public_ip
}

output "public_ec2_private_ip" {
  description = "Private IP of public EC2 (inside VPC)"
  value       = aws_instance.public.private_ip
}

output "private_ec2_private_ip" {
  description = "SSH target from inside public EC2. Use: ssh ec2-user@<this-ip>"
  value       = aws_instance.private.private_ip
}

output "nat_gateway_eip" {
  description = "What the internet sees when private EC2 makes outbound requests"
  value       = aws_eip.nat.public_ip
}

output "vpc2_ec2_private_ip" {
  description = "Ping target from private EC2. Use: ping -c 3 <this-ip>"
  value       = aws_instance.vpc2.private_ip
}

output "peering_connection_id" {
  description = "VPC peering connection ID"
  value       = aws_vpc_peering_connection.main.id
}

output "ssh_command" {
  description = "Full SSH command to connect to public EC2 with agent forwarding"
  value       = "ssh -A -i mh-key.pem ec2-user@${aws_instance.public.public_ip}"
}
