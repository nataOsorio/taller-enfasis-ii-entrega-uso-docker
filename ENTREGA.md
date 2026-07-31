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

Encontramos **14** de 14.

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

**Sí, la contraseña sigue siendo recuperable** por dos razones:

1. **La variable de entorno `DB_PASSWORD` está expuesta** en los metadatos de la imagen:
   ```bash
   $ docker inspect --format '{{.Config.Env}}' mi-app:original | grep -i password
   [PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin LANG=C.UTF-8 DB_PASSWORD=Sup3rS3cret2026]

2. **El historial de capas muestra el comando que escribió la contraseña en el archivo:**
$ docker history --no-trunc mi-app:original | grep -i password
ENV DB_PASSWORD=Sup3rS3cret2026
RUN /bin/sh -c echo "$DB_PASSWORD" > /app/.dbpass # buildkit

Incluso si el archivo **/app/.dbpass** fue borrado, la variable de entorno DB_PASSWORD aún permite recuperar la contraseña en un contenedor en ejecución:

$ docker run --rm mi-app:original sh -c 'echo $DB_PASSWORD'
Sup3rS3cret2026

 En conclusión, el rm no hace que la contraseña sea irrecuperable, porque la variable de entorno sigue accesible y la capa que contenía el archivo permanece en el historial de la imagen.