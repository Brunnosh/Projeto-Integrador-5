from pydantic import BaseModel

class EstadosSchema(BaseModel):
    id: int
    nome: str
    sigla: str

    class Config:
        from_attributes = True
