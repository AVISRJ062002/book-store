# Centralized access logs make the low-cost HTTP API easier to operate in production.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/apigateway/${var.name_prefix}-http-api"
  retention_in_days = 14

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-http-api"
  })
}

resource "aws_apigatewayv2_api" "this" {
  name          = "${var.name_prefix}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers  = ["authorization", "content-type", "x-requested-with"]
    allow_methods  = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_origins  = var.cors_allowed_origins
    expose_headers = ["date", "x-request-id"]
    max_age        = 300
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-http-api"
  })
}

# Lambda route keeps the baseline API fully serverless and cost-efficient.
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "lambda" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = var.lambda_route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "lambda_additional" {
  for_each = toset(var.additional_lambda_route_keys)

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "allow_http_api" {
  statement_id  = "AllowHttpApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

# VPC Link is created only when the optional Fargate route is enabled.
resource "aws_apigatewayv2_vpc_link" "this" {
  count = var.enable_fargate_route ? 1 : 0

  name               = "${var.name_prefix}-vpclink"
  security_group_ids = var.vpc_link_security_group_ids
  subnet_ids         = var.vpc_link_subnet_ids

  lifecycle {
    precondition {
      condition = !var.enable_fargate_route || (
        length(var.vpc_link_subnet_ids) > 0 &&
        length(var.vpc_link_security_group_ids) > 0 &&
        var.fargate_listener_arn != ""
      )
      error_message = "Provide VPC link subnets, security groups, and an ALB listener ARN when enable_fargate_route is true."
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpclink"
  })
}

resource "aws_apigatewayv2_integration" "fargate" {
  count = var.enable_fargate_route ? 1 : 0

  api_id               = aws_apigatewayv2_api.this.id
  integration_type     = "HTTP_PROXY"
  integration_method   = "ANY"
  integration_uri      = var.fargate_listener_arn
  connection_type      = "VPC_LINK"
  connection_id        = aws_apigatewayv2_vpc_link.this[0].id
  timeout_milliseconds = 30000
}

resource "aws_apigatewayv2_route" "fargate" {
  count = var.enable_fargate_route ? 1 : 0

  api_id    = aws_apigatewayv2_api.this.id
  route_key = var.fargate_route_key
  target    = "integrations/${aws_apigatewayv2_integration.fargate[0].id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  default_route_settings {
    throttling_burst_limit = 500
    throttling_rate_limit  = 1000
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-stage"
  })
}
