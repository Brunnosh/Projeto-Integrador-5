from fastapi import FastAPI
from app.db import SessionLocal
from app.api import cadastro 
from app.api import login

app = FastAPI()

app.include_router(cadastro.router)

app.include_router(login.router)

@app.get("/hello")
def read_hello():
    db = SessionLocal()
    try:
        return {"message": "Hello! Banco conectado!"}
    finally:
        db.close()