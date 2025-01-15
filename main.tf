# Create a DynamoDB table to store the scheduled tasks with attributes for task ID and scheduled time
resource "aws_dynamodb_table" "cron_job" {
  name         = "scheduled_tasks"
  billing_mode = "PAY_PER_REQUEST"

  # Define attributes
  attribute {
    name = "task_id" # Primary key
    type = "S"       # String
  }

  attribute {
    name = "scheduled_time" # GSI key
    type = "N"              # Number
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Primary key definition
  hash_key = "task_id"

  # Global secondary index
  global_secondary_index {
    name            = "overdue_tasks"
    hash_key        = "scheduled_time"
    projection_type = "ALL"
  }

  # Global secondary index for 'status'
  global_secondary_index {
    name            = "status_index"
    hash_key        = "status"
    projection_type = "ALL"
  }
}

# Grant the necessary permissions to the Lambda function to read/write to DynamoDB

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda IAM Policy
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_dynamodb_policy"
  description = "Policy for Lambda to interact with DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ],
        Resource = [
          aws_dynamodb_table.cron_job.arn,                         # Table ARN
          "${aws_dynamodb_table.cron_job.arn}/index/overdue_tasks" # GSI ARN
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "task_processor" {
  function_name = "process_overdue_tasks"
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  filename         = "./lambda.zip" # Path to your packaged Lambda function
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      scheduled_tasks = "aws_dynamodb_table.cron_job.arn"
    }
  }
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "scheduled_tasks" {
  name                = "run-every-x-minutes"
  schedule_expression = "rate(5 minutes)" # Change as needed
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.scheduled_tasks.name
  target_id = "LambdaTarget"
  arn       = aws_lambda_function.task_processor.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.task_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_tasks.arn
}
