from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import extract
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
        fim_recorrencia=dados.fim_recorrencia,
        id_categoria = dados.id_categoria
    )
    db.add(nova_despesa)
    db.commit()
    db.refresh(nova_despesa)
    return {"mensagem": "Despesa inserida com sucesso", "despesa_id": nova_despesa.id}

@router.get("/total-despesas")
def total_despesas(
    id_login: str = Query(...),
    mes: int = Query(..., ge=1, le=12),
    ano: int = Query(..., ge=1900),
    db: Session = Depends(get_db)
):
    despesas = (
        db.query(Despesas)
        .filter(
            Despesas.id_login == id_login,
            extract("month", Despesas.data_vencimento) == mes,
            extract("year", Despesas.data_vencimento) == ano
        )
        .all()
    )

    total = sum(r.valor for r in despesas) if despesas else 0

    return {
        "id_login": id_login,
        "mes": mes,
        "ano": ano,
        "total": total
    }