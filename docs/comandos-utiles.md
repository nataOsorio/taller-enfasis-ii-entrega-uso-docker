# Comandos de apoyo

## Medición

```bash
# Tamaño en bytes
docker image inspect --format '{{.Size}}' mi-app:optimizada

# Número de capas
docker image inspect --format '{{len .RootFS.Layers}}' mi-app:optimizada

# Usuario configurado (vacío = root)
docker image inspect --format '{{.Config.User}}' mi-app:optimizada

# Variables de entorno horneadas en la imagen
docker image inspect --format '{{json .Config.Env}}' mi-app:optimizada

# Tiempo de construcción
time docker build --no-cache -t mi-app:original .
time docker build -t mi-app:optimizada .
```

## Historial de capas

```bash
# Qué aportó cada capa
docker history mi-app:original

# Sin truncar: aquí se ven los comandos completos
docker history --no-trunc mi-app:original

# Buscar algo específico en el historial
docker history --no-trunc mi-app:original | grep -i password
```

## Inspección del contenedor en ejecución

```bash
docker run --rm mi-app:optimizada whoami
docker run --rm mi-app:optimizada sh -c 'ls -la /app'
docker run --rm -it mi-app:optimizada sh   # puede no existir shell: eso es buena señal
```

## Scripts del taller

```bash
./scripts/medir.sh mi-app:original
./scripts/medir.sh mi-app:optimizada
./scripts/prueba-funcional.sh mi-app:optimizada
```

## Limpieza

```bash
docker image prune -f
docker builder prune -f      # ojo: borra la caché de build
```

---

## Pistas conceptuales

- Las capas de una imagen son **inmutables y aditivas**. Nada de lo que hagas
  en una capa posterior elimina lo que quedó escrito en una anterior.
- La caché de construcción se invalida en la primera instrucción que cambia
  y **en todas las siguientes**. El orden importa más que el contenido.
- `COPY` de un archivo que cambia mucho, colocado temprano, invalida todo lo
  que viene después.
- Las herramientas que necesitas para *construir* no son las mismas que
  necesitas para *ejecutar*.
