import boto3
import datetime
import os
import json

s3 = boto3.client("s3")
athena = boto3.client("athena")
ses = boto3.client("ses")

ATHENA_DB = os.getenv("ATHENA_DB", "events_db")
ATHENA_TABLE = os.getenv("ATHENA_TABLE", "events_raw")
OUTPUT_BUCKET = os.getenv("OUTPUT_BUCKET")
REPORT_BUCKET = os.getenv("REPORT_BUCKET")
SES_FROM = os.getenv("SES_FROM")
SES_TO = os.getenv("SES_TO")

def handler(event, context):
    """
    Lambda handler for daily summary report generation
    """
    today = datetime.date.today()
    date_str = today.strftime("%Y-%m-%d")
    
    try:
        # Build Athena query for daily summary
        query = f"""
        SELECT
          '{date_str}' AS report_date,
          COUNT(*) AS total_events,
          COUNT(DISTINCT event_type) AS unique_event_types
        FROM {ATHENA_DB}.{ATHENA_TABLE}
        WHERE event_date = date('{date_str}')
        """
        
        # Execute Athena query
        response = athena.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": ATHENA_DB},
            ResultConfiguration={
                "OutputLocation": f"s3://{OUTPUT_BUCKET}/athena-results/"
            },
        )
        
        qid = response["QueryExecutionId"]
        
        # Wait for query to complete
        waiter = athena.get_waiter("query_succeeded")
        waiter.wait(QueryExecutionId=qid)
        
        # Get query results
        result = athena.get_query_results(QueryExecutionId=qid)
        rows = result["ResultSet"]["Rows"]
        
        # Extract data from results
        if len(rows) > 1:
            data = rows[1]["Data"]
            report_date = data[0]["VarCharValue"] if "VarCharValue" in data[0] else date_str
            event_count = data[1]["VarCharValue"] if len(data) > 1 and "VarCharValue" in data[1] else "0"
            unique_types = data[2]["VarCharValue"] if len(data) > 2 and "VarCharValue" in data[2] else "0"
        else:
            report_date = date_str
            event_count = "0"
            unique_types = "0"
        
        # Create report content
        report_text = f"""
=== DAILY SUMMARY REPORT ===
Report Date: {report_date}
Total Events: {event_count}
Unique Event Types: {unique_types}

Generated at: {datetime.datetime.now().isoformat()}
"""
        
        # Store report in S3
        key = f"reports/daily_report_{date_str}.txt"
        s3.put_object(
            Bucket=REPORT_BUCKET,
            Key=key,
            Body=report_text.encode("utf-8"),
            ContentType="text/plain"
        )
        
        # Send email notification (if configured)
        if SES_FROM and SES_TO:
            try:
                ses.send_email(
                    Source=SES_FROM,
                    Destination={"ToAddresses": [SES_TO]},
                    Message={
                        "Subject": {"Data": f"Daily Summary Report - {report_date}"},
                        "Body": {"Text": {"Data": report_text}},
                    },
                )
            except Exception as e:
                print(f"Warning: Failed to send email: {str(e)}")
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Report generated successfully",
                "report_key": key,
                "report_date": report_date,
                "event_count": event_count
            })
        }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e)
            })
        }
