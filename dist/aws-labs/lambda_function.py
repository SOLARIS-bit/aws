import json


def factorial(number: int) -> int:
    if number < 0:
        raise ValueError("number must be greater than or equal to 0")
    if number == 0:
        return 1
    return number * factorial(number - 1)


def lambda_handler(event, context):
    number = event.get("number")
    if not isinstance(number, int):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "number must be provided as an integer"}),
        }

    result = factorial(number)
    return {
        "statusCode": 200,
        "body": json.dumps({"factorial": result}),
    }