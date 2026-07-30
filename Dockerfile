# ============================================================
#  Dockerfile de partida — Taller
#
#  Este archivo funciona: construye una imagen y la aplicación
#  responde. Pero contiene 14 fallas de tamano, cache, seguridad
#  y reproducibilidad.
#
#  Tu trabajo es encontrarlas y corregirlas SIN tocar el codigo
#  fuente de la aplicacion.
#
#  No borres este archivo
# ============================================================

FROM python:3.12

WORKDIR /app

COPY . .

RUN apt-get update && apt-get install -y build-essential curl vim git postgresql-client

RUN pip install --upgrade pip

RUN pip install -r app/requirements.txt

RUN pip install pytest black flake8 ipython httpx

ENV DB_PASSWORD=Sup3rS3cret2026

RUN echo "$DB_PASSWORD" > /app/.dbpass

RUN rm /app/.dbpass

EXPOSE 8000

CMD python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
