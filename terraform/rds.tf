# ==========================================
# RDS Subnet Group
# ==========================================

resource "aws_db_subnet_group" "postgres" {
  name       = "postgres-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "Postgres Subnet Group"
  }
}

# ==========================================
# RDS Security Group
# ==========================================

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow PostgreSQL access"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "rds-sg"
  }
}

# Allow from Lambda SG
resource "aws_security_group_rule" "rds_ingress_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.lambda.id
}

# Allow from anywhere (TESTING ONLY)
resource "aws_security_group_rule" "rds_ingress_public" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ==========================================
# RDS Instance
# ==========================================

resource "aws_db_instance" "postgres" {
  identifier             = "fastapi-postgres"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "fastapidb"
  username               = "postgres"
  password               = "postgres123"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name

  tags = {
    Name = "fastapi-postgres"
  }
}