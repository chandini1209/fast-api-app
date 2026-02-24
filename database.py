import boto3
import json
import os
import logging
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

logger = logging.getLogger(__name__)
Base = declarative_base()

_engine = None
_SessionLocal = None


def get_secret() -> dict:
    secret_name = os.environ["DB_SECRET_NAME"]
    region = os.environ.get("APP_REGION", "ca-central-1")
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    print("response: ", response)
    print("secret string: ", json.loads(response["SecretString"]))
    return json.loads(response["SecretString"])


def get_engine():
    global _engine

    if _engine is not None:
        return _engine

    try:
        secret = get_secret()

        host     = secret.get("host")
        port     = secret.get("port", 5432)
        db_name  = secret.get("dbname")
        username = secret.get("username")
        password = secret.get("password")
        print(f"DB Connection Details - Host: {host}, Port: {port}, DB Name: {db_name}, Username: {username}")

        DATABASE_URL = (
            f"postgresql+psycopg2://{username}:{password}"
            f"@{host}:{port}/{db_name}"
        )
        print(f"DATABASE_URL: {DATABASE_URL}")
        _engine = create_engine(
            DATABASE_URL,
            pool_size=1,
            max_overflow=0,
            pool_pre_ping=True,
            pool_recycle=300,
            connect_args={"connect_timeout": 10, "sslmode": "require"}
        )
        
        logger.info("Database engine created successfully")
        return _engine
    except Exception as e:
        logger.error(f"Failed to create database engine: {str(e)}")
        raise


def get_session_local():
    global _SessionLocal

    if _SessionLocal is None:
        engine = get_engine()
        _SessionLocal = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=engine,
        )

    return _SessionLocal