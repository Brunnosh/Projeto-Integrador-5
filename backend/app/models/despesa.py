from sqlalchemy import Column, Integer, Float, String, Date, Boolean, ForeignKey
from app.db import Base

class Despesa(Base):
    __tablename__ = "despesas"

    id = Column(Integer, primary_key=True, index=True)
    id_usuario = Column(Integer, ForeignKey("dados_usuarios.id"), nullable=False)
    valor = Column(Float, nullable=False)
    descricao = Column(String, nullable=False)
    data = Column(Date, nullable=False)
    categoria = Column(String, nullable=False)
    pago = Column(Boolean, default=False)