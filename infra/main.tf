terraform {
  required_version = ">= 1.9.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55.0"
    }
  }
}

# Configure AWS provider
provider "aws" {
  region = var.aws_region
}


terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-gold-scrape"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks" # Optional: For state locking
    encrypt        = true
  }
}


resource "aws_iam_role" "gold_scrape_role" {
  name               = "gold_scrape_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "gold_scrape_lambda_exec_role" {
  role       = aws_iam_role.gold_scrape_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


data "aws_iam_policy_document" "gold_scrape_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "AllowLambdaSendSnsNotification"
    resources = [
      "arn:aws:sns:${var.aws_region}:${var.AWS_ACCOUNT_ID}:gold-scrape-topic"
    ]
    actions = [
      "sns:Publish",
      "sns:GetTopicAttributs"
    ]
  }

  statement {
    sid = "AllowLambdaGetSsmParam"
    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.AWS_ACCOUNT_ID}:parameter/*"
    ]
    actions = [
      "ssm:GetParameter"
    ]
  }
}

resource "aws_iam_policy" "gold_scrape_policy" {
  name   = "gold_scrape_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.gold_scrape_policy.json
}

resource "aws_iam_role_policy_attachment" "gold_scrape_policy_attachment" {
  role       = aws_iam_role.gold_scrape_role.name
  policy_arn = aws_iam_policy.gold_scrape_policy.arn
}
