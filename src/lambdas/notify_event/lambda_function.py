import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    Lambda que notifica cuando llega un archivo.
    En producción esto enviaría a Slack/SNS/email.
    Por ahora solo imprime logs.
    
    Args:
        event: Evento de EventBridge con info de S3
        context: Metadata de Lambda
    """
    
    try:
        # EventBridge envuelve el evento de S3 diferente que S3 directo
        print("📬 Nueva notificación recibida de EventBridge")
        print(f"📋 Evento completo: {json.dumps(event, indent=2)}")
        
        # Extraer info del archivo desde el evento de EventBridge
        detail = event.get('detail', {})
        bucket = detail.get('bucket', {}).get('name', 'unknown')
        object_key = detail.get('object', {}).get('key', 'unknown')
        size = detail.get('object', {}).get('size', 0)
        
        # Timestamp
        event_time = event.get('time', datetime.utcnow().isoformat())
        
        # Mensaje de notificación
        message = f"""
        🔔 NOTIFICACIÓN DE ARCHIVO NUEVO
        
        📁 Bucket: {bucket}
        📄 Archivo: {object_key}
        📊 Tamaño: {size} bytes
        ⏰ Timestamp: {event_time}
        
        ✅ Archivo procesado por el pipeline
        """
        
        print(message)
        
        # En producción, aquí enviarías a:
        # - Slack: requests.post(webhook_url, json={'text': message})
        # - SNS: sns.publish(TopicArn=topic_arn, Message=message)
        # - Email: ses.send_email(...)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Notificación enviada',
                'bucket': bucket,
                'file': object_key,
                'size': size
            })
        }
        
    except Exception as e:
        print(f"❌ Error en notificación: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error en notificación',
                'error': str(e)
            })
        }