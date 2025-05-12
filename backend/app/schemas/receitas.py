from pydantic import BaseModel
from datetime import date

class ReceitaCreate(BaseModel):
    id_login: int
    descricao: str
    valor: float
    data_recebimento: date
    id_tipo: int