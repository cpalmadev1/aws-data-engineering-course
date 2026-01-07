# Configuración de Terraform
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider de AWS
provider "aws" {
  region = "us-east-1"
}

# Resource: S3 Bucket
resource "aws_s3_bucket" "data_lake" {
  bucket = "cpalma-data-lake-2026"

  tags = {
    Name        = "Data Lake - Curso"
    Environment = "dev"
    Project     = "aws-data-engineering-course"
    ManagedBy   = "Terraform"
  }
}

# Configuración de versioning
resource "aws_s3_bucket_versioning" "data_lake_versioning" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configuración de encriptación
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake_encryption" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Output: Mostrar el nombre del bucket
output "bucket_name" {
  description = "Nombre del bucket S3 creado"
  value       = aws_s3_bucket.data_lake.id
}

# Output: Mostrar el ARN del bucket
output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.data_lake.arn
}