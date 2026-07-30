#!/usr/bin/env bash
# ------------------------------------------------------------
# prueba-funcional.sh — verifica que la imagen sigue sirviendo.
#
#   Uso:  ./scripts/prueba-funcional.sh <nombre-imagen>
#
# Regla del taller: si esta prueba no pasa, la reduccion de
# tamano vale cero. Optimizar hasta romper no es optimizar.
# ------------------------------------------------------------
set -uo pipefail

IMAGEN="${1:-}"
[ -z "$IMAGEN" ] && { echo "Uso: $0 <nombre-imagen>" >&2; exit 1; }

NOMBRE="prueba-taller02-$$"
PUERTO=18000

limpiar() { docker rm -f "$NOMBRE" >/dev/null 2>&1 || true; }
trap limpiar EXIT

docker run -d --name "$NOMBRE" -p "${PUERTO}:8000" "$IMAGEN" >/dev/null || {
  echo "FALLA: el contenedor no arranco"; exit 1; }

# Esperar hasta 30 s a que la API responda
for _ in $(seq 1 30); do
  if curl -fsS "http://localhost:${PUERTO}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! curl -fsS "http://localhost:${PUERTO}/health" | grep -q '"status":"ok"'; then
  echo "FALLA: /health no respondio correctamente"; exit 1
fi

CREADO=$(curl -fsS -X POST "http://localhost:${PUERTO}/items" \
  -H 'Content-Type: application/json' \
  -d '{"nombre":"monitor","cantidad":2}' 2>/dev/null)

echo "$CREADO" | grep -q '"nombre":"monitor"' || {
  echo "FALLA: no se pudo crear un item"; exit 1; }

curl -fsS "http://localhost:${PUERTO}/items" | grep -q 'monitor' || {
  echo "FALLA: el item creado no aparece en el listado"; exit 1; }

echo "PASA: la aplicacion responde correctamente"
