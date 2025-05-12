from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.schemas.login import LoginRequest
from app.utils import security, token
from app.db import SessionLocal
from app.models import login as login_model

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/login")
def login(dados: LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(login_model.Login).filter_by(email=dados.email).first()

    if not usuario or not security.verificar_senha(dados.senha, usuario.senha):
        raise HTTPException(status_code=401, detail="Email ou senha inválidos")

    access_token = token.gerar_token_acesso(dados.email)

    return {"access_token": access_token, "token_type": "bearer"}