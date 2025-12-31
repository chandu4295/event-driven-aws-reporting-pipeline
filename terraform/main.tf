terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 buckets for data pipeline
resource "aws_s3_bucket" "raw_data" {
  bucket = var.raw_data_bucket_name
  tags = {
    Name        = "Raw Events Data"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "athena_output" {
  bucket = var.athena_output_bucket_name
  tags = {
    Name        = "Athena Query Output"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "reports" {
  bucket = var.reports_bucket_name
  tags = {
    Name        = "Daily Reports"
    Environment = var.environment
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.environment}-report-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${var.environment}-lambda-policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*",
          aws_s3_bucket.athena_output.arn,
          "${aws_s3_bucket.athena_output.arn}/*",
          aws_s3_bucket.reports.arn,
          "${aws_s3_bucket.reports.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "glue:GetDatabase",
          "glue:GetTable"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda.zip"
}

resource "aws_lambda_function" "daily_report" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.environment}-daily-summary-report"
  role             = aws_iam_role.lambda_role.arn
  handler          = "report_lambda.handler"
  runtime          = "python3.11"
  timeout          = 120
  memory_size      = 512
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ATHENA_DB      = var.athena_database
      ATHENA_TABLE   = var.athena_table
      OUTPUT_BUCKET  = aws_s3_bucket.athena_output.bucket
      REPORT_BUCKET  = aws_s3_bucket.reports.bucket
      SES_FROM       = var.ses_from_email
      SES_TO         = var.ses_to_email
    }
  }

  tags = {
    Environment = var.environment
  }
}

# EventBridge rule for daily schedule
resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name                = "${var.environment}-daily-summary-schedule"
  description         = "Trigger daily summary report generation"
  schedule_expression = var.schedule_expression

  tags = {
    Environment = var.environment
  }
}

# EventBridge target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_schedule.name
  target_id = "DailySummaryLambda"
  arn       = aws_lambda_function.daily_report.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daily_report.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule.arn
}
