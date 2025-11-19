# Dockerfile para AWS Lambda
FROM public.ecr.aws/lambda/python:3.11

# Copiar requirements
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de la función
COPY app.py ${LAMBDA_TASK_ROOT}

# Comando para ejecutar la Lambda
CMD ["app.lambda_handler"]
