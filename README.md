# Taller — Auditoría y optimización de imágenes

**Curso:** Línea de Énfasis 2
**Sesión:** Clase 2

---

## El Enunciado

Heredaste el despliegue de una API que ya está en producción. Funciona, pero la imagen pesa más de 1 GB, cada despliegue tarda una eternidad y el equipo de seguridad acaba de rechazar el contenedor.

El `Dockerfile` de este repositorio **construye y la aplicación responde**.
Ese no es el problema. El problema es todo lo demás.

Contiene **14 fallas** de tamaño, caché, seguridad y reproducibilidad.
Sabes cuántas son; no sabes cuáles.

---

## Reglas

1. **No se modifica el código fuente.** Solo puedes tocar `Dockerfile` y crear `.dockerignore`.
2. **Prohibido** `--squash` y herramientas de compresión externas. El objetivo es entender las capas, no esconderlas.
3. La imagen base es libre, pero debes justificar tu elección, se responde en la parte B.
4. Documentación oficial permitida. **Asistentes de IA no**: resuelven el ejercicio completo y eliminan el propósito del taller.
5. Antes de tocar nada, corre `make init`: guarda una copia del `Dockerfile` de partida como `Dockerfile.original`. Necesitas ambos para comparar, y a partir de ahí editas únicamente `Dockerfile`.

---

## Metas

| Parámetro | Meta |
| --- | --- |
| Tamaño final | Reducción ≥ 70% |
| Número de capas | ≤ 8 |
| Rebuild tras cambiar una línea de `app/main.py` | < 10 segundos |
| Usuario efectivo | Distinto de root |
| Secretos en el historial de la imagen | Cero |
| **Prueba funcional** | **Debe pasar** |

> **La regla que más pesa:** si `prueba-funcional.sh` no pasa, la reducción de
> tamaño vale cero. Optimizar hasta romper la aplicación no es optimizar.

---

## Parte A

Todo el taller se ejecuta con `make`. Corre `make help` en cualquier momento para ver los comandos disponibles.

### 0. Preparar

```bash
make init
```

Esto crea `Dockerfile.original` a partir del `Dockerfile` con las 14 fallas.
De aquí en adelante **solo editas `Dockerfile`**; `Dockerfile.original` no se toca nunca — es tu línea base para comparar.

### 1. Medir antes de tocar nada

```bash
make base       # construye mi-app:original desde Dockerfile.original
make medir IMAGEN=mi-app:original
```

Anota los números. Sin línea base no hay optimización, solo opinión.

### 2. Diagnosticar

Recorre el `Dockerfile` línea por línea y lista lo que está mal **antes** de corregir nada. Usa `docker history` para ver qué aportó cada capa:

```bash
docker history mi-app:original
docker history --no-trunc mi-app:original | head -40
```

### 3. Optimizar

Edita `Dockerfile` con tus correcciones. Reconstruye y vuelve a medir:

```bash
make build      # construye mi-app:optimizada desde tu Dockerfile
make medir       # mide mi-app:optimizada (es el valor por defecto)
```

### 4. Probar la caché

Cambia una línea cualquiera de `app/main.py`, reconstruye **aprovechando caché**
y mide el tiempo:

```bash
make cache
```

Si tarda más de 10 segundos, el orden de tus capas está mal. Este es el
único parámetro que no se puede aprobar por casualidad.

### 5. Comparar ambas de un solo golpe

```bash
make comparar    # corre medir.sh sobre mi-app:original y mi-app:optimizada
```

---

## Parte B

1. **Justificación por cambio.** Para cada modificación: qué cambiaste, por qué,
   y qué concepto de construcción de imágenes lo sustenta.

2. **El secreto.** El `Dockerfile` guarda una contraseña en un archivo y luego lo
   borra. Responde con evidencia en terminal:
   - ¿La imagen final pesa menos después del `rm`? ¿Por qué?
   - ¿La contraseña sigue siendo recuperable? Demuéstralo.
   - ¿Cuál es la forma correcta de manejar ese secreto?

3. **Comparativa de imágenes base.** Construye la misma aplicación sobre tres bases
   (completa, `slim`, y `alpine` o distroless). Mide tamaño y tiempo de build,
   y argumenta el compromiso. No hay respuesta única: se evalúa el argumento.

4. **Un cambio que intentaste y no funcionó**, con la explicación de por qué.
   Este punto no se puede copiar de ningún lado.

---

## Entregables

Una rama `taller-<apellidos>` con:

```bash
Dockerfile              # tu versión optimizada
Dockerfile.original     # el de partida, sin realizarle cambios
.dockerignore
ENTREGA.md              # plantilla diligenciada
entrega/evidencias/     # capturas o salidas de terminal
```

**Cada número de tu tabla debe ir acompañado del comando que lo produjo.**
Una afirmación técnica sin forma de reproducirla no es una afirmación técnica.

---

## Rúbrica

Ver [`docs/rubrica.md`](docs/rubrica.md). Comandos de apoyo en [`docs/comandos-utiles.md`](docs/comandos-utiles.md).

## Requisitos

Docker 24+, `curl`, `bash`. El primer build es lento.
