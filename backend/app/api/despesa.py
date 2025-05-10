from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.models.despesa import Despesa
from app.models.dados_usuarios import DadosUsuarios
from app.schemas.despesa import DespesaCreate

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/despesas")
def criar_despesa(dados: DespesaCreate, db: Session = Depends(get_db)):
    # Verifica se o usuário existe
    usuario = db.query(DadosUsuarios).filter(DadosUsuarios.id == dados.id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")
    
    # Cria nova despesa
    nova_despesa = Despesa(
        id_usuario=dados.id_usuario,
        valor=dados.valor,
        descricao=dados.descricao,
        data=dados.data,
        categoria=dados.categoria,
        pago=dados.pago
    )
    
    db.add(nova_despesa)
    db.commit()
    db.refresh(nova_despesa)
    
    return {"mensagem": "Despesa registrada com sucesso!", "id": nova_despesa.id}

@router.get("/despesas/{id_usuario}")
def listar_despesas(id_usuario: int, db: Session = Depends(get_db)):
    # Verifica se o usuário existe
    usuario = db.query(DadosUsuarios).filter(DadosUsuarios.id == id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")
    
    # Busca todas as despesas do usuário
    despesas = db.query(Despesa).filter(Despesa.id_usuario == id_usuario).all()
    
    return despesas