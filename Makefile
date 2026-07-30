SHELL := /bin/bash

IMAGEN ?= mi-app:optimizada
ORIGINAL = mi-app:original

.PHONY: help init base build cache medir probar comparar limpiar

help:            ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*## "}{printf "  make %-10s %s\n", $$1, $$2}'

init:            ## PRIMER PASO: guarda el Dockerfile de partida como Dockerfile.original
	@if [ -f Dockerfile.original ]; then \
		echo "Dockerfile.original ya existe, no se sobrescribe."; \
	else \
		cp Dockerfile Dockerfile.original; \
		echo "Listo: Dockerfile.original creado. Ahora edita Dockerfile con tus mejoras."; \
	fi

base: init       ## Construye la imagen de partida (crea Dockerfile.original si falta)
	time docker build --no-cache -f Dockerfile.original -t $(ORIGINAL) .

build:           ## Construye tu imagen optimizada
	time docker build --no-cache -t $(IMAGEN) .

cache:           ## Reconstruye aprovechando cache (mide este tiempo)
	time docker build -t $(IMAGEN) .

medir:           ## Metricas de tu imagen
	./scripts/medir.sh $(IMAGEN)

probar:          ## Solo la prueba funcional
	./scripts/prueba-funcional.sh $(IMAGEN)

comparar:        ## Metricas de ambas, lado a lado
	./scripts/medir.sh $(ORIGINAL)
	./scripts/medir.sh $(IMAGEN)

limpiar:
	docker image rm -f $(IMAGEN) $(ORIGINAL) 2>/dev/null || true
