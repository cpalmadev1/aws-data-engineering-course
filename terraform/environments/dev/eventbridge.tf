# ==============================================================================
# EVENTBRIDGE EVENT-DRIVEN ARCHITECTURE
# ==============================================================================
# Sistema paralelo al S3 direct trigger para comparar ambos enfoques
# Bucket nuevo → EventBridge → Múltiples Lambdas (desacoplado)

# ------------------------------------------------------------------------------
# 1. NUEVO BUCKET S3 (con EventBridge habilitado)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "eventbridge_demo" {
  bucket = "cpalma-eventbridge-demo-2026"

  tags = {
    Name        = "EventBridge Demo Bucket"
    Environment = "dev"
    Project     = "aws-data-engineering-course"
    ManagedBy   = "Terraform"
    Pattern     = "event-driven-eventbridge"
  }
}

# Versioning para el nuevo bucket
resource "aws_s3_bucket_versioning" "eventbridge_demo_versioning" {
  bucket = aws_s3_bucket.eventbridge_demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption para el nuevo bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "eventbridge_demo_encryption" {
  bucket = aws_s3_bucket.eventbridge_demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CRÍTICO: Habilitar EventBridge notifications en el bucket
resource "aws_s3_bucket_notification" "eventbridge_demo_notification" {
  bucket      = aws_s3_bucket.eventbridge_demo.id
  eventbridge = true # ← Esto habilita eventos a EventBridge
}

# ------------------------------------------------------------------------------
# 2. IAM ROLE para las nuevas Lambdas
# ------------------------------------------------------------------------------

resource "aws_iam_role" "eventbridge_lambda_role" {
  name = "eventbridge-lambda-role"

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
    Name        = "EventBridge Lambda Role"
    Environment = "dev"
    Project     = "aws-data-engineering-course"
    ManagedBy   = "Terraform"
  }
}

# Policy: Leer del nuevo bucket
resource "aws_iam_role_policy" "eventbridge_lambda_s3_policy" {
  name = "eventbridge-lambda-s3-policy"
  role = aws_iam_role.eventbridge_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.eventbridge_demo.arn,
        "${aws_s3_bucket.eventbridge_demo.arn}/*"
      ]
    }]
  })
}

# Policy: CloudWatch Logs
resource "aws_iam_role_policy_attachment" "eventbridge_lambda_logs" {
  role       = aws_iam_role.eventbridge_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------------------------------------------------------
# 3. LAMBDA 1 - Procesar CSV (copia adaptada para EventBridge)
# ------------------------------------------------------------------------------

resource "aws_lambda_function" "process_csv_eventbridge" {
  filename      = "../../../src/lambdas/process_csv/lambda_package.zip"
  function_name = "eventbridge-process-csv"
  role          = aws_iam_role.eventbridge_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256

  source_code_hash = filebase64sha256("../../../src/lambdas/process_csv/lambda_package.zip")

  environment {
    variables = {
      ENVIRONMENT = "dev"
      PATTERN     = "eventbridge"
    }
  }

  tags = {
    Name        = "EventBridge Process CSV Lambda"
    Environment = "dev"
    Project     = "aws-data-engineering-course"
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# 4. LAMBDA 2 - Notificación
# ------------------------------------------------------------------------------

resource "aws_lambda_function" "notify_event" {
  filename      = "../../../src/lambdas/notify_event/lambda_package.zip"
  function_name = "eventbridge-notify"
  role          = aws_iam_role.eventbridge_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 128

  source_code_hash = filebase64sha256("../../../src/lambdas/notify_event/lambda_package.zip")

  environment {
    variables = {
      ENVIRONMENT = "dev"
    }
  }

  tags = {
    Name        = "EventBridge Notify Lambda"
    Environment = "dev"
    Project     = "aws-data-engineering-course"
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# 5. EVENTBRIDGE RULE - Filtrar eventos de S3
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "s3-eventbridge-demo-object-created"
  description = "Captura eventos de S3 cuando se crea un objeto CSV"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.eventbridge_demo.id]
      }
      object = {
        key = [{
          suffix = ".csv"
        }]
      }
    }
  })

  tags = {
    Name        = "S3 Object Created Rule"
    Environment = "dev"
    Project     = "aws-data-engineering-course"
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------------------------
# 6. EVENTBRIDGE TARGETS - Conectar a las 2 Lambdas
# ------------------------------------------------------------------------------

# Target 1: Lambda procesadora
resource "aws_cloudwatch_event_target" "lambda_process_csv" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "ProcessCSVLambda"
  arn       = aws_lambda_function.process_csv_eventbridge.arn
}

# Target 2: Lambda notificadora
resource "aws_cloudwatch_event_target" "lambda_notify" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "NotifyLambda"
  arn       = aws_lambda_function.notify_event.arn
}

# ------------------------------------------------------------------------------
# 7. PERMISOS - EventBridge puede invocar Lambdas
# ------------------------------------------------------------------------------

# Permiso para Lambda 1
resource "aws_lambda_permission" "allow_eventbridge_process" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_csv_eventbridge.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created.arn
}

# Permiso para Lambda 2
resource "aws_lambda_permission" "allow_eventbridge_notify" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_event.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created.arn
}

# ------------------------------------------------------------------------------
# 8. OUTPUTS - Info del sistema EventBridge
# ------------------------------------------------------------------------------

output "eventbridge_bucket_name" {
  description = "Nombre del bucket EventBridge"
  value       = aws_s3_bucket.eventbridge_demo.id
}

output "eventbridge_rule_name" {
  description = "Nombre de la regla EventBridge"
  value       = aws_cloudwatch_event_rule.s3_object_created.name
}

output "eventbridge_lambda_process_name" {
  description = "Nombre de Lambda procesadora"
  value       = aws_lambda_function.process_csv_eventbridge.function_name
}

output "eventbridge_lambda_notify_name" {
  description = "Nombre de Lambda notificadora"
  value       = aws_lambda_function.notify_event.function_name
}