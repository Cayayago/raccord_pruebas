-- ==========================================================
-- ACCESOS PERSONALIZADOS POR MÓDULO (excepciones puntuales)
-- ==========================================================
-- Contexto (evaluado y acordado con el usuario, ver tarea "matriz de
-- roles en 3 capas"): el sistema de permisos sigue siendo por ROL fijo
-- (roles.id_rol -> ROLE_PERMISSIONS en app/utils/permissions.py), NO
-- se reemplaza. Esta tabla es una capa liviana ENCIMA de eso: permite
-- que Administrador/Director de un proyecto le bajen el nivel de
-- acceso a UNA persona en UN módulo puntual (caso más pedido:
-- restringir un módulo sensible para alguien concreto, sin tener que
-- crear un rol nuevo ni afectar a nadie más).
--
-- Los 9 módulos reales del menú (ver appSideMenuItems en
-- app_scaffold.dart): guion, escenas, desglose, plan_rodaje,
-- personajes, cast, galeria, crew_list, roles.
--
-- Los 5 niveles (sin_acceso, ver, comentar, editar, administrar) son
-- una ETIQUETA visual pensada para el diálogo de "Personalizar
-- accesos" del frontend; la aplicación real de la excepción es
-- SIEMPRE hacia abajo: nunca le da a alguien más de lo que su rol ya
-- permite, solo puede restringirlo (ver get_effective_module_level en
-- app/utils/module_access.py). Por eso una sola fila por persona+
-- proyecto+módulo alcanza, sin necesidad de rehacer el esquema de
-- permisos existente.
CREATE TABLE IF NOT EXISTS user_project_module_access (
    id                    UUID PRIMARY KEY,
    id_user               UUID NOT NULL REFERENCES users(id_user) ON DELETE CASCADE,
    id_project            UUID NOT NULL REFERENCES projects(id_project) ON DELETE CASCADE,
    modulo                VARCHAR(30) NOT NULL,
    nivel                 VARCHAR(20) NOT NULL,
    id_actualizado_por    UUID REFERENCES users(id_user) ON DELETE SET NULL,
    fecha_actualizacion   TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT uq_module_access_persona_modulo UNIQUE (id_user, id_project, modulo)
);

CREATE INDEX IF NOT EXISTS idx_module_access_user_project
    ON user_project_module_access(id_user, id_project);
