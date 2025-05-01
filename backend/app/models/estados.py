from sqlalchemy import Column, Integer, String
from app.db import Base

class Estados(Base):
    __tablename__ = "estados"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String, nullable=False)
    sigla = Column(String, nullable=False)