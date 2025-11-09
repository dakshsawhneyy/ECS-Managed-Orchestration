import boto3
import os
import requests     # for api calls [axios]
import time
import json

SERVICE_A_URL = os.getenv("SERVICE_A_URL")
QUEUE_URL = os.getenv("SQS_URL")

sqs = boto3.client('sqs', region_name='ap-south-1')

def fetch_logs():
    try:
        response = requests.get(f"{SERVICE_A_URL}/logs")
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Failed to fetch logs: {response.status_code}")
            return []
    except Exception as e:
        print(f"Error fetching logs: {str(e)}")
        return []
    
def sendToSQS(logs):
    for log in logs:
        try:
            sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(log))
            print("Logs sent to SQS")
        except Exception as e:
            print(f"Error sending logs to sqs: {str(e)}")
            
    
def main():
    print('Ingestor Started')
    while True:
        logs = fetch_logs()
        if logs:
            sendToSQS(logs)
            print('Logs send to sqs successfully')
        else:
            print('Failed to send logs to sqs')
        time.sleep(10)

if __name__ == "__main__":
    main()