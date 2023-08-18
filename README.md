# Lambda Function for Retrieving Pre-signed URL for Latest File in S3 Bucket

## Description

The terraform code from this repo creates S3 bucket named "vo-lambda-bucket", AWS Role with attached policy to list and get objects from this bucket and a lambda function with the script written on Python to get a URL for the latest uploaded object.

The URL is valid 15 min after being created.

## How to Deploy

### Dependencies

- terraform v.1.3.4 or above

- AWS CLI version 2 - https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

### Authorization

```
export AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY
export AWS_DEFAULT_REGION=YOUR_AWS_REGION
```

**Note: make sure your user has all required permissions in AWS account you're going to work with**

#### Test access to your aws account.

Example command:
```
aws s3 ls
```
### Before Deploy

Change "vo-lambda-bucket" bucket name with your bucket name in _lambda.tf_ and _lambdaS3.py_ (zip archive must be re-created).

Optionally: change other resources names in _lambda.tf_

### Deploy

Assuming you are in the root of the repository run:

```
terraform init
terraform plan
terraform apply
```

## How to Test

1. Go to the AWS Management Console and navigate to the Lambda service.
2. Once deployed, you can test the Lambda function by configuring a test event with dummy data or invoking it directly from the Lambda console.
3. The Lambda function should return a pre-signed URL for the latest file in the specified S3 bucket, which will be valid for 15 minutes.
4. In case no objects are present in the bucket you will see the next message:
```
Response
{
  "statusCode": 404,
  "body": "No files found in the S3 bucket."
}
```

## Possible improvements

1. Additional bucket can be created for storing terraform state file
2. Additional script could be written so developer/sales agents can run it locally with some extra parameters (e.g. bucket name) and get a URL for the latest object in the specified bucket without visiting AWS console (lambda function should be updated as well, or new functions could be created for different buckets)
