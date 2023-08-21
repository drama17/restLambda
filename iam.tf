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

# IAM Policy for Lambda Function (including API Gateway invoke permission)
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-policy"
  description = "Policy for Lambda Function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = "lambda:InvokeFunction",
      Effect   = "Allow",
      Resource = aws_lambda_function.rest_lambda_function.arn
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
