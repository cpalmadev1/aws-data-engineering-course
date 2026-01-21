import json
import boto3
import csv
from io import StringIO

# Cliente de S3
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    Función principal de Lambda.
    Maneja eventos de:
    - S3 directo (Sistema 1)
    - EventBridge (Sistema 2)
    
    Args:
        event: Evento de S3 o EventBridge
        context: Metadata de Lambda
    """
    
    try:
        # Detectar tipo de evento y extraer info
        bucket, key = extract_s3_info(event)
        
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


def extract_s3_info(event):
    """
    Extrae información de S3 del evento.
    Soporta:
    - Eventos de S3 directo (con 'Records')
    - Eventos de EventBridge (con 'detail')
    
    Returns:
        tuple: (bucket_name, object_key)
    """
    # Evento de S3 directo (Sistema 1)
    if 'Records' in event:
        print("📌 Evento tipo: S3 Direct Notification")
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        return bucket, key
    
    # Evento de EventBridge (Sistema 2)
    elif 'detail' in event:
        print("📌 Evento tipo: EventBridge")
        bucket = event['detail']['bucket']['name']
        key = event['detail']['object']['key']
        return bucket, key
    
    # Evento desconocido
    else:
        raise ValueError(f"Formato de evento desconocido: {json.dumps(event)}")