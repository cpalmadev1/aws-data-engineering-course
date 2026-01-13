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

# IAM Role para Lambda
resource "aws_iam_role" "lambda_role" {
  name = "data-lake-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "Lambda Role - Data Lake"
    Environment = "dev"
    Project     = "aws-data-engineering-course"
    ManagedBy   = "Terraform"
  }
}

# Policy 1: Permisos para leer S3
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "lambda-s3-read-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.data_lake.arn,
        "${aws_s3_bucket.data_lake.arn}/*"
      ]
    }]
  })
}

# Policy 2: Permisos para escribir logs en CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "process_csv" {
  filename      = "../../../src/lambdas/process_csv/lambda_package.zip"
  function_name = "data-lake-process-csv"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256

  source_code_hash = filebase64sha256("../../../src/lambdas/process_csv/lambda_package.zip")

  environment {
    variables = {
      ENVIRONMENT = "dev"
    }
  }

  tags = {
    Name        = "Process CSV Lambda"
    Environment = "dev"
    Project     = "aws-data-engineering-course"
    ManagedBy   = "Terraform"
  }
}

# Permiso para que S3 pueda invocar Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_csv.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_lake.arn
}

# Notificación de S3 para disparar Lambda
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.data_lake.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_csv.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3]
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
# Output: Nombre de Lambda
output "lambda_function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.process_csv.function_name
}

# Output: ARN de Lambda
output "lambda_function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.process_csv.arn
}