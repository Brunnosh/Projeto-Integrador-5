from jose import jwt, JWTError
from datetime import datetime, timedelta

SECRET_KEY = "sua_chave_secreta_muito_segura"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

def gerar_token_acesso(email: str, expira_em_minutos: int = ACCESS_TOKEN_EXPIRE_MINUTES):
    expira = datetime.utcnow() + timedelta(minutes=expira_em_minutos)
    payload = {"sub": email, "exp": expira}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def validar_token_acesso(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")  # Retorna o e-mail do usuário
    except JWTError:
        return None

def gerar_token_reset(email: str, expira_em_minutos: int = 120):
    expira = datetime.utcnow() + timedelta(minutes=expira_em_minutos)
    payload = {"sub": email, "exp": expira}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def validar_token_reset(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")  # retorna o e-mail
    except JWTError:
        return None