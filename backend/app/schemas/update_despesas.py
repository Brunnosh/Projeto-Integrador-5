from pydantic import BaseModel
from typing import Optional
from datetime import date

class DespesasUpdate(BaseModel):
    descricao: str
    valor: float
    data_vencimento: date
    recorrencia: bool
    id_categoria: int
    fim_recorrencia: Optional[date] = None