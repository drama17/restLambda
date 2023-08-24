data "aws_route53_zone" "restlambda" {
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_api_gateway_domain_name" "lambda_domain_name" {
  domain_name     = "api.${var.domain_name}" # Should be moved to vars or taken from resource
  certificate_arn = module.acm-lambda.acm_certificate_arn
}

resource "aws_api_gateway_base_path_mapping" "lambda_mapping" {
  domain_name = aws_api_gateway_domain_name.lambda_domain_name.domain_name
  stage_name  = aws_api_gateway_stage.test_stage.stage_name
  api_id      = aws_api_gateway_rest_api.lambda_api.id

  depends_on = [aws_api_gateway_stage.test_stage]
}

resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.lambda_domain_name.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.restlambda.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.lambda_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.lambda_domain_name.cloudfront_zone_id
  }
}

module "acm-lambda" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v3.0"
  providers = {
    aws = aws.useast1
  }
  domain_name = "api.${var.domain_name}"
  zone_id     = data.aws_route53_zone.restlambda.zone_id

  subject_alternative_names = [
    "www.${var.domain_name}",
    "*.${var.domain_name}",
  ]

  tags = {
    Name = var.domain_name
  }
}
