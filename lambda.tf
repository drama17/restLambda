provider "aws" {
  region = "eu-west-1"
}

resource "aws_lambda_function" "rest_lambda_function" {
  filename      = "files/restLambda.zip" # Make sure the ZIP file contains your Python code and dependencies
  function_name = "VoLambdaFunction"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "restLambda.lambda_handler"
  runtime       = "python3.8"
}
