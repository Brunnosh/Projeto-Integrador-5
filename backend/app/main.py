from fastapi import FastAPI
from app.db import SessionLocal
from app.api import cadastro 
from app.api import login
from app.api import esqueceu_senha

app = FastAPI()

app.include_router(cadastro.router)

app.include_router(login.router)

app.include_router(esqueceu_senha.router)

@app.get("/hello")
def read_hello():
    db = SessionLocal()
    try:
        return {"message": "Hello! Banco conectado!"}
    finally:
        db.close()