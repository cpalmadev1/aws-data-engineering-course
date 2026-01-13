import json
import boto3
import csv
from io import StringIO

# Cliente de S3
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    Función principal de Lambda.
    Se ejecuta cuando llega un archivo a S3.
    
    Args:
        event: Información del trigger (bucket, archivo, etc.)
        context: Metadata de Lambda
    """
    
    try:
        # Obtener info del archivo que activó Lambda
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        print(f"🔍 Procesando archivo: {key} del bucket: {bucket}")
        
        # Leer archivo desde S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        file_content = response['Body'].read().decode('utf-8')
        
        # Parsear CSV
        csv_data = csv.DictReader(StringIO(file_content))
        rows = list(csv_data)
        
        print(f"📊 Total de filas procesadas: {len(rows)}")
        print(f"📋 Primeras 3 filas:")
        for i, row in enumerate(rows[:3], 1):
            print(f"  Fila {i}: {row}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Archivo procesado exitosamente',
                'bucket': bucket,
                'file': key,
                'rows_processed': len(rows)
            })
        }
        
    except Exception as e:
        print(f"❌ Error procesando archivo: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error procesando archivo',
                'error': str(e)
            })
        }