from sqlalchemy import Column, Integer, String, Date, Float, Boolean
from app.db import Base

class Despesas(Base):
    __tablename__ = "despesas"

    id = Column(Integer, primary_key=True, index=True)
    id_login = Column(Integer, unique=True, index=True, nullable=False)
    descricao = Column(String, nullable=False)
    valor = Column(Float, nullable=False)
    data_vencimento = Column(Date, nullable=False)
    recorrencia = Column(Boolean, nullable=False)
    id_categoria = Column(Integer, nullable=False)
