from pydantic import BaseModel, EmailStr

class EsqueciSenhaRequest(BaseModel):
    email: EmailStr

class RedefinirSenhaRequest(BaseModel):
    token: str
    nova_senha: str