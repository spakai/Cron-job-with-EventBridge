import boto3
import os
import logging
from datetime import datetime, timezone

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger()

def lambda_handler(event, context):
    logger.info("Starting the Lambda function")
    
    # Check environment variable
    table_name = os.environ.get("scheduled_tasks")
    if not table_name:
        logger.error("Environment variable 'scheduled_tasks' is not set.")
        return
    
    logger.debug(f"Using table: {table_name}")
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)

    now = int(datetime.now(timezone.utc).timestamp())
    logger.info("Scanning for overdue tasks at %d", now)

    try:
        response = table.scan(
            FilterExpression="scheduled_time <= :current_time",
            ExpressionAttributeValues={":current_time": now}
        )
        tasks = response.get("Items", [])
        logger.info("Found %d overdue tasks", len(tasks))
    except Exception as e:
        logger.error("Error scanning table: %s", e)
        return

    for task in tasks:
        try:
            logger.info("Processing task: %s", task["task_id"])
            table.update_item(
                Key={"task_id": task["task_id"]},
                UpdateExpression="SET #status = :status",
                ExpressionAttributeNames={"#status": "status"},
                ExpressionAttributeValues={":status": "COMPLETED"}
            )
            logger.info("Task %s marked as COMPLETED", task["task_id"])
        except Exception as e:
            logger.error("Error updating task %s: %s", task["task_id"], e)

if __name__ == "__main__":
    # Simulate event and context for testing
    test_event = {}
    test_context = {}
    lambda_handler(test_event, test_context)
