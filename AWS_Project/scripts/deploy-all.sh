#!/bin/bash

# Script de despliegue completo - Ejecuta todos los pasos en orden
# Uso: ./deploy-all.sh [environment] [region] [ec2-key-name]

set -e

ENVIRONMENT=${1:-prod}
REGION=${2:-us-east-1}
EC2_KEY_NAME=${3}

if [ -z "$EC2_KEY_NAME" ]; then
    echo "Error: Se requiere el nombre de la llave EC2"
    echo "Uso: ./deploy-all.sh [environment] [region] [ec2-key-name]"
    exit 1
fi

echo "=========================================="
echo "🚀 DESPLIEGUE COMPLETO DE APLICACIÓN AWS"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "EC2 Key: $EC2_KEY_NAME"
echo "=========================================="
echo ""

read -p "¿Continuar con el despliegue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Despliegue cancelado"
    exit 1
fi

# Paso 1: Desplegar infraestructura base (sin Lambda)
echo ""
echo "📋 Paso 1/5: Desplegando infraestructura base..."
./scripts/deploy-infrastructure.sh $ENVIRONMENT $REGION false

# Paso 2: Construir y publicar imágenes
echo ""
echo "🐳 Paso 2/5: Construyendo y publicando imágenes Docker..."
./scripts/build-and-push.sh all $ENVIRONMENT $REGION

# Paso 3: Actualizar stack con Lambda y API Gateway
echo ""
echo "⚡ Paso 3/5: Desplegando Lambda y API Gateway..."
./scripts/deploy-infrastructure.sh $ENVIRONMENT $REGION true

# Paso 4: Actualizar Lambda (por si acaso)
echo ""
echo "🔄 Paso 4/5: Verificando actualización de Lambda..."
./scripts/update-lambda.sh $ENVIRONMENT $REGION

# Paso 5: Desplegar EC2
echo ""
echo "🖥️  Paso 5/5: Desplegando aplicación EC2..."
./scripts/deploy-ec2.sh $ENVIRONMENT $REGION $EC2_KEY_NAME

echo ""
echo "=========================================="
echo "✅ DESPLIEGUE COMPLETADO EXITOSAMENTE"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Espera 3-5 minutos para que EC2 inicie completamente"
echo "2. Accede al dashboard en la URL mostrada arriba"
echo "3. Prueba el API usando los ejemplos del README.md"
echo ""
echo "Para ver los logs de EC2:"
echo "  ssh -i ~/.ssh/${EC2_KEY_NAME}.pem ec2-user@<PUBLIC_IP>"
echo "  sudo docker logs streamlit-app"
echo ""
