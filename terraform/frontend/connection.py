import boto3
from botocore.exceptions import ClientError
import datetime
from boto3.dynamodb.conditions import Key, Attr

def create_ressource() -> boto3.resource:
    dynamodb = boto3.resource('dynamodb')
    return dynamodb


def scan_table(table_name : str):
    if type(table_name) != str:
        raise ValueError("The tablename needs to be a string")

    dynamodb = create_ressource()
    current_date = datetime.datetime.now().strftime('%Y-%m-%d')

    try:
        table = dynamodb.Table(table_name)
        response = table.scan(FilterExpression=Attr('data.date').eq(current_date))
        return response

    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code')
        error_message = e.response.get('Error', {}).get('Message')

        if error_code == 'ResourceNotFoundException':
            print(f"Table '{table_name}' not found. Error message: {error_message}")
        elif error_code == 'ValidationException':
            print("A validation error occurred. Error message:", error_message)
        elif error_code == 'ProvisionedThroughputExceededException':
            print("Provisioned throughput exceeded. Error message:", error_message)
        elif error_code == 'InternalServerError':
            print("An internal server error occurred. Error message:", error_message)
        else:
            print("An unexpected error occurred:", error_message)
