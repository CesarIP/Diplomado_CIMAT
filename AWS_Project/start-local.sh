#!/bin/bash

echo "╔════════════════════════════════════════════════════╗"
echo "║   🚀 Iniciando Proyecto AWS en Modo Local         ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Verificar que Docker esté corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    echo "   Por favor inicia Docker Desktop y vuelve a intentar"
    exit 1
fi

echo "✅ Docker está corriendo"
echo ""

# Verificar docker-compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: docker-compose no está instalado"
    exit 1
fi

echo "✅ Docker Compose disponible"
echo ""

# Detener contenedores previos si existen
echo "🧹 Limpiando contenedores previos..."
docker-compose -f docker-compose.local.yml down 2>/dev/null

echo ""
echo "🐳 Construyendo e iniciando servicios..."
echo "   Esto puede tomar unos minutos la primera vez..."
echo ""

# Iniciar servicios
docker-compose -f docker-compose.local.yml up --build -d

echo ""
echo "⏳ Esperando a que los servicios estén listos..."
sleep 10

# Verificar que los contenedores estén corriendo
if docker ps | grep -q "api-local"; then
    echo "✅ API Local está corriendo"
else
    echo "❌ API Local no inició correctamente"
    docker-compose -f docker-compose.local.yml logs api-local
    exit 1
fi

if docker ps | grep -q "streamlit-local"; then
    echo "✅ Streamlit está corriendo"
else
    echo "❌ Streamlit no inició correctamente"
    docker-compose -f docker-compose.local.yml logs streamlit-app
    exit 1
fi

if docker ps | grep -q "dynamodb-local"; then
    echo "✅ DynamoDB Local está corriendo"
else
    echo "❌ DynamoDB Local no inició correctamente"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║   ✅ Todos los servicios están corriendo          ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Accede a los servicios en:"
echo ""
echo "   📊 Dashboard Streamlit: http://localhost:8501"
echo "   🔌 API REST:            http://localhost:5001"
echo "   💾 DynamoDB Local:      http://localhost:8000"
echo ""
echo "📝 Comandos útiles:"
echo ""
echo "   Ver logs:           docker-compose -f docker-compose.local.yml logs -f"
echo "   Detener servicios:  docker-compose -f docker-compose.local.yml down"
echo "   Reiniciar:          docker-compose -f docker-compose.local.yml restart"
echo ""
echo "🧪 Prueba el API:"
echo ""
echo "   curl http://localhost:5001/products"
echo ""
echo "🎉 ¡Listo para usar!"
echo ""
