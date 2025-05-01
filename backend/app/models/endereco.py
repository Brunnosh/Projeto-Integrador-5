from sqlalchemy import Column, Integer, String
from app.db import Base

class Endereco(Base):
    __tablename__ = "endereco"

    id = Column(Integer, primary_key=True, index=True)
    cep = Column(String, nullable=False)
    id_estado = Column(Integer, nullable=False)
    bairro = Column(String, nullable=False)
    rua = Column(String, nullable=False)
    numero = Column(Integer, nullable=True)
    complemento = Column(String, nullable=False)