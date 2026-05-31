import os
import time

import boto3
from django.db.backends.mysql import base

# Construct the RDS client once per execution environment. Building a boto3
# client loads the botocore service model (~100-300ms) — doing it per
# connection (the old behavior, combined with CONN_MAX_AGE=0) repeated that
# cost on every request. Module scope folds it into static init, once per env.
_rds = boto3.client("rds", region_name=os.environ["AWS_REGION"])

# Cache the IAM auth token. RDS auth tokens are valid for 15 minutes; regenerate
# only when the cached one is older than 13 minutes (margin before expiry).
_TOKEN_TTL = 13 * 60
_token_cache = {"value": None, "ts": 0.0}


def _auth_token():
    now = time.monotonic()
    if _token_cache["value"] is None or now - _token_cache["ts"] > _TOKEN_TTL:
        _token_cache["value"] = _rds.generate_db_auth_token(
            DBHostname=os.environ["DB_HOST"],
            Port=3306,
            DBUsername=os.environ["DB_USER"],
            Region=os.environ["AWS_REGION"],
        )
        _token_cache["ts"] = now
    return _token_cache["value"]


class DatabaseWrapper(base.DatabaseWrapper):
    def get_connection_params(self):
        params = super().get_connection_params()
        params["password"] = _auth_token()
        return params
