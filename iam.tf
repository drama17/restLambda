data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Lambda Function
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-policy"
  description = "Policy for Lambda Function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = "lambda:InvokeFunction",
      Effect   = "Allow",
      Resource = "*"
      }, {
      Action   = "logs:CreateLogGroup",
      Effect   = "Allow",
      Resource = "*"
      }, {
      Action   = "logs:CreateLogStream",
      Effect   = "Allow",
      Resource = "*"
      }, {
      Action   = "logs:PutLogEvents",
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}


# Attach Lambda Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec_role.name
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "api_gateway_logging" {
  name        = "api-gateway-logging"
  path        = "/"
  description = "IAM policy for logging from the api gateway"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "gateway_logs" {
  role       = aws_iam_role.cloudwatch.id
  policy_arn = aws_iam_policy.api_gateway_logging.arn
}

resource "aws_iam_policy" "api_gateway_lambda" {
  name        = "api-gateway-lambda"
  path        = "/"
  description = "IAM policy for invoke lambda from the api gateway"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "lambda:InvokeFunction",
        "Resource" : aws_api_gateway_rest_api.lambda_api.arn,
        "Effect" : "Allow"
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "gateway_lambda" {
  role       = aws_iam_role.cloudwatch.id
  policy_arn = aws_iam_policy.api_gateway_lambda.arn
}

########

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["execute-api:Invoke"]
    resources = [
      aws_api_gateway_rest_api.lambda_api.execution_arn,
      "arn:aws:execute-api:eu-west-1:${local.account_id}:${aws_api_gateway_rest_api.lambda_api.id}/*/*/*",
      "arn:aws:execute-api:eu-west-1:${local.account_id}:${aws_api_gateway_rest_api.lambda_api.id}/${aws_api_gateway_stage.test_stage.stage_name}/*/*",
      "arn:aws:execute-api:eu-west-1:${local.account_id}:${aws_api_gateway_rest_api.lambda_api.id}/${aws_api_gateway_stage.test_stage.stage_name}/GET/${aws_api_gateway_resource.lambda_resource.path_part}/*",
      "arn:aws:execute-api:eu-west-1:${local.account_id}:${aws_api_gateway_rest_api.lambda_api.id}/dev-deployment/GET/${aws_api_gateway_resource.lambda_resource.path_part}/*",
      aws_api_gateway_deployment.lambda_deployment.execution_arn
    ]

    # condition {
    #   test     = "IpAddress"
    #   variable = "aws:SourceIp"
    #   values   = ["123.123.123.123/32"]
    # }
  }
}
resource "aws_api_gateway_rest_api_policy" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  policy      = data.aws_iam_policy_document.lambda.json
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rest_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*"
}
