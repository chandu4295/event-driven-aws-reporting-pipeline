# Event-Driven AWS Reporting Pipeline

A fully automated event-driven data processing pipeline on AWS with serverless architecture, Infrastructure as Code (Terraform), and continuous integration/deployment (GitHub Actions).

## Overview

This project demonstrates a production-ready serverless data pipeline that:
- **Captures** incoming data events
- **Processes** data using AWS Lambda and Athena
- **Generates** automated daily summary reports
- **Delivers** reports via email using SES
- **Scales** automatically with zero server management

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  S3 Events  │────→│ EventBridge  │────→│   Lambda     │
│  (Raw Data) │     │  (Scheduler) │     │ (Processor)  │
└─────────────┘     └──────────────┘     └──────────────┘
                                               │
                                               ↓
                                        ┌──────────────┐
                                        │   Athena     │
                                        │  (Query)     │
                                        └──────────────┘
                                               │
                ┌──────────────────────────────┤
                ↓                              ↓
          ┌─────────────┐              ┌──────────────┐
          │ S3 Reports  │              │    SES       │
          │  (Storage)  │              │   (Email)    │
          └─────────────┘              └──────────────┘
```

## Key Components

- **AWS S3**: Data lake for raw events and reports
- **AWS Lambda**: Serverless compute for ETL and report generation
- **AWS Athena**: SQL queries on S3 data (no database required)
- **AWS EventBridge**: Serverless event router and scheduler
- **AWS SES**: Email delivery for daily summaries
- **Terraform**: Infrastructure as Code for reproducible deployment
- **GitHub Actions**: CI/CD pipeline for automated testing and deployment

## Directory Structure

```
.
├── lambda/
│   └── report_lambda.py          # Daily report generator function
├── terraform/
│   ├── main.tf                   # AWS resources (S3, Lambda, EventBridge)
│   └── variables.tf              # Input variables with defaults
├── .github/workflows/
│   └── deploy.yml                # CI/CD pipeline configuration
├── .gitignore                    # Git ignore patterns
└── README.md                     # This file
```

## Getting Started

### Prerequisites

- AWS Account with permissions (S3, Lambda, Athena, SES, EventBridge, IAM)
- GitHub Account
- AWS CLI configured locally (optional, for testing)
- Terraform 1.5.0+
- Python 3.11+

### Configuration

#### 1. Set Up GitHub Secrets

Add AWS credentials to your GitHub repository:

1. Go to **Settings → Secrets and variables → Actions**
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS Access Key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key

**Important**: Use an IAM user with minimal permissions (S3, Lambda, Athena, SES, EventBridge, Glue)

#### 2. Configure Terraform Variables (Optional)

Create `terraform/terraform.tfvars` locally:

```hcl
aws_region = "ap-south-1"
environment = "prod"
ses_from_email = "sender@example.com"
ses_to_email = "recipient@example.com"
```

#### 3. Verify SES Email Addresses

If using SES for email:
1. Go to AWS SES Console
2. Verify both sender and recipient email addresses
3. Request production access (if in sandbox mode)

### Deployment

**Automatic (via GitHub Actions)**:
```bash
# Push changes to main branch
git push origin main
# GitHub Actions will automatically:
# 1. Check Terraform format
# 2. Plan infrastructure changes
# 3. Apply Terraform config
# 4. Deploy Lambda function
```

**Manual (Local)**:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Usage

### Trigger Daily Report Manually

```bash
aws lambda invoke \
  --function-name dev-daily-summary-report \
  --region ap-south-1 \
  response.json
```

### Upload Sample Data

```bash
echo '{"event_type": "purchase", "amount": 99.99}' > event.json
aws s3 cp event.json s3://event-pipeline-raw-data-123456789/events/
```

### Query Reports in S3

```bash
aws s3 ls s3://event-pipeline-reports-123456789/reports/
aws s3 cp s3://event-pipeline-reports-123456789/reports/daily_report_2025-01-01.txt .
```

## Monitoring

View Lambda logs:
```bash
aws logs tail /aws/lambda/dev-daily-summary-report --follow
```

Check EventBridge schedule:
```bash
aws events list-rules --name-prefix dev-daily
```

## Cost Optimization

- **S3**: ~$0.023/GB stored
- **Lambda**: ~$0.20 per 1M requests (first 1M free)
- **Athena**: ~$6.25 per TB scanned (first 1TB free)
- **SES**: ~$0.10 per 1000 emails

Estimated monthly cost for small-medium workloads: **<$5**

## Troubleshooting

**Lambda timeout**: Increase timeout in `terraform/main.tf` (default: 120s)

**Athena query fails**: Ensure table exists and S3 data format matches schema

**Emails not sent**: Verify SES sender/recipient emails are verified in AWS

**Terraform state lock**: Use `terraform force-unlock <lock-id>` if stuck

## Next Steps

- Integrate with AWS Glue Catalog for automatic schema detection
- Add SNS notifications for error handling
- Implement data validation with AWS Lambda Layers
- Set up CloudWatch dashboards for monitoring
- Create QuickSight reports from Athena data
- Add S3 lifecycle policies for cost optimization

## Contributing

Pull requests are welcome. Please follow:
1. Terraform format: `terraform fmt -recursive`
2. Python style: PEP 8 with Black formatter
3. Commit messages: descriptive and concise

## License

MIT License - See LICENSE file

## Resources

- [AWS Terraform Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
- [Athena SQL Reference](https://docs.aws.amazon.com/athena/latest/ug/querying-supported-statements.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Created by**: IIIT Naya Raipur ECE Student  
**Last Updated**: January 2025
