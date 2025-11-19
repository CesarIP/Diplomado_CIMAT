FROM python:3.11-slim

WORKDIR /app

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código
COPY lambda_handler.py .
COPY app.py .

# Exponer puerto
EXPOSE 5000

# Ejecutar Flask app
CMD ["python", "app.py"]
