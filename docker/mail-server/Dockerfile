FROM python:3.6.3-slim

STOPSIGNAL SIGTERM

CMD ["python", "-m", "smtpd", "-n", "-c", "DebuggingServer", "localhost:1025"]
