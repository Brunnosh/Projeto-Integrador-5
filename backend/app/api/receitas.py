from fastapi import APIRouter, HTTPException, Depends, Query
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

@router.get("/total-receitas")
def total_receitas(id_login: str = Query(...), db: Session = Depends(get_db)):
    receitas = db.query(Receitas).filter(Receitas.id_login == id_login).all()
    
    if not receitas:
        raise HTTPException(status_code=404, detail="Nenhuma receita encontrada para esse usuário.")

    total = sum(r.valor for r in receitas)
    
    return {
        "id_login": id_login,
        "total_receitas": total
    }