import smtplib
from email.mime.text import MIMEText

SMTP_USER = "AKIAXZLAHVPEWJ2YOKR7"
SMTP_PASS = "BDzS310gE5pub4TzzVdoG4DgijlPPFYxMy0GyIIDKw4h"
SMTP_HOST = "email-smtp.us-east-1.amazonaws.com"
SMTP_PORT = 587

FROM = "admin@sree84s.site"
TO = "sreekanthpaleti1999@gmail.com"  # must be verified if SES is still sandbox

msg = MIMEText("Test email from AWS SES via SMTP. If you see this, SES works.")
msg["Subject"] = "SES SMTP Test - sree84s.site"
msg["From"] = FROM
msg["To"] = TO

with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
    server.starttls()
    server.login(SMTP_USER, SMTP_PASS)
    server.sendmail(FROM, [TO], msg.as_string())

print("Email sent")
