aws_region   = "ca-central-1"
project_name = "fastapi-app"
environment  = "dev"

# Database
db_name     = "appdb"
db_username = "appuser"
db_password = "FastApiPassw0rd!"

# Lambda
lambda_memory_mb   = 512
lambda_timeout_sec = 30
ecr_image_tag      = "latest"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
subnet_count         = 2
enable_dns_support   = true
enable_dns_hostnames = true
secretsmanager_endpoint_service = "com.amazonaws.ca-central-1.secretsmanager"