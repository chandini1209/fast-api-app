import boto3
import json
import os
import logging
from sqlalchemy import create_engine, Engine
from sqlalchemy.orm import sessionmaker, declarative_base

logger = logging.getLogger(__name__)
Base = declarative_base()

def get_secret() -> dict:
    """Fetch DB credentials from AWS Secrets Manager."""
    secret_name = os.environ.get("DB_SECRET_NAME")
    region = os.environ.get("APP_REGION", "ca-central-1")

    if not secret_name:
        raise RuntimeError("DB_SECRET_NAME environment variable is not set")

    try:
        client = boto3.client("secretsmanager", region_name=region)
        response = client.get_secret_value(SecretId=secret_name)
        return json.loads(response["SecretString"])
    except Exception as e:
        logger.error("Failed to fetch secret: %s", str(e))
        raise

def build_engine() -> Engine:
    """Creates a SQLAlchemy engine using secrets."""
    secret = get_secret()

    url = (
        f"postgresql+psycopg2://{secret['username']}:{secret['password']}"
        f"@{secret['host']}:{secret.get('port', 5432)}/{secret['dbname']}"
    )

    return create_engine(
        url,
        pool_size=1,           # Optimized for Lambda
        max_overflow=0,
        pool_pre_ping=True,    # Verifies connection health
        pool_recycle=300,
        connect_args={"connect_timeout": 10, "sslmode": "require"},
    )

def build_session_factory(engine: Engine) -> sessionmaker:
    """Returns a session factory bound to the provided engine."""
    return sessionmaker(
        bind=engine,
        autocommit=False,
        autoflush=False,
    )
