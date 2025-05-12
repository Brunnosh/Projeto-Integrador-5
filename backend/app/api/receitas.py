from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db import SessionLocal
from app.models.receitas import Receitas
from app.schemas.receitas import ReceitaCreate

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/inserir-receita")
def inserir_receita(dados: ReceitaCreate, db: Session = Depends(get_db)):
    nova_receita = Receitas(
        id_login=dados.id_login,
        descricao=dados.descricao,
        valor=dados.valor,
        data_recebimento=dados.data_recebimento,
        recorrencia=dados.recorrencia
    )
    db.add(nova_receita)
    db.commit()
    db.refresh(nova_receita)
    return {"mensagem": "Receita inserida com sucesso", "receita_id": nova_receita.id}