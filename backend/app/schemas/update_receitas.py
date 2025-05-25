from pydantic import BaseModel
from typing import Optional
from datetime import date

class ReceitaUpdate(BaseModel):
    descricao: str
    valor: float
    data_recebimento: date
    recorrencia: bool
    fim_recorrencia: Optional[date] = None