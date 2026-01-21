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