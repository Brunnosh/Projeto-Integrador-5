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
                "id": r.id,
                "descricao": r.descricao,
                "valor": r.valor,
                "data_vencimento": r.data_vencimento,
                "recorrencia": r.recorrencia,
                "fim_recorrencia": None,
                "id_categoria": r.id_categoria
            })
        elif r.recorrencia and (data_consulta >= data_base and (fim is None or data_consulta <= fim)):
            resultado.append({
                "id": r.id,
                "descricao": r.descricao,
                "valor": r.valor,
                "data_vencimento": r.data_vencimento,
                "recorrencia": r.recorrencia,
                "fim_recorrencia": r.fim_recorrencia,
                "id_categoria": r.id_categoria
            })

    return resultado

@router.delete("/delete-despesa/{id}")
def deletar_despesa(id: int, id_login: str, db: Session = Depends(get_db)):
    despesa = db.query(Despesas).filter(Despesas.id == id).first()

    if not despesa:
        raise HTTPException(status_code=404, detail="Despesa não encontrada")

    if str(despesa.id_login).strip() != str(id_login).strip():
        raise HTTPException(status_code=403, detail="Você não tem permissão para excluir esta despesa.")

    db.delete(despesa)
    db.commit()

    return {"mensagem": "Despesa excluída com sucesso", "id_despesa": id}


@router.put("/update-despesa/{id}")
def atualizar_despesa(
    id: int,
    id_login: str,
    dados: DespesasCreate,
    db: Session = Depends(get_db)
):
    despesa = db.query(Despesas).filter(Despesas.id == id).first()

    if not despesa:
        raise HTTPException(status_code=404, detail="Despesa não encontrada")

    if str(despesa.id_login).strip() != str(id_login).strip():
        raise HTTPException(status_code=403, detail="Você não tem permissão para editar esta despesa.")

    despesa.descricao = dados.descricao
    despesa.valor = dados.valor
    despesa.data_vencimento = dados.data_vencimento
    despesa.recorrencia = dados.recorrencia
    despesa.fim_recorrencia = dados.fim_recorrencia
    despesa.id_categoria = dados.id_categoria

    db.commit()
    db.refresh(despesa)

    return {"mensagem": "Despesa atualizada com sucesso", "id_despesa": despesa.id}

@router.get("/unica-despesa/{id}")
def obter_despesa(
    id: int ,
    id_login: str ,
    db: Session = Depends(get_db)
):
    despesa = db.query(Despesas).filter(Despesas.id == id).first()

    if not despesa:
        raise HTTPException(status_code=404, detail="Despesa não encontrada")

    if str(despesa.id_login).strip() != str(id_login).strip():
        raise HTTPException(status_code=403, detail="Acesso não autorizado à despesa")

    return {
        "id": despesa.id,
        "descricao": despesa.descricao,
        "valor": despesa.valor,
        "data_vencimento": despesa.data_vencimento,
        "recorrencia": despesa.recorrencia,
        "fim_recorrencia": despesa.fim_recorrencia,
        "id_categoria": despesa.id_categoria,
    }