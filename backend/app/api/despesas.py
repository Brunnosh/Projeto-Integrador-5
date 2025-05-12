from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.models.despesas import Despesas
from app.schemas.despesas import DespesasCreate

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/inserir-despesa")
def inserir_despesa(dados: DespesasCreate, db: Session = Depends(get_db)):
    nova_despesa = Despesas(
        id_login=dados.id_login,
        descricao=dados.descricao,
        valor=dados.valor,
        data_vencimento=dados.data_vencimento,
        recorrencia=dados.recorrencia,
        id_categoria = dados.id_categoria
    )
    db.add(nova_despesa)
    db.commit()
    db.refresh(nova_despesa)
    return {"mensagem": "Despesa inserida com sucesso", "despesa_id": nova_despesa.id}