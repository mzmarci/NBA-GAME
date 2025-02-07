

output "sns_topic_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.weather_notifications.arn
}

output "email_subscription_arn" {
  description = "The ARN of the email subscription"
  value       = aws_sns_topic_subscription.email_subscription.arn
}

output "sms_subscription_arn" {
  description = "The ARN of the SMS subscription"
  value       = aws_sns_topic_subscription.sms_subscription.arn
}
