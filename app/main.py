"""API de inventario — aplicación semilla del curso.

No modifiques este archivo: el taller se resuelve únicamente
desde el Dockerfile y el .dockerignore.
"""
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

APP_VERSION = "1.0.0"

app = FastAPI(title="Inventario", version=APP_VERSION)

_items = {}
_next_id = 1


class ItemIn(BaseModel):
    nombre: str = Field(min_length=1, max_length=80)
    cantidad: int = Field(ge=0)


class Item(ItemIn):
    id: int
    creado: str


@app.get("/health")
def health():
    return {"status": "ok", "version": APP_VERSION}


@app.get("/items")
def listar():
    return list(_items.values())


@app.post("/items", status_code=201)
def crear(payload: ItemIn):
    global _next_id
    item = Item(
        id=_next_id,
        nombre=payload.nombre,
        cantidad=payload.cantidad,
        creado=datetime.now(timezone.utc).isoformat(),
    )
    _items[item.id] = item
    _next_id += 1
    return item


@app.get("/items/{item_id}")
def obtener(item_id: int):
    if item_id not in _items:
        raise HTTPException(status_code=404, detail="No existe")
    return _items[item_id]
