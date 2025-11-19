# 🐳 Ejecución Local del Proyecto

Esta guía te permite ejecutar **todo el proyecto completamente en local** sin necesidad de AWS.

## 📋 Requisitos

- Docker Desktop instalado y corriendo
- Docker Compose (viene con Docker Desktop)

## 🚀 Inicio Rápido

### Opción 1: Con el script automatizado

```bash
./start-local.sh
```

### Opción 2: Manual

```bash
# Iniciar todos los servicios
docker-compose -f docker-compose.local.yml up --build

# O en modo detached (segundo plano)
docker-compose -f docker-compose.local.yml up -d --build
```

## 🎯 Acceso a los Servicios

Una vez iniciado, tendrás acceso a:

- **🖥️ Dashboard Streamlit**: http://localhost:8501
- **🔌 API REST**: http://localhost:5000
- **💾 DynamoDB Local**: http://localhost:8000

## 📝 Probar el API Manualmente

### Crear un producto
```bash
curl -X POST http://localhost:5000/products \
  -H "Content-Type: application/json" \
  -d '{
    "id": "prod-001",
    "name": "Laptop",
    "description": "Laptop gaming",
    "price": 999.99,
    "stock": 10
  }'
```

### Listar productos
```bash
curl http://localhost:5000/products
```

### Obtener un producto
```bash
curl http://localhost:5000/products/prod-001
```

### Actualizar producto
```bash
curl -X PUT http://localhost:5000/products/prod-001 \
  -H "Content-Type: application/json" \
  -d '{
    "price": 899.99,
    "stock": 8
  }'
```

### Eliminar producto
```bash
curl -X DELETE http://localhost:5000/products/prod-001
```

## 🛑 Detener los Servicios

```bash
# Detener servicios
docker-compose -f docker-compose.local.yml down

# Detener y eliminar volúmenes (borra datos de DynamoDB)
docker-compose -f docker-compose.local.yml down -v
```

## 🔍 Ver Logs

```bash
# Todos los servicios
docker-compose -f docker-compose.local.yml logs -f

# Solo API
docker-compose -f docker-compose.local.yml logs -f api-local

# Solo Streamlit
docker-compose -f docker-compose.local.yml logs -f streamlit-app

# Solo DynamoDB
docker-compose -f docker-compose.local.yml logs -f dynamodb-local
```

## 🐛 Solución de Problemas

### El puerto 8501 ya está en uso
```bash
# Ver qué proceso usa el puerto
lsof -i :8501

# Cambiar el puerto en docker-compose.local.yml
# Modificar: "8502:8501" en lugar de "8501:8501"
```

### DynamoDB no se conecta
```bash
# Reiniciar solo DynamoDB
docker-compose -f docker-compose.local.yml restart dynamodb-local dynamodb-init
```

### Reconstruir desde cero
```bash
# Eliminar todo y empezar de nuevo
docker-compose -f docker-compose.local.yml down -v
docker-compose -f docker-compose.local.yml build --no-cache
docker-compose -f docker-compose.local.yml up
```

## 📊 Arquitectura Local

```
┌─────────────────────┐
│   Navegador         │
│  localhost:8501     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Streamlit App      │
│  (Container)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Flask API          │
│  localhost:5000     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  DynamoDB Local     │
│  localhost:8000     │
└─────────────────────┘
```

## 🎨 Ventajas del Entorno Local

✅ No requiere cuenta AWS  
✅ No genera costos  
✅ Desarrollo rápido sin latencia de red  
✅ Datos persistentes en volumen Docker  
✅ Reinicio rápido de servicios  
✅ Ideal para pruebas y desarrollo  

## 📚 Diferencias con Producción

| Componente | Local | AWS |
|------------|-------|-----|
| API | Flask en contenedor | Lambda + API Gateway |
| Frontend | Streamlit en contenedor | EC2 con Docker |
| Base de Datos | DynamoDB Local | DynamoDB |
| Puerto API | 5000 | Variable (API Gateway) |
| Puerto Frontend | 8501 | 8501 |

## 🔄 Reiniciar un Servicio Individual

```bash
# Reiniciar solo la API
docker-compose -f docker-compose.local.yml restart api-local

# Reiniciar solo Streamlit
docker-compose -f docker-compose.local.yml restart streamlit-app
```

## 💡 Tips

1. Los datos de DynamoDB se guardan en un volumen Docker llamado `aws_project_dynamodb-data`
2. Para ver los contenedores corriendo: `docker ps`
3. Para entrar a un contenedor: `docker exec -it <container-name> bash`
4. Los logs en tiempo real ayudan a debuggear: `docker-compose -f docker-compose.local.yml logs -f`
