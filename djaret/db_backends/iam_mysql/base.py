import os

import boto3
from django.db.backends.mysql import base


class DatabaseWrapper(base.DatabaseWrapper):
    def get_connection_params(self):
        params = super().get_connection_params()
        client = boto3.client("rds", region_name=os.environ["AWS_REGION"])
        params["password"] = client.generate_db_auth_token(
            DBHostname=os.environ["DB_HOST"],
            Port=3306,
            DBUsername=os.environ["DB_USER"],
            Region=os.environ["AWS_REGION"],
        )
        return params
