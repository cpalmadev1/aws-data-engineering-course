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