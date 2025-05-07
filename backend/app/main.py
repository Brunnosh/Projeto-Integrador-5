from fastapi import FastAPI
from app.db import SessionLocal, engine
from app.api import cadastro 
from app.api import login
from app.api import esqueceu_senha
from app.models import login as login_model, endereco as endereco_model, dados_usuarios as usuario_model

app = FastAPI()

print("Verificando e criando tabelas, se não existirem...")
usuario_model.Base.metadata.create_all(bind=engine)
login_model.Base.metadata.create_all(bind=engine)
endereco_model.Base.metadata.create_all(bind=engine)

app.include_router(cadastro.router)
app.include_router(login.router)
app.include_router(esqueceu_senha.router)

@app.get("/hello")
def read_hello():
    db = SessionLocal()
    try:
        return {"message": "Hello! Banco conectado!"}
    finally:
        print("olar")
        