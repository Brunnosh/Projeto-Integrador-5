from pydantic import BaseModel
from datetime import date
from typing import Optional

class NomeUpdate(BaseModel):
    nome: Optional[str] = None
    sobrenome: Optional[str] = None

class EmailUpdate(BaseModel):
    email: Optional[str] = None

class NascimentoUpdate(BaseModel):
    data_nascimento: Optional[date] = None