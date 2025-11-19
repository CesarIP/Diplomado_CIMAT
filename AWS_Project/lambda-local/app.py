"""
Wrapper Flask para ejecutar la Lambda localmente
Convierte requests HTTP normales al formato de API Gateway
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import sys

# Importar el handler de Lambda
sys.path.insert(0, os.path.dirname(__file__))
from lambda_handler import lambda_handler

app = Flask(__name__)
CORS(app)

def create_api_gateway_event(method, path, body=None):
    """Crear evento simulado de API Gateway"""
    return {
        'httpMethod': method,
        'path': path,
        'body': body,
        'headers': dict(request.headers),
        'queryStringParameters': dict(request.args) if request.args else None,
        'pathParameters': None
    }

@app.route('/products', methods=['GET', 'POST'])
def products():
    """Endpoint /products"""
    body = request.get_data(as_text=True) if request.method == 'POST' else None
    event = create_api_gateway_event(request.method, '/products', body)
    
    response = lambda_handler(event, {})
    
    return jsonify(response.get('body', {})), response.get('statusCode', 200)

@app.route('/products/<product_id>', methods=['GET', 'PUT', 'DELETE'])
def product_detail(product_id):
    """Endpoint /products/{id}"""
    body = request.get_data(as_text=True) if request.method == 'PUT' else None
    path = f'/products/{product_id}'
    event = create_api_gateway_event(request.method, path, body)
    
    response = lambda_handler(event, {})
    
    # Parsear el body si es string JSON
    import json
    response_body = response.get('body', '{}')
    if isinstance(response_body, str):
        try:
            response_body = json.loads(response_body)
        except:
            pass
    
    return jsonify(response_body), response.get('statusCode', 200)

@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({'status': 'healthy', 'service': 'products-api-local'}), 200

if __name__ == '__main__':
    print("🚀 API Local iniciando en http://localhost:5000")
    print("📋 Endpoints disponibles:")
    print("   GET    /products")
    print("   POST   /products")
    print("   GET    /products/{id}")
    print("   PUT    /products/{id}")
    print("   DELETE /products/{id}")
    app.run(host='0.0.0.0', port=5000, debug=True)
