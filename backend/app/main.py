from fastapi import FastAPI
from app.db import SessionLocal
from app.api import cadastro, login, esqueceu_senha, ler_token
app = FastAPI()

app.include_router(cadastro.router)
app.include_router(login.router)
app.include_router(esqueceu_senha.router)
app.include_router(ler_token.router)

@app.get("/hello")
def read_hello():
    db = SessionLocal()
    try:
        return {"message": "Hello! Banco conectado!"}
    finally:
        db.close()