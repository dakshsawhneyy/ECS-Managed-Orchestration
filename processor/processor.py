import boto3
import requests
import json
import os
import time
import uuid

# env's
SQS_URL = os.getenv("SQS_URL")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE")

sqs = boto3.client('sqs', region_name='ap-south-1')
dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
table = dynamodb.Table(DYNAMODB_TABLE)


# Read logs from SQS
def read_from_sqs():
    try:
        response = sqs.receive_message(
            QueueUrl=SQS_URL,
            MaxNumberOfMessages=10,         # fetch up to 10 at once
            WaitTimeSeconds=10,             # enable long polling
            VisibilityTimeout=30            # gives time to process before retry
        )
        print('Response: ', response)       # Debugging
        messages = response.get('Messages', [])
        print('Messages: ', messages)
        return messages
        time.sleep(5)   # sleep for some time
    except Exception as e:
        print(f"Error receiving messages: {str(e)}")
        return []
    
    
# Function to write logs in DynamoDB
def write_logs_to_dynamodb(log_data):
    try:
        log_data['id'] = str(uuid.uuid4())
        table.put_item(Item=log_data)
    except Exception as e:
        print(f"Error inserting into DynamoDB: {str(e)}")
        
# Delete messages from SQS, once they been inserted into DynamoDB
def delete_msgs_from_sqs(reciept_handle):
    try:
        sqs.delete_message(QueueUrl=SQS_URL, ReceiptHandle=receipt_handle)
        print("Message deleted from SQS")
    except Exception as e:
        print(f"Error deleting messages from SQS: {str(e)}")
        

# Main Function
def main():
    print('Processor Started')
    while True:
        messages = read_from_sqs()
        if not messages:
            print("No messages in SQS, waiting...")
            time.sleep(5)
            continue
        for msg in messages:
            try:
                log_data = json.loads(msg['Body'])
                write_logs_to_dynamodb(log_data)
                delete_msgs_from_sqs(msg['ReceiptHandle'])
            except Exception as e:
                print(f"Error processing message: {str(e)}")

if __name__ == "__main__":
    main()