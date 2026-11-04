--
-- PostgreSQL database dump
--

\restrict RW3sOgMdk484egD1ALFFgHzkzky9SjGnAKDshF66HjfefEAghZzFh0RvdPKhIdI

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6 (Debian 18.6-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: estado_guion; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_guion AS ENUM (
    'Borrador',
    'Revisión',
    'Aprobado',
    'En Rodaje',
    'Archivado'
);


--
-- Name: estado_usuario; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_usuario AS ENUM (
    'activo',
    'inactivo',
    'pendiente',
    'suspendido'
);


--
-- Name: formatos; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.formatos AS ENUM (
    'serie',
    'miniserie',
    'pelicula',
    'largometraje',
    'mediometraje',
    'cortometraje',
    'documental',
    'spot publicitario',
    'video musical',
    'video corporativo',
    'video educativo',
    'micro-formato',
    'mockumentary'
);


--
-- Name: generos; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.generos AS ENUM (
    'accion',
    'comedia',
    'aventura',
    'drama',
    'terror',
    'ciencia ficcion',
    'fantasia',
    'suspenso',
    'musical',
    'western',
    'belico',
    'romance',
    'crimen',
    'misterio',
    'animacion',
    'biopic',
    'documental',
    'video',
    'artes marciales',
    'thriller',
    'Histórico',
    'epoca',
    'familiar',
    'deportivo',
    'horror',
    'paranormal',
    'otro'
);


--
-- Name: generosex; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.generosex AS ENUM (
    'masculino',
    'fenemino',
    'otro'
);


--
-- Name: jerarquias_rol; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.jerarquias_rol AS ENUM (
    'productora',
    'direccion',
    'alto',
    'medio',
    'bajo'
);


--
-- Name: momentodia; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.momentodia AS ENUM (
    'dia',
    'noche',
    'amanecer',
    'atardecer',
    'amanecer/dia',
    'dia/noche'
);


--
-- Name: tipo_documento; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_documento AS ENUM (
    'CC',
    'TI',
    'NIT',
    'CE',
    'PA'
);


--
-- Name: vistalugar; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.vistalugar AS ENUM (
    'int',
    'ext',
    'int/ext',
    'ext/int'
);


--
-- Name: gen_id_actor(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_id_actor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.id_actor := 'act' || nextval('actor_seq');
    RETURN NEW;
END;
$$;


--
-- Name: gen_id_departamento(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_id_departamento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.id_departamento := 'area' || LPAD(nextval('departamento_seq')::text, 2, '0');
    RETURN NEW;
END;
$$;


--
-- Name: gen_id_escena(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_id_escena() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.id_escena := 'esc' || LPAD(nextval('escena_seq')::text, 3, '0');
    RETURN NEW;
END;
$$;


--
-- Name: gen_id_personaje(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.gen_id_personaje() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.id_personaje := 'cast' || nextval('personajes_seq');
    RETURN NEW;
END;
$$;


--
-- Name: generar_id_project(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generar_id_project() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN 'proj' || LPAD(nextval('project_seq')::TEXT, 4, '0');
END;
$$;


--
-- Name: actor_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.actor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: actors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.actors (
    id_actor text NOT NULL,
    nombre character varying(45) NOT NULL,
    apellido character varying(45) NOT NULL,
    genero public.generosex NOT NULL,
    fecha_de_nacimiento date NOT NULL,
    talla_zapatos character varying(10) NOT NULL,
    ancho_espalda character varying(30) NOT NULL,
    pecho character varying(30) NOT NULL,
    cintura character varying(30) NOT NULL,
    cadera character varying(30) NOT NULL,
    largo_manga character varying(30) NOT NULL,
    largo_pierna character varying(30) NOT NULL,
    talla_anillo text,
    contorno_cabeza character varying(30),
    contorno_cuello character varying(30),
    color_cabello character varying(45) NOT NULL,
    textura_cabello character varying(45) NOT NULL,
    tipo_piel character varying(45) NOT NULL,
    color_ojos character varying(45) NOT NULL,
    alergias text,
    habilidades_especiales text,
    restricciones text,
    comentarios_adicionales text,
    nacionalidad character varying(50) NOT NULL,
    doble_riesgo boolean NOT NULL,
    id_personaje text
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id_cliente integer NOT NULL,
    document public.tipo_documento NOT NULL,
    razon_social character varying(50) NOT NULL,
    representante_legal character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    address character varying(100) NOT NULL,
    telephone character varying(15),
    number_cellphone character varying(20) NOT NULL,
    id_document text
);


--
-- Name: clients_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clients_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clients_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clients_id_cliente_seq OWNED BY public.clients.id_cliente;


--
-- Name: departamento_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departamento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departamentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departamentos (
    id_departamento text NOT NULL,
    nombre character varying(45) NOT NULL,
    ubicacion text NOT NULL
);


--
-- Name: desglose_item_detalle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.desglose_item_detalle (
    id_detalle integer NOT NULL,
    id_desglose_item integer NOT NULL,
    etiqueta character varying(100) NOT NULL,
    cantidad integer,
    estado character varying(20) DEFAULT 'pendiente'::character varying NOT NULL,
    prioridad character varying(10),
    notas text,
    id_user_editor integer,
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: desglose_item_detalle_id_detalle_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.desglose_item_detalle_id_detalle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: desglose_item_detalle_id_detalle_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.desglose_item_detalle_id_detalle_seq OWNED BY public.desglose_item_detalle.id_detalle;


--
-- Name: desglose_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.desglose_items (
    id_desglose_item integer NOT NULL,
    id_escena text NOT NULL,
    id_departamento text,
    categoria character varying(50) NOT NULL,
    nombre_item text NOT NULL,
    cantidad integer,
    notas text,
    id_user_creador integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: desglose_items_id_desglose_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.desglose_items_id_desglose_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: desglose_items_id_desglose_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.desglose_items_id_desglose_item_seq OWNED BY public.desglose_items.id_desglose_item;


--
-- Name: desglose_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.desglose_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: desgloses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.desgloses (
    id_desglose text DEFAULT ('desg'::text || nextval('public.desglose_seq'::regclass)) NOT NULL,
    version character varying(50) NOT NULL,
    semana_grabacion integer,
    dia_rodaje integer,
    hora_inicio time without time zone,
    hora_fin time without time zone,
    location character varying(200),
    requerimientos text NOT NULL,
    activo boolean DEFAULT true
);


--
-- Name: escena_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.escena_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: escenas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escenas (
    id_escena text NOT NULL,
    numero_de_escena character varying(45) NOT NULL,
    encabezado text NOT NULL,
    descripcion text,
    id_guion integer,
    modo_vista public.vistalugar,
    momento_dia public.momentodia,
    ciudad text,
    pagina integer,
    fecha_de_grabacion date,
    dia_dramatico integer,
    id_rodaje text,
    id_desglose text,
    estado character varying(20) DEFAULT 'Pendiente'::character varying NOT NULL,
    locacion_rodaje text,
    tiempo_estimado text,
    hora_inicio_rodaje time without time zone,
    notas_rodaje text,
    orden_rodaje integer
);


--
-- Name: escenas_personajes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escenas_personajes (
    id_escena text NOT NULL,
    id_personaje text NOT NULL
);


--
-- Name: fotos_continuidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fotos_continuidad (
    id_foto integer NOT NULL,
    id_escena text NOT NULL,
    tipo_foto character varying(30) DEFAULT 'Set'::character varying NOT NULL,
    personaje_codigo character varying(30),
    descripcion text,
    notas_continuidad text,
    archivo_nombre character varying(255) NOT NULL,
    archivo_contenido bytea NOT NULL,
    archivo_tipo character varying(100) NOT NULL,
    archivo_tamano integer NOT NULL,
    fecha_subida timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: fotos_continuidad_id_foto_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fotos_continuidad_id_foto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fotos_continuidad_id_foto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fotos_continuidad_id_foto_seq OWNED BY public.fotos_continuidad.id_foto;


--
-- Name: guiones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guiones (
    id_guion integer NOT NULL,
    numero_de_version character varying(45) NOT NULL,
    fecha_de_emision date NOT NULL,
    estado public.estado_guion NOT NULL,
    archivo text,
    nombre character varying(100) NOT NULL,
    descripcion text,
    id_project text,
    archivo_nombre character varying(255),
    archivo_contenido bytea,
    archivo_tipo character varying(100),
    archivo_tamano integer
);


--
-- Name: guiones_id_guion_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.guiones_id_guion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: guiones_id_guion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.guiones_id_guion_seq OWNED BY public.guiones.id_guion;


--
-- Name: permiso_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permiso_seq
    START WITH 2001
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permisos (
    id_permiso integer DEFAULT nextval('public.permiso_seq'::regclass) NOT NULL,
    codigo character varying(50) NOT NULL,
    nombre character varying(100) NOT NULL,
    modulo character varying(50),
    descripcion text,
    activo boolean DEFAULT true
);


--
-- Name: personajes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personajes (
    id_personaje text NOT NULL,
    nombre character varying(45) NOT NULL,
    edad integer NOT NULL,
    codigo_personaje character varying(30) NOT NULL
);


--
-- Name: personajes_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personajes_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plan_rodaje_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plan_rodaje_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plan_rodaje; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plan_rodaje (
    id_rodaje text DEFAULT ('rod'::text || nextval('public.plan_rodaje_seq'::regclass)) NOT NULL,
    version character varying(50) NOT NULL,
    semana_grabacion integer,
    dia_rodaje integer,
    hora_inicio time without time zone,
    hora_fin time without time zone,
    location character varying(200),
    notas text,
    activo boolean DEFAULT true
);


--
-- Name: project_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id_project character varying(20) DEFAULT public.generar_id_project() NOT NULL,
    project_name character varying(45) NOT NULL,
    formato_de_produccion public.formatos NOT NULL,
    genero public.generos,
    sinopsis text,
    director character varying NOT NULL,
    id_client integer
);


--
-- Name: rol_has_permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rol_has_permisos (
    rol_idrol integer NOT NULL,
    permisos_idpermiso integer NOT NULL
);


--
-- Name: rol_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rol_seq
    START WITH 1001
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id_rol integer DEFAULT nextval('public.rol_seq'::regclass) NOT NULL,
    nombre character varying(45) NOT NULL,
    nivel_jerarquia public.jerarquias_rol NOT NULL,
    descripcion text NOT NULL,
    activo boolean DEFAULT true
);


--
-- Name: user_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_projects (
    id integer NOT NULL,
    id_user integer NOT NULL,
    id_project character varying NOT NULL,
    id_rol integer DEFAULT 1005 NOT NULL,
    fecha_vinculacion timestamp without time zone DEFAULT now()
);


--
-- Name: user_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_projects_id_seq OWNED BY public.user_projects.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id_user bigint NOT NULL,
    nombre character varying(255) NOT NULL,
    apellido character varying(255) NOT NULL,
    identificacion public.tipo_documento NOT NULL,
    id_identificacion text NOT NULL,
    mail character varying(255) NOT NULL,
    msisdn text NOT NULL,
    direccion text,
    fecha_de_nacimiento date,
    estado character varying(255) NOT NULL,
    fecha_de_creacion timestamp with time zone NOT NULL,
    ultimo_acceso timestamp with time zone NOT NULL,
    contrasena character varying(255) NOT NULL,
    id_departamento character varying(255),
    id_project text,
    id_rol bigint
);


--
-- Name: users_id_user_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_user_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_user_seq OWNED BY public.users.id_user;


--
-- Name: clients id_cliente; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients ALTER COLUMN id_cliente SET DEFAULT nextval('public.clients_id_cliente_seq'::regclass);


--
-- Name: desglose_item_detalle id_detalle; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_item_detalle ALTER COLUMN id_detalle SET DEFAULT nextval('public.desglose_item_detalle_id_detalle_seq'::regclass);


--
-- Name: desglose_items id_desglose_item; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_items ALTER COLUMN id_desglose_item SET DEFAULT nextval('public.desglose_items_id_desglose_item_seq'::regclass);


--
-- Name: fotos_continuidad id_foto; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fotos_continuidad ALTER COLUMN id_foto SET DEFAULT nextval('public.fotos_continuidad_id_foto_seq'::regclass);


--
-- Name: guiones id_guion; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guiones ALTER COLUMN id_guion SET DEFAULT nextval('public.guiones_id_guion_seq'::regclass);


--
-- Name: user_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects ALTER COLUMN id SET DEFAULT nextval('public.user_projects_id_seq'::regclass);


--
-- Name: users id_user; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id_user SET DEFAULT nextval('public.users_id_user_seq'::regclass);


--
-- Name: actors actors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actors
    ADD CONSTRAINT actors_pkey PRIMARY KEY (id_actor);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id_cliente);


--
-- Name: departamentos departamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departamentos
    ADD CONSTRAINT departamentos_pkey PRIMARY KEY (id_departamento);


--
-- Name: desglose_item_detalle desglose_item_detalle_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_item_detalle
    ADD CONSTRAINT desglose_item_detalle_pkey PRIMARY KEY (id_detalle);


--
-- Name: desglose_items desglose_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_items
    ADD CONSTRAINT desglose_items_pkey PRIMARY KEY (id_desglose_item);


--
-- Name: desgloses desgloses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desgloses
    ADD CONSTRAINT desgloses_pkey PRIMARY KEY (id_desglose);


--
-- Name: escenas_personajes escenas_personajes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escenas_personajes
    ADD CONSTRAINT escenas_personajes_pkey PRIMARY KEY (id_escena, id_personaje);


--
-- Name: escenas escenas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escenas
    ADD CONSTRAINT escenas_pkey PRIMARY KEY (id_escena);


--
-- Name: fotos_continuidad fotos_continuidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fotos_continuidad
    ADD CONSTRAINT fotos_continuidad_pkey PRIMARY KEY (id_foto);


--
-- Name: guiones guiones_numero_de_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guiones
    ADD CONSTRAINT guiones_numero_de_version_key UNIQUE (numero_de_version);


--
-- Name: guiones guiones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guiones
    ADD CONSTRAINT guiones_pkey PRIMARY KEY (id_guion);


--
-- Name: permisos permisos_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_codigo_key UNIQUE (codigo);


--
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id_permiso);


--
-- Name: personajes personajes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personajes
    ADD CONSTRAINT personajes_pkey PRIMARY KEY (id_personaje);


--
-- Name: plan_rodaje plan_rodaje_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_rodaje
    ADD CONSTRAINT plan_rodaje_pkey PRIMARY KEY (id_rodaje);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id_project);


--
-- Name: rol_has_permisos rol_has_permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_has_permisos
    ADD CONSTRAINT rol_has_permisos_pkey PRIMARY KEY (rol_idrol, permisos_idpermiso);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_rol);


--
-- Name: user_projects user_projects_id_user_id_project_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects
    ADD CONSTRAINT user_projects_id_user_id_project_key UNIQUE (id_user, id_project);


--
-- Name: user_projects user_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects
    ADD CONSTRAINT user_projects_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id_user);


--
-- Name: idx_fotos_continuidad_id_escena; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fotos_continuidad_id_escena ON public.fotos_continuidad USING btree (id_escena);


--
-- Name: idx_permisos_codigo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permisos_codigo ON public.permisos USING btree (codigo);


--
-- Name: idx_permisos_modulo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permisos_modulo ON public.permisos USING btree (modulo);


--
-- Name: ix_desglose_item_detalle_id_detalle; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_desglose_item_detalle_id_detalle ON public.desglose_item_detalle USING btree (id_detalle);


--
-- Name: ix_desglose_items_id_desglose_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_desglose_items_id_desglose_item ON public.desglose_items USING btree (id_desglose_item);


--
-- Name: ix_fotos_continuidad_id_foto; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_fotos_continuidad_id_foto ON public.fotos_continuidad USING btree (id_foto);


--
-- Name: actors trg_id_actor; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_id_actor BEFORE INSERT ON public.actors FOR EACH ROW EXECUTE FUNCTION public.gen_id_actor();


--
-- Name: departamentos trg_id_departamento; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_id_departamento BEFORE INSERT ON public.departamentos FOR EACH ROW EXECUTE FUNCTION public.gen_id_departamento();


--
-- Name: escenas trg_id_escena; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_id_escena BEFORE INSERT ON public.escenas FOR EACH ROW EXECUTE FUNCTION public.gen_id_escena();


--
-- Name: personajes trg_id_personaje; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_id_personaje BEFORE INSERT ON public.personajes FOR EACH ROW EXECUTE FUNCTION public.gen_id_personaje();


--
-- Name: desglose_item_detalle desglose_item_detalle_id_desglose_item_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_item_detalle
    ADD CONSTRAINT desglose_item_detalle_id_desglose_item_fkey FOREIGN KEY (id_desglose_item) REFERENCES public.desglose_items(id_desglose_item) ON DELETE CASCADE;


--
-- Name: desglose_item_detalle desglose_item_detalle_id_user_editor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_item_detalle
    ADD CONSTRAINT desglose_item_detalle_id_user_editor_fkey FOREIGN KEY (id_user_editor) REFERENCES public.users(id_user);


--
-- Name: desglose_items desglose_items_id_departamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_items
    ADD CONSTRAINT desglose_items_id_departamento_fkey FOREIGN KEY (id_departamento) REFERENCES public.departamentos(id_departamento);


--
-- Name: desglose_items desglose_items_id_escena_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_items
    ADD CONSTRAINT desglose_items_id_escena_fkey FOREIGN KEY (id_escena) REFERENCES public.escenas(id_escena) ON DELETE CASCADE;


--
-- Name: desglose_items desglose_items_id_user_creador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.desglose_items
    ADD CONSTRAINT desglose_items_id_user_creador_fkey FOREIGN KEY (id_user_creador) REFERENCES public.users(id_user);


--
-- Name: actors fk_actor_personaje; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actors
    ADD CONSTRAINT fk_actor_personaje FOREIGN KEY (id_personaje) REFERENCES public.personajes(id_personaje) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: escenas fk_escenas_desglose; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escenas
    ADD CONSTRAINT fk_escenas_desglose FOREIGN KEY (id_desglose) REFERENCES public.desgloses(id_desglose) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: escenas fk_escenas_guion; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escenas
    ADD CONSTRAINT fk_escenas_guion FOREIGN KEY (id_guion) REFERENCES public.guiones(id_guion) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: escenas_personajes fk_escenas_personajes_escena; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escenas_personajes
    ADD CONSTRAINT fk_escenas_personajes_escena FOREIGN KEY (id_escena) REFERENCES public.escenas(id_escena) ON DELETE CASCADE;


--
-- Name: escenas_personajes fk_escenas_personajes_personaje; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escenas_personajes
    ADD CONSTRAINT fk_escenas_personajes_personaje FOREIGN KEY (id_personaje) REFERENCES public.personajes(id_personaje) ON DELETE CASCADE;


--
-- Name: escenas fk_escenas_rodaje; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escenas
    ADD CONSTRAINT fk_escenas_rodaje FOREIGN KEY (id_rodaje) REFERENCES public.plan_rodaje(id_rodaje) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: guiones fk_guion_project; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guiones
    ADD CONSTRAINT fk_guion_project FOREIGN KEY (id_project) REFERENCES public.projects(id_project) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: projects fk_project_client; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_project_client FOREIGN KEY (id_client) REFERENCES public.clients(id_cliente) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: rol_has_permisos fk_rol_has_permisos_permisos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_has_permisos
    ADD CONSTRAINT fk_rol_has_permisos_permisos FOREIGN KEY (permisos_idpermiso) REFERENCES public.permisos(id_permiso) ON DELETE CASCADE;


--
-- Name: rol_has_permisos fk_rol_has_permisos_rol; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rol_has_permisos
    ADD CONSTRAINT fk_rol_has_permisos_rol FOREIGN KEY (rol_idrol) REFERENCES public.roles(id_rol) ON DELETE CASCADE;


--
-- Name: users fk_users_departamento; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_departamento FOREIGN KEY (id_departamento) REFERENCES public.departamentos(id_departamento) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users fk_users_rol; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_rol FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fotos_continuidad fotos_continuidad_id_escena_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fotos_continuidad
    ADD CONSTRAINT fotos_continuidad_id_escena_fkey FOREIGN KEY (id_escena) REFERENCES public.escenas(id_escena) ON DELETE CASCADE;


--
-- Name: user_projects user_projects_id_project_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects
    ADD CONSTRAINT user_projects_id_project_fkey FOREIGN KEY (id_project) REFERENCES public.projects(id_project) ON DELETE CASCADE;


--
-- Name: user_projects user_projects_id_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_projects
    ADD CONSTRAINT user_projects_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict RW3sOgMdk484egD1ALFFgHzkzky9SjGnAKDshF66HjfefEAghZzFh0RvdPKhIdI

--
-- PostgreSQL database dump
--

\restrict VNCJNTIyvE4LKYrhphYZJ3xgaOXdYIAjTNtkZ2IAi2vbCB6QEaddty46ambOR00

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6 (Debian 18.6-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id_rol, nombre, nivel_jerarquia, descripcion, activo) FROM stdin;
1001	Administrador	productora	Control total del sistema	t
1002	Director	direccion	Aprueba y supervisa producción	t
1003	Jefe de Departamento	alto	Gestiona su departamento	t
1004	Onset	medio	Sube y consulta información en producción	t
1005	Usuario	bajo	Solo consulta información	t
\.


--
-- PostgreSQL database dump complete
--

\unrestrict VNCJNTIyvE4LKYrhphYZJ3xgaOXdYIAjTNtkZ2IAi2vbCB6QEaddty46ambOR00

