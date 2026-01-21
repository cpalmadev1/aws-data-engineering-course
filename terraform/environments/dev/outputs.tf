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