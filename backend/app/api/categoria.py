from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models import categoria as categoria_model
from app.schemas.categoria import CategoriaSchema
from app.db import SessionLocal
from typing import List

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/categoria", response_model=List[CategoriaSchema])
def listar_categorias(db: Session = Depends(get_db)):
    categorias = db.query(categoria_model.Categoria).all()
    return categorias