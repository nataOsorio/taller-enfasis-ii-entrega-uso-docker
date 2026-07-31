# Entrega — Taller

**Estudiante:** [Natalia Muñoz Osorio]
**Fecha:** 2026-07-31
**Rama:** taller-[muñoz-osorio]

---

## 1. Tabla comparativa

| Métrica | Original | Optimizada | Mejora | Comando usado |
|---|---|---|---|---|
| Tamaño | 481.3 MB | 71.1 MB | **85.2%** | `docker image inspect --format '{{.Size}}'` |
| Capas | 15 | 8 | – | `docker image inspect --format '{{len .RootFS.Layers}}'` |
| Build en frío | ~2 min | ~1 min | – | `time docker build --no-cache` |
| Rebuild tras cambio de código | – | < 10 s | – | `time docker build` |
| Usuario efectivo | root | appuser | – | `docker image inspect --format '{{.Config.User}}'` |
| Prueba funcional | PASA | PASA | – | `./scripts/prueba-funcional.sh` |

---

## 2. Fallas identificadas

Identifique **14** fallas.

| # | Falla | Línea | Corrección aplicada | Concepto |
|---|---|---|---|---|
| 1 | Imagen base pesada (`python:3.12`) | `FROM python:3.12` | Cambiar a `python:3.12-slim` | Capas: elegir base más ligera reduce tamaño global. |
| 2 | Copia de todo el contexto sin `.dockerignore` | `COPY . .` | Añadir `.dockerignore` y copiar solo `app/` y `requirements.txt` | Contexto: evitar copiar archivos innecesarios. |
| 3 | Instalación de paquetes de construcción innecesarios | `RUN apt-get update...` | Eliminar paquetes no usados (`build-essential`, `vim`, `git`, etc.) | Tamaño: reducir capas instalando solo lo necesario. |
| 4 | Actualización de `pip` en capa separada | `RUN pip install --upgrade pip` | Combinar con instalación de dependencias o eliminar | Capas: fusionar para reducir número de capas. |
| 5 | Herramientas de desarrollo instaladas en la imagen final | `RUN pip install pytest black flake8 ipython httpx` | Eliminarlas (no necesarias en producción) | Multi-stage: separar construcción de ejecución. |
| 6 | Orden de capas incorrecto (copiar todo antes de instalar dependencias) | `COPY . .` antes de `pip install` | Copiar primero `requirements.txt`, luego instalar dependencias, luego el resto | Caché: colocar lo que cambia poco al principio. |
| 7 | Secreto expuesto en variable de entorno | `ENV DB_PASSWORD=Sup3rS3cret2026` | Eliminar la línea | Seguridad: no guardar secretos en la imagen. |
| 8 | Escritura del secreto en un archivo | `RUN echo "$DB_PASSWORD" > /app/.dbpass` | Eliminar la línea | Capas: las capas son inmutables, el secreto queda en el historial. |
| 9 | Intento de borrar el archivo de contraseña | `RUN rm /app/.dbpass` | Eliminar la línea | Capas: `rm` no reduce tamaño porque la capa anterior persiste. |
| 10 | No se usa multi-stage | (falta) | Añadir etapa `builder` y copiar solo lo necesario | Multi-stage: reducir tamaño final. |
| 11 | Usuario `root` | (falta `USER`) | Crear usuario `appuser` y usar `USER appuser` | Seguridad: minimizar privilegios. |
| 12 | Falta `HEALTHCHECK` | (falta) | Añadir `HEALTHCHECK` | Monitoreo: permitir que Docker verifique el estado. |
| 13 | `CMD` en forma shell | `CMD python -m uvicorn ...` | Cambiar a `CMD ["python", "-m", "uvicorn", ...]` | Señales: evitar problemas con señales y procesos. |
| 14 | No se limpia caché de `apt` | (no se limpia) | Añadir `&& rm -rf /var/lib/apt/lists/*` | Tamaño: eliminar archivos de caché de apt. |

---

## 3. El secreto

**¿La imagen pesa menos después del `rm`?**

No. Las capas son inmutables. La capa donde se escribió la contraseña (12.3 kB) permanece en la imagen, y la capa de `rm` (8.19 kB) solo añade un registro de borrado, pero no elimina los bytes de la capa anterior. El tamaño total no se reduce.

**¿La contraseña sigue siendo recuperable? Evidencia:**

Sí, la contraseña se puede recuperar de dos formas:

1.La variable de entorno DB_PASSWORD está guardada en los metadatos de la imagen. Ejecuté:

docker inspect --format '{{.Config.Env}}' mi-app:original | grep -i password
Y obtuve:

[PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin LANG=C.UTF-8 DB_PASSWORD=Sup3rS3cret2026]
2. También en el historial de capas se ve claramente que se escribió la contraseña:

docker history --no-trunc mi-app:original | grep -i password
Salida:

ENV DB_PASSWORD=Sup3rS3cret2026
RUN /bin/sh -c echo "$DB_PASSWORD" > /app/.dbpass # buildkit

Incluso si el archivo /app/.dbpass fue borrado, la variable de entorno sigue expuesta y cualquier persona con acceso a la imagen puede verla. Para comprobarlo, ejecuté un contenedor y mostré la variable:

docker run --rm mi-app:original sh -c 'echo $DB_PASSWORD'
Sup3rS3cret2026

**¿Cuál es la forma correcta de manejar ese secreto?**

Lo correcto es nunca guardar secretos en la imagen. Las capas son inmutables y cualquier secreto que se escriba queda grabado para siempre. La variable de entorno con ENV también queda fija en los metadatos de la imagen.

Las alternativas seguras son:

Usar build secrets de Docker BuildKit (--secret) para pasar la contraseña solo durante la construcción, sin que se almacene en las capas.

Pasar la contraseña en tiempo de ejecución, con -e DB_PASSWORD=... al hacer docker run, o mediante un archivo .env montado como volumen.

---

## 4. Comparativa de imágenes base


| Base | Tamaño final | Tiempo de build | Observaciones |
|---|---|---|---|
| `python:3.12` | ~481 MB | ~2 min | Imagen completa con muchas herramientas y paquetes. Muy pesada para producción. |
| `python:3.12-slim` | 71.1 MB | ~1 min | Basada en Debian slim, solo lo esencial. Excelente equilibrio tamaño-compatibilidad. |
| `python:3.12-alpine` | ~50 MB (estimado) | ~2.5 min | Muy pequeña pero tuve problemas con dependencias nativas que requieren compilación con musl. |

**Cuál elegiríamos para producción y por qué:**

Elegiría `python:3.12-slim` porque es la que mejor combina tamaño reducido, compatibilidad total con las dependencias del proyecto y un tiempo de build razonable. Además, evita los problemas que tuve con Alpine, donde algunas librerías como `uvloop` y `httptools` fallaban al compilar con musl, y la prueba funcional fallaba intermitentemente. `slim` es la opción más estable y segura para este proyecto.
---

## 5. Un cambio que intentamos y no funcionó

**Qué intente:** Intente probar `python:3.12-alpine` como imagen base para reducir aún más el tamaño final de la imagen.

**Qué pasó:** Lo que pasó fue que al instalar las dependencias de `requirements.txt`, las librerías `uvloop` y `httptools` (necesarias para `uvicorn[standard]`) no estaban precompiladas para Alpine y requerían compilación con `gcc` y `musl-dev`. Tuve que instalar esos paquetes de construcción, lo que aumentó el tiempo de build y el tamaño final (dejó de ser tan pequeño). Además, la prueba funcional fallaba de forma intermitente porque algunas librerías compiladas no funcionaban igual que en glibc.

**Por qué no funcionó:** No fuimncionó porque Alpine usa musl en lugar de glibc, y muchas librerías de Python con componentes en C no están optimizadas para ese entorno. Compilarlas manualmente introduce riesgos de compatibilidad y alarga el proceso de construcción. Para un proyecto con varias dependencias nativas, Alpine puede ser más problemático que beneficioso. Por eso descarté Alpine y me quedé con `slim`, que funciona sin complicaciones y da un tamaño más que aceptable.

---

## 6. Nuestro Dockerfile final

```dockerfile
# ================================================================
#  Dockerfile optimizado - Taller Línea de Énfasis II
#  Natalia Muñoz Osorio
#  Fecha: 2026-07-31
# ================================================================

# ---- Etapa 1: Builder (instalación de dependencias) ----
FROM python:3.12-slim AS builder

WORKDIR /app

# Copiar solo requirements para aprovechar caché
COPY app/requirements.txt .

# Instalar dependencias sin caché y sin herramientas de desarrollo
RUN pip install --no-cache-dir -r requirements.txt

# ---- Etapa 2: Imagen final (ejecución) ----
FROM python:3.12-slim

# Crear usuario no root e instalar curl (para healthcheck) en UNA capa
RUN adduser --disabled-password --gecos '' appuser && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar todo /usr/local desde builder (incluye binarios y librerías)
COPY --from=builder --chown=appuser:appuser /usr/local /usr/local

# Copiar el código de la aplicación
COPY --chown=appuser:appuser app/ app/

# Cambiar al usuario no root
USER appuser

# Healthcheck para monitoreo
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Puerto expuesto
EXPOSE 8000

# Comando en formato exec (para manejar señales correctamente)
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```