from pydantic import BaseModel, Field
from datetime import date
from typing import Optional

class ReceitaCreate(BaseModel):
    id_usuario: int
    valor: float = Field(gt=0)
    descricao: str
    data: date
    tipo: str  # salario, freelance, investimento, etc.