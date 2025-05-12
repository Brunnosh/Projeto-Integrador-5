from sqlalchemy import Column, Integer, String, Date, Float
from app.db import Base

class Receitas(Base):
    __tablename__ = "receitas"

    id = Column(Integer, primary_key=True, index=True)
    id_login = Column(Integer, unique=True, index=True, nullable=False)
    descricao = Column(String, nullable=False)
    valor = Column(Float, nullable=False)
    data_recebimento = Column(Date)
    id_tipo = Column(Integer)
