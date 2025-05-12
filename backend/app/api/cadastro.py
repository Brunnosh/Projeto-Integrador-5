from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.models import login as login_model, endereco as endereco_model, dados_usuarios as usuario_model
from app.schemas.cadastro import UsuarioCreate
from app.utils import security, token

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/cadastro")
def cadastrar_usuario(dados: UsuarioCreate, db: Session = Depends(get_db)):
    if db.query(login_model.Login).filter_by(email=dados.email).first():
        raise HTTPException(status_code=400, detail="E-mail já cadastrado.")

    login = login_model.Login(
        email=dados.email,
        senha=security.hash_senha(dados.senha)
    )
    db.add(login)
    db.commit()
    db.refresh(login)

    endereco = endereco_model.Endereco(
        cep=dados.endereco.cep,
        id_estado=dados.endereco.id_estado,
        bairro=dados.endereco.bairro,
        rua=dados.endereco.rua,
        numero=dados.endereco.numero,
        complemento=dados.endereco.complemento
    )
    db.add(endereco)
    db.commit()
    db.refresh(endereco)

    usuario = usuario_model.DadosUsuarios(
        id_login=login.id,
        nome=dados.nome,
        sobrenome=dados.sobrenome,
        data_nascimento=dados.data_nascimento,
        id_endereco=endereco.id
    )
    db.add(usuario)
    db.commit()

    access_token = token.gerar_token_acesso(dados.email)

    return {"access_token": access_token, "token_type": "bearer"}
