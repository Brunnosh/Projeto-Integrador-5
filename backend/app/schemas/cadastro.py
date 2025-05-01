from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional

class EnderecoCreate(BaseModel):
    cep: str
    id_estado: int
    bairro: str
    rua: str
    numero: Optional[str] = None
    complemento: Optional[str] = None

class UsuarioCreate(BaseModel):
    email: EmailStr
    senha: str = Field(min_length=6)
    confirmar_senha: str
    nome: str
    sobrenome: str
    data_nascimento: str
    endereco: EnderecoCreate

    @validator("confirmar_senha")
    def senhas_devem_bater(cls, v, values, **kwargs):
        if 'senha' in values and v != values['senha']:
            raise ValueError("As senhas não coincidem")
        return v
