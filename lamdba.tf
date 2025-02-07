# Create an IAM policy that grants the Lambda function permission to publish messages to the SNS topic
resource "aws_iam_policy" "sns_publish_policy" {
  name        = "LambdaSNSTopicPublishPolicy"
  description = "Allows Lambda function to publish messages to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.weather_notifications.arn
      }
    ]
  })
}

# The Lambda function must assume an IAM role with permissions to invoke SNS.
resource "aws_iam_role" "lambda_execution_role" {
  name_prefix = "lambda_execution_role_"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sns_publish" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

resource "aws_lambda_function" "nbagame_data_collector" {
  filename         = "${path.module}/nbagame.zip" # Path to the zipped file
  function_name    = "FetchWeatherData"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          =   "game.lambda_handler"     //"lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/nbagame.zip")

  environment {
    variables = {
      AWS_BUCKET_NAME = "workspacebucket-2023"
      NBA_API_KEY     = "fefc4ce7cde74550b6f4f47fe06570b1" # Replace with your actual API key
      SNS_TOPIC_ARN   = aws_sns_topic.weather_notifications.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "schedule_rule" {
  name                = "FetchWeatherDataRule"
  schedule_expression = "rate(1 hour)" # Adjust schedule as needed
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nbagame_data_collector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_rule.arn
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule_rule.name
  target_id = "FetchWeatherData"
  arn       = aws_lambda_function.nbagame_data_collector.arn
}


