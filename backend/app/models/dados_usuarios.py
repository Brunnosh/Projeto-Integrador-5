from sqlalchemy import Column, Integer, String, Date
from app.db import Base

class DadosUsuarios(Base):
    __tablename__ = "dados_usuarios"

    id = Column(Integer, primary_key=True, index=True)
    id_login = Column(Integer, unique=True, index=True, nullable=False)
    nome = Column(String, nullable=False)
    sobrenome = Column(String, nullable=False)
    data_nascimento = Column(Date)
    id_endereco = Column(Integer)
