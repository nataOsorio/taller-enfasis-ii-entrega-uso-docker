#!/usr/bin/env bash
# ------------------------------------------------------------
# medir.sh — recolecta las metricas del taller para una imagen.
#
#   Uso:  ./scripts/medir.sh <nombre-imagen>
#   Ej.:  ./scripts/medir.sh mi-app:optimizada
#
# Imprime una fila lista para pegar en ENTREGA.md.
# ------------------------------------------------------------
set -uo pipefail

IMAGEN="${1:-}"
if [ -z "$IMAGEN" ]; then
  echo "Uso: $0 <nombre-imagen>" >&2
  exit 1
fi

if ! docker image inspect "$IMAGEN" >/dev/null 2>&1; then
  echo "ERROR: la imagen '$IMAGEN' no existe. Construyela primero." >&2
  exit 1
fi

echo "=============================================="
echo " Midiendo: $IMAGEN"
echo "=============================================="

# --- Tamano ---------------------------------------------------
BYTES=$(docker image inspect --format '{{.Size}}' "$IMAGEN")
MB=$(awk -v b="$BYTES" 'BEGIN { printf "%.1f", b/1024/1024 }')
echo "Tamano.................: ${MB} MB"

# --- Capas ----------------------------------------------------
CAPAS=$(docker image inspect --format '{{len .RootFS.Layers}}' "$IMAGEN")
echo "Capas..................: ${CAPAS}"

# --- Usuario --------------------------------------------------
USUARIO=$(docker image inspect --format '{{.Config.User}}' "$IMAGEN")
if [ -z "$USUARIO" ]; then
  USUARIO="root (NO DEFINIDO)"
fi
echo "Usuario configurado....: ${USUARIO}"

# --- Healthcheck ----------------------------------------------
HC=$(docker image inspect --format '{{if .Config.Healthcheck}}si{{else}}no{{end}}' "$IMAGEN")
echo "Healthcheck............: ${HC}"

# --- Forma de CMD ---------------------------------------------
CMD_RAW=$(docker image inspect --format '{{json .Config.Cmd}}' "$IMAGEN")
if echo "$CMD_RAW" | grep -q '"/bin/sh","-c"'; then
  FORMA="shell (revisar manejo de senales)"
else
  FORMA="exec"
fi
echo "Forma de CMD...........: ${FORMA}"

# --- Secretos en el historial ---------------------------------
HIST=$(docker history --no-trunc --format '{{.CreatedBy}}' "$IMAGEN" 2>/dev/null)
CFG=$(docker image inspect --format '{{json .Config.Env}}' "$IMAGEN")
FUGAS=0
if echo "$HIST" | grep -qiE 'Sup3rS3cret|DB_PASSWORD='; then
  FUGAS=$((FUGAS+1))
fi
if echo "$CFG" | grep -qiE 'Sup3rS3cret|PASSWORD'; then
  FUGAS=$((FUGAS+1))
fi
if [ "$FUGAS" -gt 0 ]; then
  echo "Secretos expuestos.....: SI  <-- revisa docker history y docker inspect"
else
  echo "Secretos expuestos.....: no"
fi

# --- Prueba funcional -----------------------------------------
if [ -x "$(dirname "$0")/prueba-funcional.sh" ]; then
  if "$(dirname "$0")/prueba-funcional.sh" "$IMAGEN" >/dev/null 2>&1; then
    FUNCIONA="PASA"
  else
    FUNCIONA="FALLA  <-- la reduccion no cuenta"
  fi
else
  FUNCIONA="(script no encontrado)"
fi
echo "Prueba funcional.......: ${FUNCIONA}"

echo
echo "Fila para ENTREGA.md:"
echo "| ${IMAGEN} | ${MB} MB | ${CAPAS} | ${USUARIO} | ${FUNCIONA} |"
