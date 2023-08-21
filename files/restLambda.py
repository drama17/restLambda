import json

def lambda_handler(event, context):
    try:
        query_params = event['queryStringParameters']
        number = int(query_params['i'])
        result = number + 1

        response = {
            "statusCode": 200,
            "body": json.dumps(result)
        }

        return response
    except Exception as e:
        response = {
            "statusCode": 500,
            "body": json.dumps("Error: " + str(e))
        }
        return response
