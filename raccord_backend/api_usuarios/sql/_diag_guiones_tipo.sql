-- Solo diagnóstico: confirma el tipo real de la columna y si de verdad hay NULLs.
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'guiones' AND column_name = 'id_guion';

SELECT count(*) AS total_filas, count(id_guion) AS filas_con_id
FROM guiones;
