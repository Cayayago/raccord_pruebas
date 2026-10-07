-- ==========================================
-- 009_uuid_primary_keys.sql
-- ==========================================
-- Convierte las llaves primarias/foráneas de IDs secuenciales (enteros
-- autoincrementales o texto con prefijo generado por trigger, ej.
-- "esc001", "act1") a UUID — para que cualquier cliente (incluso sin
-- conexión) pueda generar un ID único sin depender de una secuencia
-- central de la base de datos, evitando colisiones al sincronizar.
--
-- ALCANCE — se excluyen a propósito 3 tablas:
--   - roles / permisos / rol_has_permisos: el sistema de permisos del
--     backend (app/utils/permissions.py) está hardcodeado con los IDs
--     numéricos fijos 1001-1005 para cada rol. Cambiarlos a UUID
--     rompería TODA la autorización de la app. Se dejan como están.
--
-- DATOS — se pierde toda la información existente EXCEPTO en
-- "departamentos": esa tabla se migra en el lugar (cada fila existente
-- recibe un UUID nuevo, sin perder nombre/ubicación). El resto de
-- tablas de contenido/cuentas se recrean vacías.
--
-- IMPORTANTE: correr esto DESPUÉS de aplicar el backend nuevo (o con
-- el backend detenido) — el código viejo espera IDs int/texto con
-- prefijo y va a fallar contra un esquema UUID.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==========================================
-- 1) Todo lo que NO es departamentos (menos roles/permisos/
--    rol_has_permisos) — se recrea desde cero con UUID. CASCADE se
--    lleva también las FK, índices y triggers que colgaban de estas
--    tablas. Esto va PRIMERO porque users y desglose_items tienen FK
--    hacia departamentos_pkey — hay que quitarlas antes de poder
--    convertir el tipo de esa llave primaria en el paso 2.
-- ==========================================
DROP TABLE IF EXISTS
    desglose_item_detalle,
    desglose_items,
    fotos_continuidad,
    escenas_personajes,
    escenas,
    actors,
    personajes,
    plan_rodaje,
    desgloses,
    guiones,
    user_projects,
    users,
    projects,
    clients
CASCADE;

-- Funciones/secuencias que generaban los IDs con prefijo — ya no hacen
-- falta, el DEFAULT de cada tabla nueva es gen_random_uuid().
DROP FUNCTION IF EXISTS gen_id_actor();
DROP FUNCTION IF EXISTS gen_id_escena();
DROP FUNCTION IF EXISTS gen_id_personaje();
DROP FUNCTION IF EXISTS generar_id_project();

DROP SEQUENCE IF EXISTS actor_seq;
DROP SEQUENCE IF EXISTS escena_seq;
DROP SEQUENCE IF EXISTS personajes_seq;
DROP SEQUENCE IF EXISTS plan_rodaje_seq;
DROP SEQUENCE IF EXISTS desglose_seq;
DROP SEQUENCE IF EXISTS project_seq;
-- Las secuencias "OWNED BY" una columna (clients_id_cliente_seq,
-- guiones_id_guion_seq, fotos_continuidad_id_foto_seq,
-- desglose_items_id_desglose_item_seq,
-- desglose_item_detalle_id_detalle_seq, user_projects_id_seq,
-- users_id_user_seq) ya se borraron solas con el DROP TABLE CASCADE.

-- ==========================================
-- 2) departamentos — se preserva la data, solo cambia el tipo del ID.
--    Ahora que ya no hay FK vivas apuntando a departamentos_pkey (se
--    fueron con el DROP TABLE CASCADE de arriba), se puede convertir
--    el tipo de la columna sin bloqueos.
-- ==========================================
DROP TRIGGER IF EXISTS trg_id_departamento ON departamentos;
DROP FUNCTION IF EXISTS gen_id_departamento();
DROP SEQUENCE IF EXISTS departamento_seq;

ALTER TABLE departamentos DROP CONSTRAINT IF EXISTS departamentos_pkey;
ALTER TABLE departamentos ALTER COLUMN id_departamento DROP DEFAULT;
ALTER TABLE departamentos ALTER COLUMN id_departamento TYPE uuid USING gen_random_uuid();
ALTER TABLE departamentos ALTER COLUMN id_departamento SET DEFAULT gen_random_uuid();
ALTER TABLE departamentos ADD CONSTRAINT departamentos_pkey PRIMARY KEY (id_departamento);

-- ---------- clients ----------
CREATE TABLE clients (
    id_cliente          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    document            varchar(50) NOT NULL,
    id_document         text NOT NULL,
    razon_social        varchar(50) NOT NULL,
    representante_legal varchar(100) NOT NULL,
    email               varchar(100) NOT NULL UNIQUE,
    address             varchar(100),
    telephone           varchar(15),
    number_cellphone    varchar(20)
);

-- ---------- projects ----------
CREATE TABLE projects (
    id_project             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_name           varchar(45) NOT NULL,
    formato_de_produccion  varchar(50) NOT NULL,
    genero                 varchar(50) NOT NULL,
    sinopsis               text,
    director               varchar(255),
    id_client              uuid NOT NULL REFERENCES clients(id_cliente) ON UPDATE CASCADE ON DELETE CASCADE
);

-- ---------- users ----------
CREATE TABLE users (
    id_user             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre               varchar(255) NOT NULL,
    apellido             varchar(255) NOT NULL,
    identificacion       varchar(50) NOT NULL,
    id_identificacion    varchar(50) NOT NULL UNIQUE,
    mail                 varchar(150) NOT NULL UNIQUE,
    msisdn               varchar(20) NOT NULL,
    direccion            varchar(150),
    fecha_de_nacimiento  timestamp NOT NULL,
    estado               varchar(20) NOT NULL,
    fecha_de_creacion    timestamp DEFAULT now(),
    ultimo_acceso        timestamp DEFAULT now(),
    contrasena           varchar(255) NOT NULL,
    id_departamento      uuid REFERENCES departamentos(id_departamento) ON UPDATE CASCADE ON DELETE CASCADE,
    id_project           uuid,
    id_client            uuid REFERENCES clients(id_cliente) ON UPDATE CASCADE ON DELETE CASCADE,
    id_rol               integer NOT NULL REFERENCES roles(id_rol) ON UPDATE CASCADE ON DELETE CASCADE,
    foto_perfil_key       text
);

-- ---------- guiones ----------
CREATE TABLE guiones (
    id_guion            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_de_version   varchar(45) NOT NULL UNIQUE,
    fecha_de_emision    date NOT NULL,
    estado              varchar(50) NOT NULL,
    archivo              text,
    nombre               varchar(100) NOT NULL,
    descripcion          text,
    archivo_nombre       varchar(255),
    archivo_key          text,
    archivo_tipo         varchar(100),
    archivo_tamano       integer,
    id_project           uuid REFERENCES projects(id_project) ON UPDATE CASCADE ON DELETE CASCADE
);

-- ---------- personajes ----------
CREATE TABLE personajes (
    id_personaje      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre             varchar(45) NOT NULL,
    edad               integer NOT NULL,
    codigo_personaje   varchar(30) NOT NULL
);

-- ---------- actors ----------
CREATE TABLE actors (
    id_actor                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                   varchar(45) NOT NULL,
    apellido                 varchar(45) NOT NULL,
    genero                   varchar(20) NOT NULL,
    fecha_de_nacimiento      date NOT NULL,
    talla_zapatos            varchar(10) NOT NULL,
    ancho_espalda            varchar(30) NOT NULL,
    pecho                    varchar(30) NOT NULL,
    cintura                  varchar(30) NOT NULL,
    cadera                   varchar(30) NOT NULL,
    largo_manga              varchar(30) NOT NULL,
    largo_pierna             varchar(30) NOT NULL,
    talla_anillo             text,
    contorno_cabeza          varchar(30),
    contorno_cuello          varchar(30),
    color_cabello            varchar(45) NOT NULL,
    textura_cabello          varchar(45) NOT NULL,
    tipo_piel                varchar(45) NOT NULL,
    color_ojos               varchar(45) NOT NULL,
    alergias                 text,
    habilidades_especiales   text,
    restricciones            text,
    comentarios_adicionales  text,
    nacionalidad             varchar(50) NOT NULL,
    doble_riesgo             boolean NOT NULL,
    id_personaje             uuid REFERENCES personajes(id_personaje) ON UPDATE CASCADE ON DELETE CASCADE
);

-- ---------- plan_rodaje ----------
CREATE TABLE plan_rodaje (
    id_rodaje         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    version            varchar(50) NOT NULL,
    semana_grabacion   integer,
    dia_rodaje         integer,
    hora_inicio        time,
    hora_fin           time,
    location           varchar(200),
    notas              text,
    activo             boolean DEFAULT true
);

-- ---------- desgloses ----------
CREATE TABLE desgloses (
    id_desglose        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    version             varchar(50) NOT NULL,
    semana_grabacion    integer,
    dia_rodaje          integer,
    hora_inicio         time,
    hora_fin            time,
    location            varchar(200),
    requerimientos      text NOT NULL,
    activo              boolean DEFAULT true
);

-- ---------- escenas ----------
CREATE TABLE escenas (
    id_escena           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_de_escena     varchar(45) NOT NULL,
    encabezado           text NOT NULL,
    descripcion          text,
    id_guion             uuid REFERENCES guiones(id_guion) ON UPDATE CASCADE ON DELETE CASCADE,
    modo_vista           varchar(20),
    momento_dia          varchar(20),
    ciudad               text,
    pagina               integer,
    fecha_de_grabacion   date,
    dia_dramatico        integer,
    id_rodaje            uuid REFERENCES plan_rodaje(id_rodaje) ON UPDATE CASCADE ON DELETE CASCADE,
    id_desglose          uuid REFERENCES desgloses(id_desglose) ON UPDATE CASCADE ON DELETE CASCADE,
    estado               varchar(20) NOT NULL DEFAULT 'Pendiente',
    locacion_rodaje      text,
    tiempo_estimado      text,
    hora_inicio_rodaje   time,
    notas_rodaje         text,
    orden_rodaje         integer
);

-- ---------- escenas_personajes ----------
CREATE TABLE escenas_personajes (
    id_escena      uuid NOT NULL REFERENCES escenas(id_escena) ON DELETE CASCADE,
    id_personaje   uuid NOT NULL REFERENCES personajes(id_personaje) ON DELETE CASCADE,
    PRIMARY KEY (id_escena, id_personaje)
);

-- ---------- desglose_items ----------
CREATE TABLE desglose_items (
    id_desglose_item   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_escena           uuid NOT NULL REFERENCES escenas(id_escena) ON DELETE CASCADE,
    id_departamento     uuid REFERENCES departamentos(id_departamento),
    categoria            varchar(50) NOT NULL,
    nombre_item          text NOT NULL,
    cantidad             integer,
    notas                text,
    id_user_creador      uuid REFERENCES users(id_user),
    created_at           timestamp DEFAULT now(),
    updated_at           timestamp DEFAULT now()
);

-- ---------- desglose_item_detalle ----------
CREATE TABLE desglose_item_detalle (
    id_detalle          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_desglose_item     uuid NOT NULL REFERENCES desglose_items(id_desglose_item) ON DELETE CASCADE,
    etiqueta              varchar(100) NOT NULL,
    cantidad              integer,
    estado                varchar(20) NOT NULL DEFAULT 'pendiente',
    prioridad             varchar(10),
    notas                 text,
    id_user_editor        uuid REFERENCES users(id_user),
    updated_at            timestamp DEFAULT now()
);

-- ---------- fotos_continuidad ----------
CREATE TABLE fotos_continuidad (
    id_foto              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_escena             uuid NOT NULL REFERENCES escenas(id_escena) ON DELETE CASCADE,
    tipo_foto             varchar(30) NOT NULL DEFAULT 'Propuesta',
    personaje_codigo      varchar(30),
    descripcion           text,
    notas_continuidad     text,
    archivo_nombre        varchar(255) NOT NULL,
    archivo_key           text NOT NULL,
    archivo_tipo          varchar(100) NOT NULL,
    archivo_tamano        integer NOT NULL,
    fecha_subida          timestamp NOT NULL DEFAULT now()
);

-- ---------- user_projects ----------
CREATE TABLE user_projects (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    id_user              uuid NOT NULL REFERENCES users(id_user) ON DELETE CASCADE,
    id_project           uuid NOT NULL REFERENCES projects(id_project) ON DELETE CASCADE,
    id_rol               integer NOT NULL DEFAULT 1005,
    fecha_vinculacion    timestamp DEFAULT now()
);

COMMIT;
