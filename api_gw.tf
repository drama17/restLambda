resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "lambda-api"
  description = "Lambda API Gateway"
}

resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "increase"
}

resource "aws_api_gateway_method" "lambda_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.lambda_resource.id
  http_method             = aws_api_gateway_method.lambda_method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.rest_lambda_function.invoke_arn
}

resource "aws_api_gateway_method_response" "lambda_method_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.lambda_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "lambda_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.lambda_method.http_method
  status_code = aws_api_gateway_method_response.lambda_method_response.status_code

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_usage_plan" "lambda_usage_plan" {
  name        = "lambda-usage-plan"
  description = "Lambda Usage Plan"
  api_stages {
    api_id = aws_api_gateway_rest_api.lambda_api.id
    stage  = aws_api_gateway_stage.test_stage.stage_name
  }

  quota_settings {
    limit  = 200
    offset = 20
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }
}

resource "aws_api_gateway_api_key" "lambda_api_key" {
  name = "lambda-api-key"
}

resource "aws_api_gateway_usage_plan_key" "lambda_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.lambda_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.lambda_usage_plan.id
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/api-gateway/lambda-api"
}

resource "aws_api_gateway_deployment" "lambda_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = "test_deployment"

  depends_on = [aws_api_gateway_integration.lambda_integration]
}

resource "aws_api_gateway_stage" "test_stage" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  stage_name    = "dev_stage"
  deployment_id = aws_api_gateway_deployment.lambda_deployment.id

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.lambda_log_group.arn
    format = jsonencode({
      requestId          = "$context.requestId",
      requestTime        = "$context.requestTime",
      httpMethod         = "$context.httpMethod",
      resourcePath       = "$context.resourcePath",
      status             = "$context.status",
      protocol           = "$context.protocol",
      responseLength     = "$context.responseLength",
      integrationLatency = "$context.integrationLatency",
      requestLatency     = "$context.requestLatency",
    })
  }
}

# resource "aws_route53_record" "lambda" {
#   name    = aws_api_gateway_domain_name.lambda_domain_name.domain_name
#   type    = "A"
#   zone_id = aws_route53_zone.example.id # Need to be created
#
#   alias {
#     evaluate_target_health = true
#     name                   = aws_api_gateway_domain_name.lambda_domain_name.cloudfront_domain_name
#     zone_id                = aws_api_gateway_domain_name.lambda_domain_name.cloudfront_zone_id
#   }
# }

# data "external" "acm_certificate" {
#   program = ["sh", "-c", "aws acm request-certificate --domain-name api.restlambda.com --validation-method DNS --region us-east-1 --output text --query CertificateArn"]
# }


# ACM Certificate for Custom Domain
# resource "aws_acm_certificate" "lambda_certificate" {
#   domain_name       = "api.restlambda.com"
#   validation_method = "DNS"
#   arn               = data.external.acm_certificate.result
#
#   tags = {
#     Name = "lambda-certificate"
#   }
# }

# resource "aws_api_gateway_domain_name" "lambda_domain_name" {
#   domain_name     = "api.restlambda.com" # Should be moved to vars or taken from resource
#   certificate_arn = "arn:aws:acm:us-east-1:121255988189:certificate/734297e6-21d6-43f1-b8d2-9c911495994b"
# }

# resource "aws_api_gateway_base_path_mapping" "lambda_mapping" {
#   domain_name = aws_api_gateway_domain_name.lambda_domain_name.domain_name
#   stage_name  = aws_api_gateway_stage.test_stage.stage_name
#   api_id      = aws_api_gateway_rest_api.lambda_api.id
#
#   depends_on = [aws_api_gateway_stage.test_stage]
# }