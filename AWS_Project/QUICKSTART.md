# Guía de Inicio Rápido

## ⚡ Despliegue en 5 Minutos

### 1. Prerrequisitos Rápidos

```bash
# Verificar AWS CLI
aws --version

# Verificar Docker
docker --version

# Configurar AWS (si no está configurado)
aws configure
```

### 2. Clonar y Navegar

```bash
cd AWS_Project
```

### 3. Crear Par de Llaves EC2 (si no tienes uno)

```bash
# Opción A: Crear desde AWS Console
# Ve a EC2 > Key Pairs > Create Key Pair

# Opción B: Crear desde CLI
aws ec2 create-key-pair \
    --key-name products-key \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/products-key.pem

chmod 400 ~/.ssh/my-products-key.pem
```

### 4. Desplegar Todo

```bash
# Hacer scripts ejecutables (si no lo están)
chmod +x scripts/*.sh

# Desplegar todo de una vez
./scripts/deploy-all.sh prod us-east-1 products-key
```

### 5. Acceder a la Aplicación

Después de 3-5 minutos, accede a la URL mostrada en la consola:
```
http://<PUBLIC_IP>:8501
```

## 🎯 Despliegue Paso a Paso (Alternativa)

Si prefieres ejecutar cada paso manualmente:

```bash
# 1. Infraestructura
./scripts/deploy-infrastructure.sh prod us-east-1

# 2. Construir imágenes
./scripts/build-and-push.sh all prod us-east-1

# 3. Actualizar Lambda
./scripts/update-lambda.sh prod us-east-1

# 4. Desplegar EC2
./scripts/deploy-ec2.sh prod us-east-1 my-products-key
```

## 🧪 Prueba Rápida

```bash
# Obtener URL del API
API_URL=$(aws cloudformation describe-stacks \
  --stack-name ProductsApp-prod \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
  --output text)

# Crear producto de prueba
curl -X POST ${API_URL}/products \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-001",
    "name": "Producto de Prueba",
    "description": "Este es un producto de prueba",
    "price": 99.99,
    "stock": 5
  }'

# Ver productos
curl ${API_URL}/products | jq
```

## 🗑️ Limpieza Rápida

```bash
# Terminar EC2
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ProductsApp-ec2-prod" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Eliminar stack (esperar a que EC2 termine)
aws cloudformation delete-stack --stack-name ProductsApp-prod
```

## ⚠️ Problemas Comunes

### Error: "No se puede autenticar con ECR"
```bash
# Volver a autenticar
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
```

### Error: "Lambda no tiene imagen"
```bash
# Reconstruir y actualizar
./scripts/build-and-push.sh lambda prod us-east-1
./scripts/update-lambda.sh prod us-east-1
```

### EC2 no responde en el puerto 8501
```bash
# Verificar security group
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=ProductsApp-ec2-sg-prod" \
  --query 'SecurityGroups[0].IpPermissions'

# Debería incluir puerto 8501
```

## 📊 Monitoreo

```bash
# Ver logs de Lambda
aws logs tail /aws/lambda/ProductsApp-api-prod --follow

# Conectar a EC2 y ver logs
ssh -i ~/.ssh/my-products-key.pem ec2-user@<PUBLIC_IP>
sudo docker logs -f streamlit-app
```

## 💡 Tips

1. **Costos**: Los recursos principales son EC2 (~$15/mes) y Lambda/DynamoDB pay-per-use
2. **Regiones**: Usa `us-east-1` para costos más bajos
3. **Testing**: Usa Docker Compose localmente antes de desplegar
4. **Updates**: Solo necesitas reconstruir la imagen que modificaste
5. **Backup**: DynamoDB tiene point-in-time recovery (activarlo si es producción)

## 🎓 Siguiente Nivel

- Agregar Amazon CloudFront para CDN
- Implementar AWS WAF para seguridad
- Configurar Auto Scaling para EC2
- Añadir Amazon RDS como alternativa a DynamoDB
- Implementar CI/CD con AWS CodePipeline
- Agregar monitoreo con CloudWatch Dashboards


politicas de Usuario:
AdministratorAccess (para desarrollo) O las siguientes específicas:
AmazonEC2FullAccess
AmazonDynamoDBFullAccess
AWSLambda_FullAccess
AmazonEC2ContainerRegistryFullAccess
CloudFormationFullAccess
IAMFullAccess
AmazonAPIGatewayAdministrator
