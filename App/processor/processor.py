import boto3
import json
import os
from datetime import datetime
import time

# ENV Variablen holen
aws_region = os.getenv("AWS_REGION", "eu-central-1")
queue_url = os.getenv("SQS_QUEUE_URL")
dynamo_table = os.getenv("DYNAMODB_TABLE_NAME")

# AWS Clients
sqs = boto3.client("sqs", region_name=aws_region)
dynamodb = boto3.client("dynamodb", region_name=aws_region)


def process_event(data):
    # Region basierend auf Lat/Lon generieren
    region_key = f"{data['lat']}_{data['lon']}"

    # In DynamoDB speichern
    dynamodb.put_item(
        TableName=dynamo_table,
        Item={
            "region": {"S": region_key},
            "timestamp": {"S": datetime.utcnow().isoformat()},
            "payload": {"S": json.dumps(data)}
        }
    )

    print("Saved event to DynamoDB:", region_key)


def main_loop():
    print("Processor SQS loop started...")

    while True:
        response = sqs.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=10
        )

        messages = response.get("Messages", [])

        if not messages:
            print("⏳ No messages received, waiting...")
            continue

        for message in messages:
            body = json.loads(message["Body"])
            process_event(body)

            sqs.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=message["ReceiptHandle"]
            )

            print("🗑️ Deleted message from SQS")

        time.sleep(1)


if __name__ == "__main__":
    main_loop()