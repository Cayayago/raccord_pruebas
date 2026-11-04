-- Solo diagnóstico, no modifica nada.
-- 1) ¿Existe de verdad la constraint PRIMARY KEY en cada tabla?
SELECT tc.table_name, tc.constraint_name, tc.constraint_type, kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name IN ('guiones', 'clients')
  AND tc.constraint_type = 'PRIMARY KEY';

-- 2) Tipo real de columna y si permite NULL
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name IN ('guiones', 'clients')
  AND column_name IN ('id_guion', 'id_cliente');

-- 3) Filas reales de guiones (id_guion NULL o no)
SELECT id_guion, numero_de_version, estado FROM guiones;
