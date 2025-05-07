from sqlalchemy import Column, Integer, Float, String, Date, ForeignKey
from app.db import Base

class Receita(Base):
    __tablename__ = "receitas"

    id = Column(Integer, primary_key=True, index=True)
    id_usuario = Column(Integer, ForeignKey("dados_usuarios.id"), nullable=False)
    valor = Column(Float, nullable=False)
    descricao = Column(String, nullable=False)
    data = Column(Date, nullable=False)
    tipo = Column(String, nullable=False)