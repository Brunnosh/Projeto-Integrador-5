import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

# Carrega as variáveis de ambiente do .env
load_dotenv()

# Pega a variável DATABASE_URL do ambiente
DATABASE_URL = os.getenv("DATABASE_URL")

# Cria o engine de conexão
engine = create_engine(DATABASE_URL)

# Cria uma sessão para interagir com o banco
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()