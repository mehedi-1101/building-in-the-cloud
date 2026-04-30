output "api_endpoint" {
  description = "API Gateway invoke URL — primary test endpoint"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "alb_dns" {
  description = "ALB DNS name — use to test ALB directly, bypassing API Gateway"
  value       = "http://${aws_lb.main.dns_name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "instance_subnets" {
  description = "Public subnet IDs where EC2 instances are launched"
  value       = aws_subnet.public[*].id
}
