#!/bin/bash

# Script para desplegar la infraestructura AWS usando CloudFormation
# Uso: ./deploy-infrastructure.sh [environment] [region] [deploy-lambda]

set -e

# Configuración por defecto
ENVIRONMENT=${1:-prod}
REGION=${2:-us-east-1}
DEPLOY_LAMBDA=${3:-false}
PROJECT_NAME="productsapp"
STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}"

echo "=========================================="
echo "Desplegando infraestructura AWS"
echo "=========================================="
echo "Proyecto: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "Stack: $STACK_NAME"
echo "Deploy Lambda: $DEPLOY_LAMBDA"
echo "=========================================="

# Validar template
echo "✓ Validando template de CloudFormation..."
aws cloudformation validate-template \
    --template-body file://infrastructure/cloudformation-template.yaml \
    --region $REGION

# Desplegar stack
echo "✓ Desplegando stack de CloudFormation..."
aws cloudformation deploy \
    --template-file infrastructure/cloudformation-template.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        ProjectName=$PROJECT_NAME \
        Environment=$ENVIRONMENT \
        DeployLambda=$DEPLOY_LAMBDA \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset

# Obtener outputs
echo "✓ Obteniendo información del stack..."
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output table

echo ""
echo "=========================================="
echo "✅ Infraestructura desplegada exitosamente"
echo "=========================================="

# Guardar outputs en archivo
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output json > infrastructure/stack-outputs.json

echo "Outputs guardados en: infrastructure/stack-outputs.json"
