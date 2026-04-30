resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project}-api-${var.owner}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "alb" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = "http://${aws_lb.main.dns_name}"
  integration_method = "ANY"
}

# Two routes needed to cover all traffic:
# "ANY /" catches requests to the root URL
# "ANY /{proxy+}" catches anything with a path (/health, /api/v1, etc.)
resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}

# $default stage with auto_deploy — changes to the API deploy automatically.
# No manual deployments needed during development.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}
