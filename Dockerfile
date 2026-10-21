FROM python:3.12-slim

WORKDIR /app

# Install Python dependencies first (layer-cache friendly)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source and pre-built UI
COPY server/ ./server/
COPY dist/ ./dist/
COPY template.env ./

ENV PYTHONPATH=/app
ENV UI_PORT=8080

EXPOSE 8080

CMD ["python3", "server/app.py"]
