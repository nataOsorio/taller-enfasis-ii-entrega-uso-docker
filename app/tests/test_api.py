from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_crear_y_listar():
    r = client.post("/items", json={"nombre": "teclado", "cantidad": 3})
    assert r.status_code == 201
    creado = r.json()
    assert creado["nombre"] == "teclado"
    r = client.get("/items/" + str(creado["id"]))
    assert r.status_code == 200


def test_validacion():
    r = client.post("/items", json={"nombre": "", "cantidad": -1})
    assert r.status_code == 422
