from pydantic import BaseModel
from datetime import date

class DespesasCreate(BaseModel):
    id_login: int
    descricao: str
    valor: float
    data_vencimento: date
    recorrencia: bool
    id_categoria: int