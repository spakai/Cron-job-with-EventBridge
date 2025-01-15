output "eventbridge_rule_arn" {
  value = aws_cloudwatch_event_rule.scheduled_tasks.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.task_processor.arn
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.cron_job.arn
}