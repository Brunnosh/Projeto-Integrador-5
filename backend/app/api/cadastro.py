from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.models import login as login_model, endereco as endereco_model, dados_usuarios as usuario_model
from app.schemas.cadastro import UsuarioCreate, EnderecoCreate
from app.schemas.update_usuario import NomeUpdate, EmailUpdate, NascimentoUpdate
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

@router.get("/get-usuario")
def obter_dados_usuario(id_login: int , db: Session = Depends(get_db)):
    usuario = db.query(usuario_model.DadosUsuarios).filter_by(id_login=id_login).first()

    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    login = db.query(login_model.Login).filter_by(id=usuario.id_login).first()
    endereco = db.query(endereco_model.Endereco).filter_by(id=usuario.id_endereco).first()

    return {
        "id_login": usuario.id_login,
        "nome": usuario.nome,
        "sobrenome": usuario.sobrenome,
        "data_nascimento": usuario.data_nascimento,
        "email": login.email if login else None,
        "endereco": {
            "id": endereco.id,
            "rua": endereco.rua if endereco else None,
            "numero": endereco.numero if endereco else None,
            "bairro": endereco.bairro if endereco else None,
            "complemento": endereco.complemento if endereco else None,
            "cep": endereco.cep if endereco else None,
            "id_estado": endereco.id_estado if endereco else None,
        }
    }

@router.put("/atualizar-endereco/{id_endereco}")
def atualizar_endereco(id_endereco: int, dados: EnderecoCreate, db: Session = Depends(get_db)):
    endereco = db.query(endereco_model.Endereco).filter_by(id=id_endereco).first()

    if not endereco:
        raise HTTPException(status_code=404, detail="Endereço não encontrado.")

    for campo, valor in dados.dict(exclude_unset=True).items():
        setattr(endereco, campo, valor)

    db.commit()
    db.refresh(endereco)

    return {"mensagem": "Endereço atualizado com sucesso", "endereco": {
        "id": endereco.id,
        "rua": endereco.rua,
        "numero": endereco.numero,
        "bairro": endereco.bairro,
        "complemento": endereco.complemento,
        "cep": endereco.cep,
        "id_estado": endereco.id_estado,
    }}

@router.put("/atualizar-nome/{id_login}")
def atualizar_nome(id_login: int, dados: NomeUpdate, db: Session = Depends(get_db)):
    usuario = db.query(usuario_model.DadosUsuarios).filter_by(id_login=id_login).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    if dados.nome:
        usuario.nome = dados.nome
    if dados.sobrenome:
        usuario.sobrenome = dados.sobrenome

    db.commit()
    db.refresh(usuario)
    return "Nome atualizado com sucesso"

@router.put("/atualizar-email/{id}")
def atualizar_email(id: int, dados: EmailUpdate, db: Session = Depends(get_db)):
    usuario = db.query(login_model.Login).filter_by(id=id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    if dados.email:
        usuario.email = dados.email

    db.commit()
    db.refresh(usuario)
    return "Email atualizado com sucesso"

@router.put("/atualizar-nascimento/{id_login}")
def atualizar_nascimento(id_login: int, dados: NascimentoUpdate, db: Session = Depends(get_db)):
    usuario = db.query(usuario_model.DadosUsuarios).filter_by(id_login=id_login).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    if dados.data_nascimento:
        usuario.data_nascimento = dados.data_nascimento

    db.commit()
    db.refresh(usuario)
    return "Data de nascimento atualizado com sucesso"