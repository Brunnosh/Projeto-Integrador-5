from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.schemas.esqueceu_senha import EsqueciSenhaRequest, RedefinirSenhaRequest
from app.models.login import Login
from app.utils import email, security
from app.utils.token import gerar_token_reset, validar_token_reset
from dotenv import load_dotenv
import os

load_dotenv()  # Carrega o .env

SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT"))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/esqueci-senha")
def esqueci_senha(dados: EsqueciSenhaRequest, db: Session = Depends(get_db)):
    usuario = db.query(Login).filter_by(email=dados.email).first()
    if not usuario:
        return {"mensagem": "Se o e-mail já estiver registrado, enviaremos um link para redefinir a senha."}

    token = gerar_token_reset(usuario.email)
    
    # Aqui você enviaria um e-mail com o link contendo o token
    print(f"Link de redefinição: http://localhost:8000/resetar-senha?token={token}")
    link_redefinicao = f"http://localhost:8000/resetar-senha?token={token}"
    corpo_email = f"Olá,\n\nClique no link abaixo para redefinir sua senha:\n{link_redefinicao}\n\nSe você não solicitou isso, ignore este e-mail."

    email.enviar_email(dados.email, "Redefinição de Senha", corpo_email, SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD)

    return {"mensagem": "Se o e-mail já estiver registrado, enviaremos um link para redefinir a senha."}

@router.post("/resetar-senha")
def resetar_senha(dados: RedefinirSenhaRequest, db: Session = Depends(get_db)):
    email = validar_token_reset(dados.token)
    if not email:
        raise HTTPException(status_code=400, detail="Token inválido ou expirado.")

    usuario = db.query(Login).filter_by(email=email).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    usuario.senha = security.hash_senha(dados.nova_senha)
    db.commit()

    return {"mensagem": "Senha redefinida com sucesso"}
