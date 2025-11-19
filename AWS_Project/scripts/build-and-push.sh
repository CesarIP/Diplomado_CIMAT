#!/bin/bash

# Script para construir y publicar imágenes Docker a ECR
# Uso: ./build-and-push.sh [lambda|ec2|all] [environment] [region]

set -e

# Configuración
SERVICE=${1:-all}
ENVIRONMENT=${2:-prod}
REGION=${3:-us-east-1}
PROJECT_NAME="productsapp"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=========================================="
echo "Build y Push de imágenes Docker a ECR"
echo "=========================================="
echo "Servicio: $SERVICE"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "=========================================="

# Autenticar con ECR
echo "✓ Autenticando con ECR..."
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Función para construir y publicar Lambda
build_lambda() {
    echo ""
    echo "📦 Construyendo imagen Lambda..."
    
    LAMBDA_REPO="${PROJECT_NAME}-lambda-${ENVIRONMENT}"
    LAMBDA_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${LAMBDA_REPO}"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    cd lambda
    
    # Construir imagen local con formato Docker v2 (deshabilitar BuildKit)
    DOCKER_BUILDKIT=0 docker build --platform linux/amd64 -t ${LAMBDA_REPO}:latest .
    
    # Etiquetar para ECR
    docker tag ${LAMBDA_REPO}:latest ${LAMBDA_URI}:latest
    docker tag ${LAMBDA_REPO}:latest ${LAMBDA_URI}:${TIMESTAMP}
    
    echo "✓ Publicando imagen Lambda a ECR..."
    # Forzar formato Docker v2 Schema (requerido por Lambda)
    DOCKER_BUILDKIT=0 docker push ${LAMBDA_URI}:latest
    DOCKER_BUILDKIT=0 docker push ${LAMBDA_URI}:${TIMESTAMP}
    
    cd ..
    
    echo "✅ Imagen Lambda publicada: ${LAMBDA_URI}:latest"
}

# Función para construir y publicar EC2 App
build_ec2() {
    echo ""
    echo "📦 Construyendo imagen EC2 App..."
    
    EC2_REPO="${PROJECT_NAME}-ec2app-${ENVIRONMENT}"
    EC2_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${EC2_REPO}"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    
    cd ec2_app
    docker build --platform linux/amd64 -t ${EC2_REPO}:latest .
    docker tag ${EC2_REPO}:latest ${EC2_URI}:latest
    docker tag ${EC2_REPO}:latest ${EC2_URI}:${TIMESTAMP}
    
    echo "✓ Publicando imagen EC2 App a ECR..."
    docker push ${EC2_URI}:latest
    docker push ${EC2_URI}:${TIMESTAMP}
    
    cd ..
    
    echo "✅ Imagen EC2 App publicada: ${EC2_URI}:latest"
}

# Ejecutar según el servicio especificado
case $SERVICE in
    lambda)
        build_lambda
        ;;
    ec2)
        build_ec2
        ;;
    all)
        build_lambda
        build_ec2
        ;;
    *)
        echo "❌ Servicio no válido. Use: lambda, ec2 o all"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "✅ Proceso completado exitosamente"
echo "=========================================="
