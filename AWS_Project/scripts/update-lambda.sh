#!/bin/bash

# Script para actualizar la función Lambda con la nueva imagen de ECR
# Uso: ./update-lambda.sh [environment] [region]

set -e

ENVIRONMENT=${1:-prod}
REGION=${2:-us-east-1}
PROJECT_NAME="productsapp"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

FUNCTION_NAME="${PROJECT_NAME}-api-${ENVIRONMENT}"
LAMBDA_REPO="${PROJECT_NAME}-lambda-${ENVIRONMENT}"
IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${LAMBDA_REPO}:latest"

echo "=========================================="
echo "Actualizando función Lambda"
echo "=========================================="
echo "Function: $FUNCTION_NAME"
echo "Image: $IMAGE_URI"
echo "=========================================="

# Actualizar código de función
echo "✓ Actualizando código de Lambda..."
aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --image-uri $IMAGE_URI \
    --region $REGION

# Esperar a que la actualización se complete
echo "✓ Esperando que la actualización se complete..."
aws lambda wait function-updated \
    --function-name $FUNCTION_NAME \
    --region $REGION

echo ""
echo "✅ Función Lambda actualizada exitosamente"
