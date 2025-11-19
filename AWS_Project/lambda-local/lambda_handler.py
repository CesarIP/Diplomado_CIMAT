import json
import boto3
import os
from datetime import datetime
from decimal import Decimal

# Configurar endpoint de DynamoDB local si existe
dynamodb_config = {
    'region_name': os.environ.get('AWS_REGION', 'us-east-1')
}

if os.environ.get('DYNAMODB_ENDPOINT'):
    dynamodb_config['endpoint_url'] = os.environ.get('DYNAMODB_ENDPOINT')

# Inicializar cliente de DynamoDB
dynamodb = boto3.resource('dynamodb', **dynamodb_config)
table_name = os.environ.get('DYNAMODB_TABLE', 'ProductsTable')
table = dynamodb.Table(table_name)

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    """
    Handler principal para AWS Lambda
    Gestiona operaciones CRUD en DynamoDB a través de API Gateway
    """
    
    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    
    try:
        # GET /products - Listar todos los productos
        if http_method == 'GET' and path == '/products':
            return get_all_products()
        
        # GET /products/{id} - Obtener un producto
        elif http_method == 'GET' and path.startswith('/products/'):
            product_id = path.split('/')[-1]
            return get_product(product_id)
        
        # POST /products - Crear producto
        elif http_method == 'POST' and path == '/products':
            body = json.loads(event.get('body', '{}'))
            return create_product(body)
        
        # PUT /products/{id} - Actualizar producto
        elif http_method == 'PUT' and path.startswith('/products/'):
            product_id = path.split('/')[-1]
            body = json.loads(event.get('body', '{}'))
            return update_product(product_id, body)
        
        # DELETE /products/{id} - Eliminar producto
        elif http_method == 'DELETE' and path.startswith('/products/'):
            product_id = path.split('/')[-1]
            return delete_product(product_id)
        
        else:
            return response(404, {'error': 'Ruta no encontrada'})
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'error': str(e)})

def get_all_products():
    """Obtener todos los productos"""
    try:
        result = table.scan()
        items = result.get('Items', [])
        
        return response(200, {
            'products': items,
            'count': len(items)
        })
    except Exception as e:
        return response(500, {'error': f'Error al obtener productos: {str(e)}'})

def get_product(product_id):
    """Obtener un producto por ID"""
    try:
        result = table.get_item(Key={'id': product_id})
        
        if 'Item' in result:
            return response(200, result['Item'])
        else:
            return response(404, {'error': 'Producto no encontrado'})
    except Exception as e:
        return response(500, {'error': f'Error al obtener producto: {str(e)}'})

def create_product(data):
    """Crear un nuevo producto"""
    try:
        if 'id' not in data or 'name' not in data:
            return response(400, {'error': 'Se requiere id y name'})
        
        item = {
            'id': data['id'],
            'name': data['name'],
            'description': data.get('description', ''),
            'price': Decimal(str(data.get('price', 0))),
            'stock': data.get('stock', 0),
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
        
        table.put_item(Item=item)
        
        return response(201, {
            'message': 'Producto creado exitosamente',
            'product': item
        })
    except Exception as e:
        return response(500, {'error': f'Error al crear producto: {str(e)}'})

def update_product(product_id, data):
    """Actualizar un producto existente"""
    try:
        # Verificar si el producto existe
        result = table.get_item(Key={'id': product_id})
        if 'Item' not in result:
            return response(404, {'error': 'Producto no encontrado'})
        
        # Construir la expresión de actualización
        update_expression = "SET updated_at = :updated_at"
        expression_values = {':updated_at': datetime.now().isoformat()}
        expression_names = {}
        
        if 'name' in data:
            update_expression += ", #n = :name"
            expression_values[':name'] = data['name']
            expression_names['#n'] = 'name'
        
        if 'description' in data:
            update_expression += ", description = :description"
            expression_values[':description'] = data['description']
        
        if 'price' in data:
            update_expression += ", price = :price"
            expression_values[':price'] = Decimal(str(data['price']))
        
        if 'stock' in data:
            update_expression += ", stock = :stock"
            expression_values[':stock'] = data['stock']
        
        # Actualizar el producto
        update_params = {
            'Key': {'id': product_id},
            'UpdateExpression': update_expression,
            'ExpressionAttributeValues': expression_values,
            'ReturnValues': "ALL_NEW"
        }
        
        if expression_names:
            update_params['ExpressionAttributeNames'] = expression_names
        
        result = table.update_item(**update_params)
        
        return response(200, {
            'message': 'Producto actualizado exitosamente',
            'product': result['Attributes']
        })
    except Exception as e:
        return response(500, {'error': f'Error al actualizar producto: {str(e)}'})

def delete_product(product_id):
    """Eliminar un producto"""
    try:
        # Verificar si el producto existe
        result = table.get_item(Key={'id': product_id})
        if 'Item' not in result:
            return response(404, {'error': 'Producto no encontrado'})
        
        table.delete_item(Key={'id': product_id})
        
        return response(200, {'message': 'Producto eliminado exitosamente'})
    except Exception as e:
        return response(500, {'error': f'Error al eliminar producto: {str(e)}'})

def response(status_code, body):
    """Generar respuesta HTTP"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }
