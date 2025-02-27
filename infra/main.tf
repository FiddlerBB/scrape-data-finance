terraform {
    required_version = ">= 1.2.0"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.16"
        }
    }
}

# Configure AWS provider
provider "aws" {
    region = var.aws_region
}

resource "aws_sns" "gold_scrape_topic" {
    name = "gold-scrape-topic"
}

resource "aws_sns_topic_subscription" "gold_scrape_subscription" {
    topic_arn = aws_sns_topic.gold_scrape_topic.arn
    protocol = "email"
    endpoint = var.EMAIL_SUB

}