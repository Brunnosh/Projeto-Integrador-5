from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models.estados import Estados
from app.schemas.estados import EstadosSchema
from app.db import SessionLocal
from typing import List

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/estados", response_model=List[EstadosSchema])
def listar_estados(db: Session = Depends(get_db)):
    lista_estados = db.query(Estados).all()
    return lista_estados
