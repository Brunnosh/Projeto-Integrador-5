from datetime import date
from fastapi import APIRouter, Depends, Query
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
    data_consulta = date(ano, mes, 1)
    receitas = (
        db.query(Receitas)
        .filter(Receitas.id_login == id_login)
        .all()
    )

    total = 0.0

    for r in receitas:
            data_base = r.data_recebimento.replace(day=1)
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

@router.get("/detalhes-receitas")
def receitas_detalhadas(id_login: str, mes: int, ano: int, db: Session = Depends(get_db)):
    data_consulta = date(ano, mes, 1)
    receitas = db.query(Receitas).filter(Receitas.id_login == id_login).all()

    resultado = []
    for r in receitas:
        data_base = r.data_recebimento.replace(day=1)
        fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

        if not r.recorrencia and data_base == data_consulta:
            resultado.append({
                "id": r.id,
                "descricao": r.descricao,
                "valor": r.valor,
                "data_recebimento": r.data_recebimento,
                "recorrencia": r.recorrencia,
                "fim_recorrencia": None
            })
        elif r.recorrencia and (data_consulta >= data_base and (fim is None or data_consulta <= fim)):
            resultado.append({
                "id": r.id,
                "descricao": r.descricao,
                "valor": r.valor,
                "data_recebimento": r.data_recebimento,
                "recorrencia": r.recorrencia,
                "fim_recorrencia": r.fim_recorrencia
            })

    return resultado