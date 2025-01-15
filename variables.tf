variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
  default     = "my_lambda_function"
}

variable "eventbridge_rule_name" {
  description = "The name of the EventBridge rule"
  type        = string
  default     = "my_eventbridge_rule"
}

variable "schedule_expression" {
  description = "The schedule expression for the cron job"
  type        = string
  default     = "rate(5 minutes)"
}