from fastapi import FastAPI # type: ignore
from db import SessionLocal

app = FastAPI()

@app.get("/hello")
def read_hello():
    
    db = SessionLocal()
    try:
        
        return {"message": "Hello, MyWallet! Banco conectado!"}
    finally:
        db.close()
