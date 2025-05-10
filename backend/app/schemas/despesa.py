from pydantic import BaseModel, Field
from datetime import date
from typing import Optional

class DespesaCreate(BaseModel):
    id_usuario: int
    valor: float = Field(gt=0)
    descricao: str
    data: date
    categoria: str  # alimentacao, transporte, moradia, etc.
    pago: bool = False