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





