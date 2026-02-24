# ==========================================
# VPC
# ==========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.prefix}-vpc"
    Environment = var.environment
  }
}

# ==========================================
# Internet Gateway
# ==========================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-igw"
  }
}

# ==========================================
# Availability Zones
# ==========================================

data "aws_availability_zones" "available" {
  state = "available"
}

# ==========================================
# Public Subnets
# ==========================================

resource "aws_subnet" "public" {
  count = var.subnet_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.prefix}-public-${count.index + 1}"
    Environment = var.environment
  }
}

# ==========================================
# Route Table
# ==========================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${local.prefix}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Lambda Security Group
# ==========================================

resource "aws_security_group" "lambda" {
  name        = "${local.prefix}-lambda-sg"
  description = "Lambda function security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${local.prefix}-lambda-sg"
    Environment = var.environment
  }
}

# ==========================================
# VPC Endpoint Security Group
# ==========================================

resource "aws_security_group" "vpc_endpoint" {
  name        = "${local.prefix}-vpce-sg"
  description = "Secrets Manager VPC endpoint security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${local.prefix}-vpce-sg"
    Environment = var.environment
  }
}

# ==========================================
# Lambda SG Rules
# ==========================================

resource "aws_security_group_rule" "lambda_egress_rds" {
  type                     = "egress"
  description              = "Allow Lambda to connect to RDS"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = aws_security_group.rds.id
}

resource "aws_security_group_rule" "lambda_egress_https" {
  type              = "egress"
  description       = "Allow HTTPS for Secrets Manager VPC endpoint"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ==========================================
# VPC Endpoint SG Rules
# ==========================================

resource "aws_security_group_rule" "vpce_ingress_lambda" {
  type                     = "ingress"
  description              = "Allow Lambda to use Secrets Manager endpoint"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoint.id
  source_security_group_id = aws_security_group.lambda.id
}

resource "aws_security_group_rule" "vpce_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.vpc_endpoint.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ==========================================
# VPC Endpoint for Secrets Manager
# ==========================================

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = var.secretsmanager_endpoint_service
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.public[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name        = "${local.prefix}-secretsmanager-endpoint"
    Environment = var.environment
  }
}