#!/bin/bash

# Script para crear y configurar una instancia EC2
# Uso: ./deploy-ec2.sh [environment] [region] [key-name]

set -e

ENVIRONMENT=${1:-prod}
REGION=${2:-us-east-1}
KEY_NAME=${3:-my-ec2-key}
PROJECT_NAME="productsapp"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}"
EC2_REPO="${PROJECT_NAME}-ec2app-${ENVIRONMENT}"
IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${EC2_REPO}:latest"

echo "=========================================="
echo "Desplegando aplicación en EC2"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "Key Name: $KEY_NAME"
echo "=========================================="

# Obtener información del stack
echo "✓ Obteniendo información de infraestructura..."

SUBNET_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnetId`].OutputValue' \
    --output text)

SECURITY_GROUP_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`EC2SecurityGroupId`].OutputValue' \
    --output text)

INSTANCE_PROFILE=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`EC2InstanceProfileArn`].OutputValue' \
    --output text)

API_GATEWAY_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
    --output text)

# User data script
USER_DATA=$(cat <<EOF
#!/bin/bash
set -e

# Actualizar sistema
yum update -y

# Instalar Docker
yum install -y docker
service docker start
usermod -a -G docker ec2-user

# Instalar AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Autenticar con ECR
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Descargar y ejecutar contenedor
docker pull ${IMAGE_URI}
docker run -d -p 8501:8501 \
    -e API_GATEWAY_URL=${API_GATEWAY_URL} \
    --name streamlit-app \
    --restart unless-stopped \
    ${IMAGE_URI}

echo "Aplicación iniciada en el puerto 8501"
EOF
)

# Crear instancia EC2
echo "✓ Creando instancia EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --instance-type t3.small \
    --key-name $KEY_NAME \
    --subnet-id $SUBNET_ID \
    --security-group-ids $SECURITY_GROUP_ID \
    --iam-instance-profile Name=${PROJECT_NAME}-ec2-profile-${ENVIRONMENT} \
    --user-data "$USER_DATA" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT_NAME}-ec2-${ENVIRONMENT}},{Key=Environment,Value=${ENVIRONMENT}}]" \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

# Esperar a que la instancia esté corriendo
echo "✓ Esperando que la instancia esté corriendo..."
aws ec2 wait instance-running \
    --instance-ids $INSTANCE_ID \
    --region $REGION

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo ""
echo "=========================================="
echo "✅ EC2 desplegado exitosamente"
echo "=========================================="
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Streamlit URL: http://${PUBLIC_IP}:8501"
echo "=========================================="
echo ""
echo "Nota: La aplicación tardará unos minutos en estar disponible"
echo "mientras se completa el user-data script."
