# Rúbrica — Taller

| Criterio | Peso | Qué se evalúa |
|---|---|---|
| Reducción alcanzada **con la prueba funcional pasando** | 30% | ≥70% de reducción y `prueba-funcional.sh` en PASA. Si la prueba falla, este criterio es 0 |
| Fallas identificadas | 20% | Sobre 14. Proporcional |
| Justificación por cambio | 25% | Cada corrección explicada con el concepto correcto, no con la receta |
| El secreto en las capas | 10% | Demostración con evidencia de que el `rm` no eliminó nada, más el manejo correcto |
| Comparativa de imágenes base | 10% | Medición de las tres y argumento del compromiso |
| Cambio fallido documentado | 5% | Honestidad técnica y capacidad de diagnóstico |

## Verificación automática

El docente ejecuta sobre la entrega:

```bash
./scripts/medir.sh <imagen-del-estudiante>
```

Eso resuelve objetivamente tamaño, capas, usuario, healthcheck, forma de CMD,
secretos y prueba funcional. La calificación cualitativa se concentra en las
justificaciones.

## Penalizaciones de Nota

| Situación | Efecto |
|---|---|
| Se modificó el código de la aplicación | Anula el criterio de reducción |
| Uso de `--squash` o compresión externa | Anula el criterio de reducción |
| Números sin el comando que los produjo | −50% del criterio correspondiente |
| Entrega sin `Dockerfile.original` | No se puede comparar: −30% global |
