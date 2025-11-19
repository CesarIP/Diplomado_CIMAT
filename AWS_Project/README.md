# 🚀 Proyecto AWS - Sistema de Gestión de Productos

Sistema completo de gestión de productos desplegado en AWS utilizando arquitectura serverless y contenedores.

## 📋 Arquitectura

Este proyecto utiliza los siguientes servicios de AWS:

- **AWS Lambda**: API REST para operaciones CRUD
- **API Gateway**: Endpoint HTTP para acceder a Lambda
- **DynamoDB**: Base de datos NoSQL para almacenar productos
- **ECR (Elastic Container Registry)**: Registro de imágenes Docker
- **EC2**: Servidor para la aplicación web (dashboard Streamlit)
- **CloudFormation**: Infraestructura como código
- **IAM**: Gestión de permisos y roles
- **VPC**: Red virtual para EC2

### Diagrama de Arquitectura

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │
       ├──────────────────┐
       │                  │
       ▼                  ▼
┌─────────────┐    ┌─────────────┐
│  Streamlit  │    │ API Gateway │
│   (EC2)     │    │             │
└──────┬──────┘    └──────┬──────┘
       │                  │
       │                  ▼
       │           ┌─────────────┐
       │           │   Lambda    │
       │           │  (Docker)   │
       │           └──────┬──────┘
       │                  │
       └──────────┬───────┘
                  │
                  ▼
           ┌─────────────┐
           │  DynamoDB   │
           │   Table     │
           └─────────────┘
```

## 🛠️ Componentes

### 1. Lambda Function (`/lambda`)
- **Función**: API REST para operaciones CRUD
- **Runtime**: Python 3.11 en contenedor Docker
- **Endpoints**:
  - `GET /products` - Listar todos los productos
  - `GET /products/{id}` - Obtener producto por ID
  - `POST /products` - Crear producto
  - `PUT /products/{id}` - Actualizar producto
  - `DELETE /products/{id}` - Eliminar producto

### 2. EC2 Application (`/ec2_app`)
- **Framework**: Streamlit
- **Puerto**: 8501
- **Funcionalidad**: Dashboard web para gestionar productos
- **Contenedor**: Docker con Python 3.11

### 3. Infraestructura (`/infrastructure`)
- **CloudFormation**: Template completo con todos los recursos
- **Recursos creados**:
  - Tabla DynamoDB
  - Repositorios ECR (Lambda y EC2)
  - Función Lambda con rol IAM
  - API Gateway REST API
  - VPC con subnet pública
  - Security Groups
  - IAM Roles y Policies

### 4. Scripts de Despliegue (`/scripts`)
- `deploy-infrastructure.sh` - Despliega la infraestructura con CloudFormation
- `build-and-push.sh` - Construye y publica imágenes Docker a ECR
- `update-lambda.sh` - Actualiza la función Lambda con nueva imagen
- `deploy-ec2.sh` - Crea y configura instancia EC2

## 📦 Prerrequisitos

1. **AWS CLI** configurado con credenciales válidas
2. **Docker** instalado y corriendo
3. **Bash** shell
4. **Cuenta AWS** con permisos para crear recursos
5. **Par de llaves EC2** (para SSH a la instancia)

## 🚀 Despliegue Completo

### Paso 1: Configurar variables

```bash
export AWS_REGION=us-east-1
export ENVIRONMENT=prod
export PROJECT_NAME=ProductsApp
export EC2_KEY_NAME=my-ec2-key  # Tu par de llaves EC2
```

### Paso 2: Desplegar infraestructura

```bash
cd AWS_Project
./scripts/deploy-infrastructure.sh $ENVIRONMENT $AWS_REGION
```

Este comando creará:
- Tabla DynamoDB
- Repositorios ECR
- Función Lambda (placeholder)
- API Gateway
- VPC y subnets
- Security Groups
- IAM Roles

### Paso 3: Construir y publicar imágenes Docker

```bash
./scripts/build-and-push.sh all $ENVIRONMENT $AWS_REGION
```

Este comando:
1. Autentica con ECR
2. Construye imagen Lambda
3. Construye imagen EC2
4. Publica ambas imágenes a ECR

### Paso 4: Actualizar Lambda con la imagen

```bash
./scripts/update-lambda.sh $ENVIRONMENT $AWS_REGION
```

### Paso 5: Desplegar aplicación EC2

```bash
./scripts/deploy-ec2.sh $ENVIRONMENT $AWS_REGION $EC2_KEY_NAME
```

Este comando:
1. Crea instancia EC2
2. Instala Docker
3. Descarga imagen del ECR
4. Ejecuta contenedor con Streamlit
5. Muestra la URL de acceso

## 🔧 Desarrollo Local

### Usando Docker Compose

```bash
# Construir y ejecutar todos los servicios
docker-compose up --build

# Acceder a:
# - Streamlit: http://localhost:8501
# - Lambda local: http://localhost:9000
```

### Lambda local

```bash
cd lambda
docker build -t products-lambda .
docker run -p 9000:8080 \
  -e DYNAMODB_TABLE=ProductsTable \
  products-lambda
```

### Streamlit local

```bash
cd ec2_app
pip install -r requirements.txt
export API_GATEWAY_URL=https://your-api-gateway-url.com/prod
streamlit run app.py
```

## 📊 Modelo de Datos (DynamoDB)

### Tabla: Products

```json
{
  "id": "string (PK)",
  "name": "string",
  "description": "string",
  "price": "number",
  "stock": "number",
  "created_at": "string (ISO 8601)",
  "updated_at": "string (ISO 8601)"
}
```

## 🔐 Seguridad

- **IAM Roles**: Principio de menor privilegio
- **Security Groups**: Solo puertos necesarios (8501, 22)
- **VPC**: Red aislada para EC2
- **ECR**: Escaneo de vulnerabilidades activado
- **API Gateway**: CORS configurado

## 💰 Costos Estimados

| Servicio | Costo Aproximado |
|----------|------------------|
| Lambda | ~$0.20/millón de invocaciones |
| DynamoDB | Pay-per-request (~$1.25/millón) |
| API Gateway | ~$3.50/millón de llamadas |
| EC2 t3.small | ~$15/mes |
| ECR | $0.10/GB/mes |

**Total estimado**: ~$20-30/mes (uso moderado)

## 🧪 Pruebas

### Probar API directamente

```bash
# Obtener URL del API Gateway
API_URL=$(aws cloudformation describe-stacks \
  --stack-name ProductsApp-prod \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

# Crear producto
curl -X POST ${API_URL}/products \
  -H "Content-Type: application/json" \
  -d '{
    "id": "prod-001",
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "stock": 10
  }'

# Listar productos
curl ${API_URL}/products

# Obtener producto
curl ${API_URL}/products/prod-001

# Actualizar producto
curl -X PUT ${API_URL}/products/prod-001 \
  -H "Content-Type: application/json" \
  -d '{"price": 899.99, "stock": 15}'

# Eliminar producto
curl -X DELETE ${API_URL}/products/prod-001
```

## 🔄 Actualización

### Actualizar código Lambda

```bash
# 1. Modificar código en lambda/app.py
# 2. Reconstruir y publicar imagen
./scripts/build-and-push.sh lambda prod us-east-1

# 3. Actualizar función Lambda
./scripts/update-lambda.sh prod us-east-1
```

### Actualizar aplicación EC2

```bash
# 1. Modificar código en ec2_app/app.py
# 2. Reconstruir y publicar imagen
./scripts/build-and-push.sh ec2 prod us-east-1

# 3. SSH a EC2 y actualizar contenedor
ssh -i ~/.ssh/${EC2_KEY_NAME}.pem ec2-user@<EC2_PUBLIC_IP>
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <AWS_ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com
docker pull <ECR_URI>:latest
docker stop streamlit-app
docker rm streamlit-app
docker run -d -p 8501:8501 -e API_GATEWAY_URL=<URL> --name streamlit-app --restart unless-stopped <ECR_URI>:latest
```

## 🗑️ Limpieza de Recursos

```bash
# Eliminar instancia EC2
aws ec2 terminate-instances --instance-ids <INSTANCE_ID> --region us-east-1

# Eliminar imágenes de ECR
aws ecr batch-delete-image \
  --repository-name ProductsApp-lambda-prod \
  --image-ids imageTag=latest \
  --region us-east-1

aws ecr batch-delete-image \
  --repository-name ProductsApp-ec2app-prod \
  --image-ids imageTag=latest \
  --region us-east-1

# Eliminar stack de CloudFormation (esto elimina todos los recursos)
aws cloudformation delete-stack \
  --stack-name ProductsApp-prod \
  --region us-east-1
```

## 📝 Notas Importantes

1. **Primera vez**: La función Lambda necesita la imagen en ECR antes de poder ejecutarse
2. **EC2 User Data**: La aplicación tarda 3-5 minutos en estar disponible después de crear la instancia
3. **API Gateway URL**: Debes configurarla en la variable de entorno de EC2 después del despliegue
4. **Costos**: No olvides eliminar recursos cuando no los uses para evitar cargos
5. **Región**: Asegúrate de usar la misma región en todos los comandos

## 🐛 Troubleshooting

### Lambda no responde
- Verificar que la imagen existe en ECR
- Revisar logs en CloudWatch: `/aws/lambda/ProductsApp-api-prod`
- Verificar permisos del rol IAM

### EC2 no accesible
- Verificar Security Group permite tráfico en puerto 8501
- Revisar logs del user-data: `ssh` a EC2 y `cat /var/log/cloud-init-output.log`
- Verificar que Docker está corriendo: `sudo systemctl status docker`

### DynamoDB errores
- Verificar que la tabla existe
- Revisar permisos del rol Lambda
- Confirmar nombre de tabla en variable de entorno

## 📚 Recursos Adicionales

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Streamlit Documentation](https://docs.streamlit.io/)

## 👨‍💻 Autor

Proyecto desarrollado para el Diplomado CIMAT

## 📄 Licencia

Este proyecto es de código abierto y está disponible para uso educativo.
