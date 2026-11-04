FROM python:3.11-slim

WORKDIR /app

# psycopg2-binary ya trae el binario compilado, no hace falta gcc/libpq-dev.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
