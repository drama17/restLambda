resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn

  depends_on = [
    aws_lambda_function.rest_lambda_function
  ]
}

resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "lambda-api"
  description = "Lambda API Gateway"

  depends_on = [
    aws_lambda_function.rest_lambda_function
  ]

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
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.lambda_resource.id
  http_method             = aws_api_gateway_method.lambda_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.rest_lambda_function.invoke_arn

  depends_on = [
    aws_lambda_function.rest_lambda_function
  ]

}

resource "aws_api_gateway_method_response" "lambda_method_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.lambda_method.http_method
  status_code = "200"

  depends_on = [
    aws_lambda_function.rest_lambda_function
  ]

}

resource "aws_api_gateway_integration_response" "lambda_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.lambda_method.http_method
  status_code = aws_api_gateway_method_response.lambda_method_response.status_code

  response_templates = {
    "application/json" = ""
  }

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_account.demo
  ]
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
    offset = 0
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
  stage_name  = "dev-deployment"

  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_account.demo
  ]
}

resource "aws_api_gateway_stage" "test_stage" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  stage_name    = "dev-stage"
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
