from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import extract
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
        recorrencia=dados.recorrencia,
        fim_recorrencia=dados.fim_recorrencia
    )
    db.add(nova_receita)
    db.commit()
    db.refresh(nova_receita)
    return {"mensagem": "Receita inserida com sucesso", "receita_id": nova_receita.id}

@router.get("/total-receitas")
def total_receitas(
    id_login: str = Query(...),
    mes: int = Query(..., ge=1, le=12),
    ano: int = Query(..., ge=1900),
    db: Session = Depends(get_db)
):
    receitas = (
        db.query(Receitas)
        .filter(
            Receitas.id_login == id_login,
            extract("month", Receitas.data_recebimento) == mes,
            extract("year", Receitas.data_recebimento) == ano
        )
        .all()
    )

    total = sum(r.valor for r in receitas) if receitas else 0

    return {
        "id_login": id_login,
        "mes": mes,
        "ano": ano,
        "total": total
    }