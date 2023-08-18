import boto3
from datetime import datetime, timedelta

def lambda_handler(event, context):
    bucket_name = 'vo-lambda-bucket'

    # Create an S3 client
    s3_client = boto3.client('s3')

    # List objects in the S3 bucket sorted by the 'LastModified' timestamp in descending order
    response = s3_client.list_objects_v2(Bucket=bucket_name)
    if 'Contents' in response and len(response['Contents']) > 0:
        sorted_objects = sorted(response['Contents'], key=lambda obj: obj['LastModified'], reverse=True)
    else:
        return {
            'statusCode': 404,
            'body': 'No files found in the S3 bucket.'
        }

    if len(sorted_objects) > 0:
        # Get the latest object (file) in the bucket
        latest_object_key = sorted_objects[0]['Key']

        # Generate a pre-signed URL for the latest object with a 15-minute expiration
        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket_name, 'Key': latest_object_key},
            ExpiresIn=900  # 900 seconds (15 minutes)
        )

        return {
            'statusCode': 200,
            'body': presigned_url
        }
    else:
        return {
            'statusCode': 404,
            'body': 'No files found in the S3 bucket.'
        }
