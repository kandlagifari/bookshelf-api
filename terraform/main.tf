terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }
  }
 backend "s3" {
   bucket = "kobokan-aer-terraform-remote-state-bucket"
   key    = "my_lambda/terraform.tfstate"
   region = "ap-southeast-3"
 }
}

provider "aws" {
  region = "ap-southeast-3"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "kobokan-aer-terraform-remote-state-bucket"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "hapi_lambda_role" {
  name               = "hapi-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "hapi_lambda" {
  filename      = "zips/lambda_function_${var.lambdasVersion}.zip"
  function_name = "hapi-lambda-function"
  role          = aws_iam_role.hapi_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  memory_size   = 1024
  timeout       = 300
}

resource "aws_lambda_function_url" "hapi_lambda_funtion_url" {
  function_name      = aws_lambda_function.hapi_lambda.id
  authorization_type = "NONE"
}

resource "aws_cloudwatch_log_group" "hapi_lambda_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.hapi_lambda.function_name}"
  retention_in_days = 1
}

data "aws_iam_policy_document" "hapi_lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.hapi_lambda_loggroup.arn,
      "${aws_cloudwatch_log_group.hapi_lambda_loggroup.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "hapi_lambda_role_policy" {
  policy = data.aws_iam_policy_document.hapi_lambda_policy.json
  role   = aws_iam_role.hapi_lambda_role.id
  name   = "hapi-lambda-policy"
}
