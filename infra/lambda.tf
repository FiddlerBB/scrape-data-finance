resource "aws_lambda_function" "gold_scrape_lambda" {
  function_name = "gold_scrape_lambda"
  role = aws_iam_role.gold_scrape_role.arn
  package_type = "Image"
  image_uri = var.IMAGE_URI
  timeout = 300
  memory_size = 512
}