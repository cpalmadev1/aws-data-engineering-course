# AWS Data Engineering Course - Terraform + Lambda

> Pipeline serverless para procesamiento automatizado de archivos CSV usando AWS Lambda, S3 y Terraform (100% IaC)

## 🏗️ Arquitectura
```
┌─────────┐       ┌────────────┐       ┌────────────┐
│   S3    │──────>│   Lambda   │──────>│ CloudWatch │
│ Bucket  │ event │  Function  │  logs │    Logs    │
└─────────┘       └────────────┘       └────────────┘
     ↑
  CSV Upload
  (trigger automático)
```

## 🛠️ Stack Técnico

- **IaC:** Terraform 1.14+
- **Cloud:** AWS (S3, Lambda, IAM, CloudWatch)
- **Runtime:** Python 3.11
- **Version Control:** Git + GitHub

## 📦 Recursos Desplegados

| Recurso | Descripción | Código |
|---------|-------------|--------|
| S3 Bucket | Storage con versioning y encryption AES256 | `aws_s3_bucket` |
| Lambda Function | Procesamiento serverless (256MB, 60s timeout) | `aws_lambda_function` |
| IAM Role | Permisos para Lambda | `aws_iam_role` |
| IAM Policies | Least privilege (S3 read + CloudWatch logs) | `aws_iam_role_policy` |
| S3 Event Notification | Trigger automático en CSV upload | `aws_s3_bucket_notification` |
| CloudWatch Logs | Observabilidad y debugging | Automático |

**Total: 9 recursos gestionados con Terraform**

## 🚀 Deployment
```bash
# Clonar repositorio
git clone https://github.com/cpalmadev1/aws-data-engineering-course.git
cd aws-data-engineering-course

# Configurar AWS credentials
aws configure

# Inicializar Terraform
cd terraform/environments/dev
terraform init

# Ver plan de ejecución
terraform plan

# Desplegar infraestructura
terraform apply
```

## 🧪 Testing
```bash
# Crear archivo CSV de prueba
cat > test.csv << EOF
producto,cantidad,precio
Laptop,5,1200.00
Mouse,20,25.50
Teclado,15,75.00
EOF

# Subir a S3 (dispara Lambda automáticamente)
aws s3 cp test.csv s3://cpalma-data-lake-2026/

# Ver logs de ejecución en tiempo real
aws logs tail /aws/lambda/data-lake-process-csv --follow
```

**Resultado esperado:**
- Lambda se ejecuta automáticamente al subir el CSV
- Procesa las 4 filas del archivo
- Imprime las primeras 3 filas en CloudWatch Logs

## 📚 Conceptos Aplicados

- ✅ **Infrastructure as Code (IaC)** con Terraform
- ✅ **Event-driven architecture** (S3 → Lambda)
- ✅ **IAM roles y policies** (least privilege principle)
- ✅ **Lambda packaging** y deployment serverless
- ✅ **S3 event notifications** para triggers automáticos
- ✅ **CloudWatch logging** para observabilidad
- ✅ **Terraform state management** y dependencias
- ✅ **Git workflow** (version control + GitHub)

## 📁 Estructura del Proyecto
```
aws-data-engineering-course/
├── README.md
├── .gitignore
├── src/
│   └── lambdas/
│       └── process_csv/
│           ├── lambda_function.py    # Código Python de Lambda
│           ├── lambda_package.zip    # Package deployable
│           └── requirements.txt      # Dependencias
└── terraform/
    ├── environments/
    │   └── dev/
    │       └── main.tf               # Configuración Terraform
    └── modules/                      # Módulos reutilizables (futuro)
```

## 🎯 Próximos Pasos

- [ ] EventBridge scheduled triggers (cron jobs)
- [ ] Step Functions para orquestación compleja
- [ ] AWS Glue para ETL a escala
- [ ] Athena para queries analíticos
- [ ] Multi-ambiente (dev/staging/prod)
- [ ] CI/CD con GitHub Actions

## 📊 Progreso del Curso
```
✅ Semana 1: S3 + Lambda (80% completado)
⬜ Semana 2: Step Functions
⬜ Semana 3-4: Glue + Athena
⬜ Semana 5-6: Optimización y producción
```

## 💰 Costos Estimados

| Recurso | Costo mensual |
|---------|---------------|
| S3 Storage (vacío) | $0.00 |
| Lambda (free tier) | $0.00 |
| CloudWatch Logs | ~$0.01 |
| **TOTAL** | **~$0.01/mes** |

---

**Autor:** Cesar Palma  
**GitHub:** [@cpalmadev1](https://github.com/cpalmadev1)  
**Fecha:** Enero 2026  
**Curso:** AWS Data Engineering con Terraform