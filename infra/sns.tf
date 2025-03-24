resource "aws_sns_topic" "gold_scrape_topic" {
  name = "gold-scrape-topic"
}

resource "aws_sns_topic_subscription" "gold_scrape_subscription" {
  topic_arn = aws_sns_topic.gold_scrape_topic.arn
  protocol  = "email"
  endpoint  = var.EMAIL_SUB
}
