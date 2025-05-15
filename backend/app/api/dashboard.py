from fastapi import APIRouter, Query, Depends
from sqlalchemy.orm import Session
from datetime import date
from app.db import SessionLocal
from app.models.despesas import Despesas
from app.models.categoria import Categoria
from app.schemas import categoria
from collections import defaultdict


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/contagem-despesas-por-dia-vencimento")
def contagem_despesas_por_dia(
    id_login: str = Query(...),
    mes: int = Query(..., ge=1, le=12),
    ano: int = Query(..., ge=1900),
    db: Session = Depends(get_db)
):
    data_consulta = date(ano, mes, 1)
    despesas = db.query(Despesas).filter(Despesas.id_login == id_login).all()

    contagem_por_dia = {}

    for r in despesas:
        data_base = r.data_vencimento.replace(day=1)
        fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

        if not r.recorrencia and data_base == data_consulta:
            dia = r.data_vencimento.day
            contagem_por_dia[dia] = contagem_por_dia.get(dia, 0) + 1
        elif r.recorrencia and (data_consulta >= data_base and (fim is None or data_consulta <= fim)):
            dia = r.data_vencimento.day
            contagem_por_dia[dia] = contagem_por_dia.get(dia, 0) + 1

    resultado = [{"dia": dia, "quantidade": quantidade} for dia, quantidade in sorted(contagem_por_dia.items())]
    return resultado

@router.get("/contagem-despesas-por-categoria")
def contagem_despesas_por_categoria(id_login: str, mes: int, ano: int, db: Session = Depends(get_db)):
    # Reutiliza a lógica do endpoint de despesas detalhadas
    data_consulta = date(ano, mes, 1)
    despesas = db.query(Despesas).filter(Despesas.id_login == id_login).all()

    despesas_filtradas = []
    for r in despesas:
        data_base = r.data_vencimento.replace(day=1)
        fim = r.fim_recorrencia.replace(day=1) if r.fim_recorrencia else None

        if not r.recorrencia and data_base == data_consulta:
            despesas_filtradas.append(r)
        elif r.recorrencia and (data_consulta >= data_base and (fim is None or data_consulta <= fim)):
            despesas_filtradas.append(r)

    # Carrega as categorias
    categorias = db.query(Categoria).all()
    categorias_dict = {c.id: c.nome for c in categorias}

    # Conta as despesas por categoria
    contagem = defaultdict(int)
    for despesa in despesas_filtradas:
        nome_categoria = categorias_dict.get(despesa.id_categoria, "Outros")
        contagem[nome_categoria] += 1

    # Retorna o resultado como lista de dicionários
    return [{"categoria": nome, "quantidade": qtd} for nome, qtd in contagem.items()]