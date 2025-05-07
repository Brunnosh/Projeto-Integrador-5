from fastapi import FastAPI
from app.db import SessionLocal
from app.api import cadastro 
from app.api import login
from app.api import esqueceu_senha
from app.api import receita  # Nova importação
from app.api import despesa  # Nova importação

app = FastAPI()

app.include_router(cadastro.router)
app.include_router(login.router)
app.include_router(esqueceu_senha.router)
app.include_router(receita.router)  # Nova rota para receitas
app.include_router(despesa.router)  # Nova rota para despesas

@app.get("/hello")
def read_hello():
    db = SessionLocal()
    try:
        return {"message": "Hello! Banco conectado!"}
    finally:
        db.close()