# AWS Lambda Function for REST API

This repository provides an example implementation of an AWS Lambda function that can be invoked via a REST API using AWS API Gateway. The Lambda function takes a query parameter and returns a response with an incremented value.

## Prerequisites

1. **AWS Account**: You'll need an active AWS account with enough permissions to deploy the resources in this repository.
2. You need to have a **domain** hosted on AWS (in case your domain is hosted elsewhere, required changes should be done in code)

### Dependencies

- terraform v.1.3.4 or above

- AWS CLI version 2 - https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

## How to Use

**Clone the Repository**: Clone this repository to your local machine.

```
git clone https://github.com/drama17/restLambda.git
```

### Authorization

**Configure AWS CLI**: Make sure you have the AWS CLI installed and configured with your AWS credentials.

```
aws configure
```
**Or**

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

Change/add proper values in *variables.tf* file (e.g. zone_id and domain_name).

### Deploy

Use Terraform to deploy the required AWS resources.

```
cd restLambda
terraform init
terraform plan
terraform apply
```

This will create the Lambda function, API Gateway, IAM roles, and other necessary resources.

**Access the API**: Once the deployment is complete, you can access the API using the provided Invoke URL. For example:

```
curl -X GET https://your-invoke-url/increase?i=10
```
(your-invoke-url - the DNS record which will be created for the API. The construction is the next: api.YOUR_DOMAIN)

## Cleanup
When you're done experimenting with this example, make sure to clean up the resources to avoid unnecessary costs.

Run the following Terraform commands to destroy the infrastructure:

```
terraform destroy

```

## Possible improvements

1. Additional bucket can be created for storing terraform state file
2. AWS Cognito could be integrated here for the additional security

## Disclaimer

This example is meant for educational purposes and might involve costs if not properly managed. Make sure to review the resources being created and understand the pricing associated with them.
