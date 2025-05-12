from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.db import SessionLocal
from app.api import cadastro 
from app.api import login
from app.api import esqueceu_senha
import os

app = FastAPI()
static_dir = os.path.join(os.path.dirname(__file__), "static")
app.mount("/static", StaticFiles(directory=static_dir), name="static")

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