# Pruebas de carga — RNF-008 y RNF-009

Todo se ejecuta en tu máquina con el stack levantado (`docker compose up -d`).

## 1. Preparar (una vez)

    # índices de búsqueda
    docker compose cp raccord_backend/api_usuarios/sql/031_busqueda_fotos_indices.sql db:/tmp/031.sql
    docker compose exec db psql -U carlos.yaya -d raccord -f /tmp/031.sql

    # reconstruir el backend (endpoint nuevo + pool de conexiones)
    docker compose build backend && docker compose up -d backend

    # ver tus proyectos y cargar 15.000 fotos de prueba en uno que tenga escenas
    Get-Content tools/carga/seed_fotos.py | docker compose exec -T backend python - listar
    Get-Content tools/carga/seed_fotos.py | docker compose exec -T backend python - ID_PROYECTO 15000

## 2. RNF-008 — búsqueda (20 usuarios, 5 filtros, 30 min)

    python tools/carga/prueba_carga.py --mail TU_CORREO --password TU_CLAVE --project ID_PROYECTO buscar --usuarios 20 --minutos 30

Prueba corta de humo: `--minutos 1`. Cumple si p95 < 10 s, promedio < 5 s y
0 errores. El comando termina con código 0 si cumple, 1 si no.

Importante: el login tiene el bloqueo de RNF-004; usa una cuenta con la
contraseña correcta (los fallos repetidos bloquean la cuenta).

## 3. RNF-009 — volumen diario (100 fotos de 2-6 MB)

    python tools/carga/prueba_carga.py --mail TU_CORREO --password TU_CLAVE --project ID_PROYECTO subir --cantidad 100 --escena ID_ESCENA

Sube de verdad a MinIO (hasta ~600 MB). Para el criterio de "30 días
seguidos" repite este comando a diario (o prográmalo) y compara los
tiempos; si el tiempo medio se mantiene, no hay degradación. Las fotos
llevan la descripción `[carga-test]`: bórralas desde la Galería/Papelera.

## 4. Limpiar las fotos de prueba de la búsqueda

    Get-Content tools/carga/seed_fotos.py | docker compose exec -T backend python - limpiar

## Nota sobre JMeter

El requisito menciona Apache JMeter. Este script mide lo mismo (promedio y
p95 con 20 hilos concurrentes) sin instalar nada. Si el docente exige el
archivo `.jmx`, se puede generar con el mismo escenario: GET
`/fotos/project/{id}/buscar` con los 5 filtros (q, tipo_foto,
personaje_codigo, desde, hasta) y cabecera `Authorization: Bearer <token>`.
