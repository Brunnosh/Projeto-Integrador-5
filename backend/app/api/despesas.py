from datetime import date
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
    data_consulta = date(ano, mes, 1)
    despesas = (
        db.query(Despesas)
        .filter(Despesas.id_login == id_login)
        .all()
    )

    total = 0.0

    for r in despesas:
        data_base = r.data_vencimento.replace(day=1)
        fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

        if not r.recorrencia:
            # Receita normal
            if data_base == data_consulta:
                total += r.valor
        else:
            # Receita recorrente
            if data_consulta >= data_base and (fim is None or data_consulta <= fim):
                total += r.valor

    return {
        "id_login": id_login,
        "mes": mes,
        "ano": ano,
        "total": total
    }

@router.get("/detalhes-despesas")
def despesas_detalhadas(id_login: str, mes: int, ano: int, db: Session = Depends(get_db)):
    data_consulta = date(ano, mes, 1)
    despesas = db.query(Despesas).filter(Despesas.id_login == id_login).all()

    resultado = []
    for r in despesas:
        data_base = r.data_vencimento.replace(day=1)
        fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

        if not r.recorrencia and data_base == data_consulta:
            resultado.append({
                "descricao": r.descricao,
                "valor": r.valor,
                "data_vencimento": r.data_vencimento,
                "recorrencia": r.recorrencia,
                "fim_recorrencia": None
            })
        elif r.recorrencia and (data_consulta >= data_base and (fim is None or data_consulta <= fim)):
            resultado.append({
                "descricao": r.descricao,
                "valor": r.valor,
                "data_vencimento": r.data_vencimento,
                "recorrencia": r.recorrencia,
                "fim_recorrencia": r.fim_recorrencia
            })

    return resultado