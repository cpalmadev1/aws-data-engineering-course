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
