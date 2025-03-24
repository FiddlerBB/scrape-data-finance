resource "aws_cloudwatch_event_rule" "gold_schedule" {
  name                = "gold-schedule"
  schedule_expression = "cron(0 3,7,9 * * ? *)"
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gold_scrape_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.gold_schedule.arn
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule       = aws_cloudwatch_event_rule.gold_schedule.name
  arn        = aws_lambda_function.gold_scrape_lambda.arn
  target_id  = "gold-schedule"
}