variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "raw_data_bucket_name" {
  description = "S3 bucket for raw event data"
  type        = string
  default     = "event-pipeline-raw-data-${data.aws_caller_identity.current.account_id}"
}

variable "athena_output_bucket_name" {
  description = "S3 bucket for Athena query results"
  type        = string
  default     = "event-pipeline-athena-output-${data.aws_caller_identity.current.account_id}"
}

variable "reports_bucket_name" {
  description = "S3 bucket for daily reports"
  type        = string
  default     = "event-pipeline-reports-${data.aws_caller_identity.current.account_id}"
}

variable "athena_database" {
  description = "Athena database name"
  type        = string
  default     = "events_db"
}

variable "athena_table" {
  description = "Athena table name"
  type        = string
  default     = "events_raw"
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for daily report (UTC)"
  type        = string
  default     = "cron(0 18 * * ? *)"
}

variable "ses_from_email" {
  description = "SES verified sender email address"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ses_to_email" {
  description = "Recipient email address for daily reports"
  type        = string
  default     = ""
  sensitive   = true
}

data "aws_caller_identity" "current" {}
