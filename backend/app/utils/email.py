import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email_validator import validate_email, EmailNotValidError
from typing import Optional

def enviar_email(destinatario: str, assunto: str, corpo: str, smtp_host: str, smtp_port: int, smtp_user: str, smtp_password: str):
    try:
        validate_email(destinatario)

        server = smtplib.SMTP(smtp_host, smtp_port)
        server.starttls()

        server.login(smtp_user, smtp_password)

        msg = MIMEMultipart()
        msg['From'] = smtp_user
        msg['To'] = destinatario
        msg['Subject'] = assunto

        msg.attach(MIMEText(corpo, 'plain'))

        server.sendmail(smtp_user, destinatario, msg.as_string())
        server.quit()

        print(f"E-mail enviado para {destinatario}")
    except EmailNotValidError as e:
        print(f"Erro na validação do e-mail: {e}")
    except Exception as e:
        print(f"Erro ao enviar o e-mail: {e}")