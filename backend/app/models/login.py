from sqlalchemy import Column, Integer, String
from app.db import Base

class Login(Base):
    __tablename__ = "login"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    senha = Column(String, nullable=False)
