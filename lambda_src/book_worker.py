import json
import os
import socket

import boto3


def _check_database_socket(host: str, port: int) -> tuple[bool, str]:
    if not host:
        return False, "DB_HOST was not configured"

    try:
        with socket.create_connection((host, port), timeout=3):
            return True, ""
    except OSError as exc:
        return False, str(exc)


def lambda_handler(event, context):
    secret_arn = os.getenv("DB_SECRET_ARN", "")
    db_host = os.getenv("DB_HOST", "")
    db_port = int(os.getenv("DB_PORT", "5432"))

    payload = {
        "invocation_id": context.aws_request_id,
        "event": event,
    }

    if secret_arn:
        secrets_manager = boto3.client("secretsmanager")
        secret_value = secrets_manager.get_secret_value(SecretId=secret_arn)
        secret_payload = json.loads(secret_value["SecretString"])

        payload["db_secret_summary"] = {
            "username": secret_payload.get("username"),
            "engine": secret_payload.get("engine"),
            "database": secret_payload.get("dbname") or secret_payload.get("database"),
        }

    is_reachable, error_message = _check_database_socket(db_host, db_port)
    payload["database_reachable"] = is_reachable

    if error_message:
        payload["database_error"] = error_message

    print(json.dumps(payload))
    return payload
