from pydantic import BaseModel

class CategoriaSchema(BaseModel):
    id: int
    nome: str

    class Config:
        from_attributes = True
