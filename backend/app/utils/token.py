from jose import jwt, JWTError
from datetime import datetime, timedelta

SECRET_KEY = "sua_chave_secreta_muito_segura"
ALGORITHM = "HS256"

def gerar_token_reset(email: str, expira_em_minutos: int = 30):
    expira = datetime.utcnow() + timedelta(minutes=expira_em_minutos)
    payload = {"sub": email, "exp": expira}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def validar_token_reset(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")  # retorna o e-mail
    except JWTError:
        return None