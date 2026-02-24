resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.prefix}-fastapi"
  retention_in_days = 14

  tags = { Name = "${local.prefix}-lambda-logs" }
}

resource "aws_lambda_function" "fastapi" {
  function_name = "${local.prefix}-fastapi"
  description   = "FastAPI CRUD application running on Lambda"

  package_type = "Image"
  image_uri    = "${aws_ecr_repository.app.repository_url}:${var.ecr_image_tag}"

  role        = aws_iam_role.lambda_exec.arn
  timeout     = var.lambda_timeout_sec
  memory_size = var.lambda_memory_mb

  vpc_config {
    subnet_ids         = aws_subnet.public[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
  variables = {
    DB_SECRET_NAME  = aws_secretsmanager_secret.db_credentials.name
    ENVIRONMENT     = var.environment
    APP_REGION      = var.aws_region
  }
}


  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc,
  ]

  tags = {
    Name        = "${local.prefix}-fastapi"
    Environment = var.environment
  }
}

resource "aws_lambda_function_url" "fastapi" {
  function_name      = aws_lambda_function.fastapi.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    max_age           = 86400
  }

  depends_on = [aws_lambda_function.fastapi]
}