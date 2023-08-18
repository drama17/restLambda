provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "vo_lambda_bucket" {
  bucket = "vo-lambda-bucket"
}

resource "aws_s3_bucket_acl" "vo_lambda_bucket_acl" {
  bucket     = aws_s3_bucket.vo_lambda_bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.vo_lambda_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_lambda_function" "vo_lambda_function" {
  filename      = "files/lambdaS3.zip" # Make sure the ZIP file contains your Python code and dependencies
  function_name = "VoLambdaFunction"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambdaS3.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role" # Replace with your desired IAM role name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda-s3-policy"
  description = "IAM policy for granting access to S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.vo_lambda_bucket.arn}/*"
      },
      {
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = aws_s3_bucket.vo_lambda_bucket.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
  role       = aws_iam_role.lambda_exec.name
}
