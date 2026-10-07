-- ==========================================================
-- ÍNDICES FALTANTES EN COLUMNAS DE LLAVE FORÁNEA
-- ==========================================================
-- Postgres NO indexa automáticamente las columnas de FOREIGN KEY (solo
-- la primary key de cada tabla) — hay que crear el índice a mano. Se
-- auditaron las 27 FK del esquema contra los índices ya existentes
-- (sql/000 en adelante) y contra los patrones reales de consulta en
-- los controllers; estas son las que quedaban sin índice pese a
-- filtrarse por esa columna en endpoints activos.
--
-- La más importante con diferencia: user_projects. Es la tabla que
-- resuelve el ROL EFECTIVO de cada persona en cada proyecto (ver
-- app/utils/project_scope.py::get_role_in_project) — se consulta en
-- prácticamente TODA petición autenticada de la API, y hasta ahora no
-- tenía ningún índice más allá de su primary key "id" (que no sirve
-- para este filtro).
CREATE INDEX IF NOT EXISTS idx_user_projects_user_project ON user_projects(id_user, id_project);
CREATE INDEX IF NOT EXISTS idx_user_projects_project ON user_projects(id_project);

-- Escenas: filtradas por guion (Guión → Escenas), por día de rodaje
-- (Plan de Rodaje) y por desglose (Desglose) — ver scene_routes.py
-- (scenes_by_script, scenes_by_rodaje, scenes_by_desglose).
CREATE INDEX IF NOT EXISTS idx_escenas_id_guion ON escenas(id_guion);
CREATE INDEX IF NOT EXISTS idx_escenas_id_rodaje ON escenas(id_rodaje);
CREATE INDEX IF NOT EXISTS idx_escenas_id_desglose ON escenas(id_desglose);

-- Guiones: listado principal de la pantalla Guión es por proyecto.
CREATE INDEX IF NOT EXISTS idx_guiones_id_project ON guiones(id_project);

-- Projects: aislamiento multi-tenant, se filtra por cliente en cada
-- listado de proyectos de una empresa.
CREATE INDEX IF NOT EXISTS idx_projects_id_client ON projects(id_client);

-- Actors: "ficha del personaje" pide sus actores relacionados
-- (GET /actors/character/{id_personaje}).
CREATE INDEX IF NOT EXISTS idx_actors_id_personaje ON actors(id_personaje);

-- Crew List: filtro por departamento (pedido explícito del usuario).
CREATE INDEX IF NOT EXISTS idx_personal_produccion_id_departamento ON personal_produccion(id_departamento);

-- Users: aislamiento por empresa/cliente (se consulta en casi todos
-- los endpoints de /users, /clients) y filtro por departamento
-- (Jefe de Departamento gestionando solo su propia área).
CREATE INDEX IF NOT EXISTS idx_users_id_client ON users(id_client);
CREATE INDEX IF NOT EXISTS idx_users_id_departamento ON users(id_departamento);
