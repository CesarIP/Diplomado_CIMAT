from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def home():
    return {"message": "Hola, primer proyecto con AWS y FastAPI"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/saludo/{nombre}")
def saludo(nombre: str):
    return {"message": f"Hola, {nombre}. Bienvenido a FastAPI con AWS!"}

