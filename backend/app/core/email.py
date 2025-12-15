from email.message import EmailMessage

import aiosmtplib

from config import settings


async def send_email(to_email: str, subject: str, body: str):
    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        print("SMTP credentials not set. Email not sent.")
        return

    message = EmailMessage()
    message["From"] = settings.SMTP_USER
    message["To"] = to_email
    message["Subject"] = subject
    message.set_content(body)

    try:
        await aiosmtplib.send(
            message,
            hostname=settings.SMTP_HOST,
            port=settings.SMTP_PORT,
            username=settings.SMTP_USER,
            password=settings.SMTP_PASSWORD,
            use_tls=True,
        )
    except Exception as e:
        print("failed to send email")
