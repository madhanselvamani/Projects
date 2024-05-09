import json
import boto3

# Create a DynamoDB object using the AWS SDK
dynamodb = boto3.resource('dynamodb')
# Use the DynamoDB object to select our table
table = dynamodb.Table('userinformation')

# Create an SNS client
sns_client = boto3.client('sns')
# Define the ARN of your SNS topic
sns_topic_arn = 'arn:aws:sns:us-east-1:313286460242:msg_sent'

# Define the handler function that the Lambda service will use as an entry point
def lambda_handler(event, context):
    # Extract values from the event object we got from the Lambda service and store in variables
    customer_id = event['customerId']
    name = event['name']
    address = event['address']
    
    # Write user data to the DynamoDB table and save the response in a variable
    response = table.put_item(
        Item={
            'userid': customer_id,
            'name': name,
            'address': address
        }
    )
    
    # Send notification to SNS topic
    sns_message = f"New user added: Customer ID: {customer_id}, Name: {name}, Address: {address}"
    sns_response = sns_client.publish(
        TopicArn=sns_topic_arn,
        Message=sns_message
    )
    
    # Return a properly formatted JSON object
    return {
        'statusCode': 200,
        'body': json.dumps('User data saved successfully!'),
        'snsResponse': sns_response
    }
