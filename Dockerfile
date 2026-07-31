# ================================================================
#  Dockerfile optimizado - 8 capas
# ================================================================

FROM python:3.12-slim AS builder

WORKDIR /app

COPY app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# ---- Imagen final ----
FROM python:3.12-slim

# Crea usuario, instala curl y limpia en UNA capa
RUN adduser --disabled-password --gecos '' appuser && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia todo /usr/local desde builder en una sola capa
COPY --from=builder --chown=appuser:appuser /usr/local /usr/local

# Copia el código de la app
COPY --chown=appuser:appuser app/ app/

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]