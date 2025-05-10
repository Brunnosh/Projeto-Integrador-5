from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.models.receita import Receita
from app.models.dados_usuarios import DadosUsuarios
from app.schemas.receita import ReceitaCreate

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/receitas")
def criar_receita(dados: ReceitaCreate, db: Session = Depends(get_db)):
    # se o usuário existe
    usuario = db.query(DadosUsuarios).filter(DadosUsuarios.id == dados.id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")
    
    # Cria nova receita
    nova_receita = Receita(
        id_usuario=dados.id_usuario,
        valor=dados.valor,
        descricao=dados.descricao,
        data=dados.data,
        tipo=dados.tipo
    )
    
    db.add(nova_receita)
    db.commit()
    db.refresh(nova_receita)
    
    return {"mensagem": "Receita registrada com sucesso!", "id": nova_receita.id}

@router.get("/receitas/{id_usuario}")
def listar_receitas(id_usuario: int, db: Session = Depends(get_db)):
    # se o usuário existe
    usuario = db.query(DadosUsuarios).filter(DadosUsuarios.id == id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")
    
    # Busca todas as receitas do usuário
    receitas = db.query(Receita).filter(Receita.id_usuario == id_usuario).all()
    
    return receitas