output "ecr_repository_url" {
  description = "ECR repository URL for docker push"
  value       = aws_ecr_repository.app.repository_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.fastapi.function_name
}

output "lambda_function_url" {
  description = "Public HTTPS endpoint for the FastAPI app"
  value       = aws_lambda_function_url.fastapi.function_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (internal VPC only)"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "db_secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "docker_push_commands" {
  description = "Commands to build and push Docker image"
  value = <<-EOT
    aws ecr get-login-password --region ${var.aws_region} | \
      docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}

    docker build --platform linux/amd64 -t ${aws_ecr_repository.app.repository_url}:latest ./app

    docker push ${aws_ecr_repository.app.repository_url}:latest

    aws lambda update-function-code \
      --function-name ${aws_lambda_function.fastapi.function_name} \
      --image-uri ${aws_ecr_repository.app.repository_url}:latest \
      --region ${var.aws_region}
  EOT
}
