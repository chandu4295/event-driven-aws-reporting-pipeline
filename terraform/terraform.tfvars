# Terraform Variables for Event-Driven AWS Reporting Pipeline
# These values provide defaults for the infrastructure

aws_region = "ap-south-1"
environment = "dev"

# S3 bucket names - must be globally unique
# Using a unique prefix pattern - REPLACE WITH YOUR UNIQUE PREFIX
raw_data_bucket_name = "chandu4295-event-pipeline-raw"
athena_output_bucket_name = "chandu4295-event-pipeline-athena"
reports_bucket_name = "chandu4295-event-pipeline-reports"

# Athena configuration
athena_database = "events_db"
athena_table = "events_raw"

# EventBridge schedule - triggers daily at 6 PM UTC
schedule_expression = "cron(0 18 * * ? *)"

# SES email configuration (optional - set these to enable email notifications)
# ses_from_email = ""
# ses_to_email = ""
