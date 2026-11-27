#!/bin/sh
# Crea el esquema de la BD de pruebas aplicando, en orden, las migraciones de
# producción (sql/0*.sql). Docker lo ejecuta una sola vez, cuando la BD está
# vacía. Los archivos "_diag_*.sql" son consultas de diagnóstico y no entran.
set -e

for archivo in /sql/0*.sql; do
  echo "Aplicando $archivo"
  # Los .sql se guardan con saltos de línea de Windows (CRLF) y psql los
  # necesita en formato Unix: se quita el \r antes de pasarlos.
  tr -d '\r' < "$archivo" | psql -v ON_ERROR_STOP=1 --quiet -U "$POSTGRES_USER" -d "$POSTGRES_DB"
done
