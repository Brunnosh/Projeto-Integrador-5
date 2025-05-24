from pydantic import BaseModel
from datetime import date
from typing import Optional

class FimRecorrenciaUpdate(BaseModel):
    fim_recorrencia: Optional[date]