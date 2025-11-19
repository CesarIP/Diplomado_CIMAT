.PHONY: help build deploy clean test

# Variables
ENVIRONMENT ?= prod
REGION ?= us-east-1
PROJECT_NAME = productsapp

help:
	@echo "Comandos disponibles:"
	@echo "  make build              - Construir imágenes Docker localmente"
	@echo "  make push               - Publicar imágenes a ECR"
	@echo "  make deploy-infra       - Desplegar infraestructura CloudFormation"
	@echo "  make deploy-lambda      - Actualizar función Lambda"
	@echo "  make deploy-ec2         - Desplegar aplicación EC2"
	@echo "  make deploy-all         - Desplegar todo (requiere EC2_KEY_NAME)"
	@echo "  make test-local         - Ejecutar con docker-compose localmente"
	@echo "  make clean              - Eliminar recursos AWS"
	@echo "  make logs-lambda        - Ver logs de Lambda"
	@echo ""
	@echo "Variables de entorno:"
	@echo "  ENVIRONMENT=${ENVIRONMENT}"
	@echo "  REGION=${REGION}"
	@echo "  EC2_KEY_NAME=${EC2_KEY_NAME}"

build:
	@echo "🐳 Construyendo imágenes Docker..."
	cd lambda && docker build -t productsapp-lambda:latest .
	cd ec2_app && docker build -t productsapp-ec2app:latest .

push:
	@echo "📤 Publicando imágenes a ECR..."
	./scripts/build-and-push.sh all $(ENVIRONMENT) $(REGION)

deploy-infra:
	@echo "🏗️ Desplegando infraestructura..."
	./scripts/deploy-infrastructure.sh $(ENVIRONMENT) $(REGION)

deploy-lambda:
	@echo "⚡ Actualizando Lambda..."
	./scripts/update-lambda.sh $(ENVIRONMENT) $(REGION)

deploy-ec2:
	@echo "🖥️ Desplegando EC2..."
	@if [ -z "$(EC2_KEY_NAME)" ]; then \
		echo "Error: Se requiere EC2_KEY_NAME"; \
		echo "Uso: make deploy-ec2 EC2_KEY_NAME=my-key"; \
		exit 1; \
	fi
	./scripts/deploy-ec2.sh $(ENVIRONMENT) $(REGION) $(EC2_KEY_NAME)

deploy-all:
	@echo "🚀 Despliegue completo..."
	@if [ -z "$(EC2_KEY_NAME)" ]; then \
		echo "Error: Se requiere EC2_KEY_NAME"; \
		echo "Uso: make deploy-all EC2_KEY_NAME=my-key"; \
		exit 1; \
	fi
	./scripts/deploy-all.sh $(ENVIRONMENT) $(REGION) $(EC2_KEY_NAME)

test-local:
	@echo "🧪 Ejecutando localmente con Docker Compose..."
	docker-compose up --build

clean:
	@echo "🗑️ Eliminando recursos..."
	@read -p "¿Estás seguro de eliminar todos los recursos? (y/n) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		aws cloudformation delete-stack \
			--stack-name $(PROJECT_NAME)-$(ENVIRONMENT) \
			--region $(REGION); \
		echo "Stack eliminándose..."; \
	fi

logs-lambda:
	@echo "📋 Logs de Lambda..."
	aws logs tail /aws/lambda/$(PROJECT_NAME)-api-$(ENVIRONMENT) --follow --region $(REGION)

api-url:
	@aws cloudformation describe-stacks \
		--stack-name $(PROJECT_NAME)-$(ENVIRONMENT) \
		--region $(REGION) \
		--query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
		--output text

test-api:
	@echo "🧪 Probando API..."
	@API_URL=$$(make api-url); \
	echo "Creando producto de prueba..."; \
	curl -X POST $$API_URL/products \
		-H "Content-Type: application/json" \
		-d '{"id":"test-001","name":"Test Product","description":"Test","price":99.99,"stock":10}'; \
	echo ""; \
	echo "Listando productos..."; \
	curl $$API_URL/products | jq
