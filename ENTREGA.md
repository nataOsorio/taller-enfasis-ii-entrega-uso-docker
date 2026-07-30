# Entrega — Taller

**Estudiantes:**
**Fecha:**
**Rama:**

---

## 1. Tabla comparativa

| Métrica | Original | Optimizada | Mejora | Comando usado |
|---|---|---|---|---|
| Tamaño |  |  |  | `docker image inspect --format '{{.Size}}'` |
| Capas |  |  |  | `docker image inspect --format '{{len .RootFS.Layers}}'` |
| Build en frío |  |  |  | `time docker build --no-cache` |
| Rebuild tras cambio de código |  |  |  | `time docker build` |
| Usuario efectivo |  |  |  | `docker image inspect --format '{{.Config.User}}'` |
| Prueba funcional |  |  |  | `./scripts/prueba-funcional.sh` |

---

## 2. Fallas identificadas

Encontramos ___ de 14.

| # | Falla | Línea | Corrección aplicada | Concepto |
|---|---|---|---|---|
| 1 |  |  |  |  |
| 2 |  |  |  |  |
| 3 |  |  |  |  |

*(Agrega las filas que hayas encontrado.)*

---

## 3. El secreto

**¿La imagen pesa menos después del `rm`?**

**¿La contraseña sigue siendo recuperable? Evidencia:**

```
(pega aquí la salida del comando que lo demuestra)
```

**¿Cuál es la forma correcta de manejar ese secreto?**

---

## 4. Comparativa de imágenes base

| Base | Tamaño final | Tiempo de build | Observaciones |
|---|---|---|---|
| `python:3.12` |  |  |  |
| `python:3.12-slim` |  |  |  |
| (alpine / distroless) |  |  |  |

**Cuál elegiríamos para producción y por qué:**

---

## 5. Un cambio que intentamos y no funcionó

**Qué intentamos:**

**Qué pasó:**

**Por qué no funcionó:**

---

## 6. Nuestro Dockerfile final

```dockerfile
(pega aquí tu Dockerfile con comentarios)
```
