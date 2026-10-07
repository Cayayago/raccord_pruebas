# Raccord

Herramienta de gestión de producción audiovisual (continuidad, guiones, escenas, desglose, plan de rodaje, cast).

```
Raccord_Codigo/
├── raccord_backend/api_usuarios/   # API FastAPI + PostgreSQL
├── raccord_flutter/                # Frontend Flutter (web + móvil) — la app real, con login
├── Landing_pages/                  # Landing page de marketing (HTML/CSS/JS plano, sin build)
└── docker-compose.yml              # Levanta todo el stack con un solo comando
```

Esta guía asume que la persona que la sigue **no tiene experiencia previa** con estas herramientas. Si ya conoces Docker/Python/Flutter, puedes saltar directo a la sección 5.

---

## 1. Requisitos previos (instalación)

Se necesitan 2 programas obligatorios (Docker y Git) y 2 opcionales (Python y Flutter, solo si vas a **programar**, no solo a correr el proyecto).

### 1.1 Docker Desktop (obligatorio)

Es el programa que corre la base de datos, el backend y el frontend sin que tengas que instalar nada más en tu computador.

**Windows:**
1. Entra a https://www.docker.com/products/docker-desktop/ y descarga "Docker Desktop for Windows".
2. Docker necesita WSL2. Si tu Windows no lo tiene activado, abre PowerShell **como administrador** (clic derecho → "Ejecutar como administrador") y corre:
   ```powershell
   wsl --install
   ```
   Reinicia el computador cuando te lo pida.
3. Ejecuta el instalador de Docker Desktop que descargaste y sigue los pasos (dejar todo por defecto).
4. Abre la aplicación "Docker Desktop" desde el menú de inicio y espera a que el ícono de la ballena en la barra de tareas deje de animarse (significa que ya está listo).

**Mac:**
1. Entra a https://www.docker.com/products/docker-desktop/ y descarga la versión para Mac (elige "Apple Silicon" si tu Mac es M1/M2/M3, o "Intel" si es más antiguo — lo puedes ver en el menú  → Acerca de este Mac).
2. Abre el archivo `.dmg` descargado y arrastra Docker a la carpeta Aplicaciones.
3. Abre Docker desde Aplicaciones y espera a que termine de iniciar.

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```
Cierra sesión y vuelve a entrar para que el permiso de grupo tome efecto.

**Verificar que quedó instalado** (en cualquier sistema operativo, abre una terminal — en Windows es "PowerShell", en Mac es "Terminal"):
```bash
docker --version
docker compose version
```
Si ambos comandos responden con un número de versión (y no un error de "comando no encontrado"), quedó listo.

### 1.2 Git (obligatorio)

Es el programa que descarga (clona) el código del proyecto.

- **Windows:** descarga el instalador de https://git-scm.com/download/win y ejecútalo dejando las opciones por defecto.
- **Mac:** abre Terminal y escribe `git --version` — si no lo tienes, macOS te ofrecerá instalarlo automáticamente (herramientas de línea de comandos de Xcode).
- **Linux:** `sudo apt install git`

Verificar:
```bash
git --version
```

### 1.3 Python (opcional — solo si vas a programar el backend fuera de Docker)

Para correr el proyecto normalmente **no hace falta**, porque el backend corre dentro de un contenedor Docker que ya trae Python. Instálalo solo si vas a escribir/probar código del backend directamente en tu máquina.

1. Descarga Python 3.11 o superior de https://www.python.org/downloads/
2. **Windows:** en el instalador, marca la casilla **"Add python.exe to PATH"** antes de darle a "Install Now" — es el error más común, si no la marcas, `python` no funcionará en la terminal.
3. Verificar:
   ```bash
   python --version
   ```
   (en Mac/Linux a veces el comando es `python3` en vez de `python`)

### 1.4 Flutter SDK (opcional — solo si vas a programar el frontend o compilar la app móvil)

Para ver la app funcionando **no hace falta**, porque la versión web corre dentro de Docker. Instálalo solo si vas a modificar código del frontend, o si necesitas generar el instalable de Android (`.apk`) o iOS.

1. Sigue la guía oficial paso a paso para tu sistema operativo: https://docs.flutter.dev/get-started/install (elige Windows, Mac o Linux).
2. Al final de la instalación, agrega la carpeta `flutter/bin` a la variable de entorno `PATH` de tu sistema (la guía oficial explica cómo, según el sistema operativo).
3. Verificar que todo quedó bien instalado:
   ```bash
   flutter doctor
   ```
   Este comando revisa tu instalación y te dice qué falta (por ejemplo, Android Studio si vas a compilar para Android). Para correr la app en el navegador no necesitas resolver los ítems de Android/iOS, solo que diga "Flutter" con un check ✓ verde.

---

## 2. Clonar el repositorio

Abre una terminal en la carpeta donde quieras guardar el proyecto y corre:

```bash
git clone <URL-del-repositorio> Raccord_Codigo
cd Raccord_Codigo
```

Reemplaza `<URL-del-repositorio>` por la URL real (pídesela a quien administre el control de versiones si no la tienes).

---

## 3. Configurar variables de entorno

El archivo `raccord_backend/api_usuarios/.env` **no viaja con el repositorio** (está en `.gitignore` a propósito, porque contiene contraseñas y llaves reales). Hay que crearlo a mano la primera vez en cada máquina.

**Windows (PowerShell):**
```powershell
cd raccord_backend\api_usuarios
Copy-Item .env.example .env
```

**Mac/Linux:**
```bash
cd raccord_backend/api_usuarios
cp .env.example .env
```

Abre el archivo `.env` recién creado con cualquier editor de texto (Bloc de notas, VS Code, etc.) y completa los valores reales:

```
DB_HOST=localhost
DB_PORT=5432
DB_USER=<usuario de la base de datos>
DB_PASSWORD=<contraseña de la base de datos>
DB_NAME=raccord

MAIL_USER=<correo que envía los códigos de verificación y recuperación>
MAIL_PASSWORD=<contraseña de aplicación de ese correo>
CONTACT_EMAIL=<correo que recibe los mensajes del formulario de contacto>

SECRET_KEY=<clave secreta para firmar los JWT>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

MINIO_ENDPOINT=localhost:9000
MINIO_PUBLIC_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=raccord_admin
MINIO_SECRET_KEY=raccord_minio_2026
MINIO_SECURE=false
```

> Las variables `MINIO_*` solo se usan si corres el backend **fuera** de Docker (sección 6). Levantando todo con `docker compose up -d --build` (sección 4) ya quedan configuradas solas en `docker-compose.yml`, no hay que tocar nada acá.

**`SECRET_KEY`**: debe ser un valor largo y aleatorio, distinto por entorno. Si tienes Python instalado, se genera uno con:
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```
Copia el resultado y pégalo como valor de `SECRET_KEY`.

Pide el resto de valores reales (contraseña de BD, credenciales de correo) a quien tenga acceso al `.env` actual — nunca se deben compartir por canales inseguros ni subir al repositorio.

---

## 4. Levantar el proyecto con Docker (forma recomendada)

Este es el método normal para correr el proyecto completo (base de datos + backend + frontend web) sin instalar Python ni Flutter.

Desde la raíz del repositorio (la carpeta `Raccord_Codigo`):

```bash
docker compose up -d --build
```

La primera vez tarda varios minutos (descarga las imágenes base de Python, Flutter y nginx). Las siguientes veces es mucho más rápido.

Cuando termine, revisa que los 6 servicios estén corriendo:
```bash
docker compose ps
```

Y accede desde el navegador:

| Servicio | URL | Descripción |
|---|---|---|
| Landing (marketing) | http://localhost:8082 | Página pública de presentación, con botón "Ingresar" al login y formulario de contacto |
| Frontend (Flutter Web) | http://localhost:8081 | La app real (login, proyectos, guiones, escenas, etc.) |
| Backend (API) | http://localhost:8000 | FastAPI |
| Adminer | http://localhost:8080 | Administrar la base de datos desde el navegador |
| PostgreSQL | localhost:5432 | Base de datos (se conecta con un cliente de BD, no desde el navegador) |
| MinIO (consola) | http://localhost:9001 | Ver/administrar los PDFs de guiones y fotos de continuidad. Usuario/contraseña: los valores de `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` (por defecto `raccord_admin` / `raccord_minio_2026`, ver `docker-compose.yml`) |

> Nota para el equipo de desarrollo original: si esta es la máquina donde ya existía un contenedor `postgres-db` corriendo desde antes (creado con `docker run`, con datos reales), hay que liberar ese nombre **una sola vez** antes del primer `docker compose up` (esto no borra los datos, solo el contenedor):
> ```bash
> docker rm -f postgres-db adminer
> ```

### 4.1 Máquina nueva sin datos previos

Si esta es una máquina completamente nueva (nadie ha corrido el proyecto ahí antes), la base de datos arrancará vacía. Hace falta cargar el esquema completo (tablas, tipos, triggers) una vez. Consulta con el equipo si ya existe un archivo de respaldo (`sql/000_schema_completo.sql`); si no existe todavía, pídanle a quien tenga la base de datos original que genere ese respaldo antes de desplegar en una máquina nueva.

Los buckets de MinIO (`guiones`, `imagenes`, `perfiles`) no necesitan nada manual: el backend los crea solos la primera vez que arranca.

### 4.2 Almacenamiento de archivos (MinIO)

Los PDFs de guiones, las fotos de continuidad y las fotos de perfil **no** se guardan en PostgreSQL — se suben a [MinIO](https://min.io/) (almacenamiento de objetos compatible con S3), otro contenedor más del mismo `docker-compose.yml`, en tres buckets separados:

| Bucket | Contenido |
|---|---|
| `guiones` | PDFs de guiones (`POST /scripts/{id}/archivo`) |
| `imagenes` | Fotos de continuidad (`POST /scenes/{id_escena}/fotos`) |
| `perfiles` | Fotos de perfil de usuario (`POST /users/me/foto`) |

En Postgres solo queda guardada la ruta del archivo (`archivo_key` / `foto_perfil_key`) y los metadatos (nombre, tipo, tamaño) — nunca el binario. Al pedir un archivo (`GET /scripts/{id}/archivo`, `GET /fotos/{id_foto}/archivo` o `GET /users/{id}/foto`), el backend valida el permiso como siempre y **sirve el archivo él mismo** (descarga el binario de MinIO y lo devuelve en la respuesta) en vez de redirigir a una URL de MinIO — así el navegador nunca pide el archivo directo al puerto de MinIO, lo que evita problemas de CORS entre dominios distintos.

### 4.3 Landing page (marketing)

La carpeta `Landing_pages/` es la página pública que presenta el producto (home, nosotros, servicios, contacto) — **deliberadamente NO** está hecha en Flutter ni en React/Vite:

- Es contenido de marketing, casi todo estático. Lo único dinámico es el formulario de contacto.
- Necesita cargar rápido y ser indexable por buscadores (SEO) — algo en lo que Flutter Web es especialmente malo (renderiza todo sobre un `<canvas>`, sin HTML real que Google pueda leer).
- Sin build ni `node_modules`: es HTML + CSS + JavaScript vanilla, servido tal cual por un nginx propio (`Landing_pages/Dockerfile` + `nginx.conf`). Menos dependencias que mantener/parchear.

La app real (login, proyectos, todo lo demás) sigue siendo Flutter Web, servida por el contenedor `frontend` — la landing solo enlaza hacia allá con el botón "Ingresar" (`/login`).

**Archivos:**

```
Landing_pages/
├── Main.html      # Contenido (se sirve como index.html)
├── Styles.css      # Estilos (ojo: nombre con S mayúscula, importa en Linux)
├── assets/         # Logos + imagen de fondo del hero, empaquetados localmente
├── Dockerfile
└── nginx.conf
```

**Formulario de contacto:** el `<form>` de la sección Contacto hace un `fetch` real a `POST /contact` del backend (`raccord_backend/app/routes/contact_routes.py`), que envía un correo a `CONTACT_EMAIL` (ver sección 3, ya está en el `.env`) usando `send_contact_email` en `app/utils/mail.py`. Incluye un campo honeypot oculto (protección anti-spam silenciosa) y validación de formato de correo en el schema (`ContactSchema`).

**Dos valores se inyectan al construir la imagen** (no hay bundler que lea variables de entorno en tiempo de ejecución, así que un `sed` en el `Dockerfile` reemplaza estos tokens en el HTML):

| Build arg | Para qué | Valor por defecto (local) |
|---|---|---|
| `API_BASE_URL` | A dónde apunta el `fetch` del formulario de contacto | `http://127.0.0.1:8000` |
| `APP_URL` | A dónde lleva el botón "Ingresar" (`/login`) | `http://localhost:8081` |

Al desplegar en dominios reales, reconstruye pasando los valores correctos:
```bash
docker compose build landing \
  --build-arg API_BASE_URL=https://api.tu-dominio.com \
  --build-arg APP_URL=https://app.tu-dominio.com
```
(o edítalos directamente en `docker-compose.yml`, dentro de `services.landing.build.args`).

> En `localhost`, el CORS del backend ya acepta cualquier puerto (`allow_origin_regex` en `app/main.py`), así que en desarrollo no hay que tocar nada de CORS. En producción, agrega el dominio real de la landing a `allow_origins` en ese mismo archivo.

---

## 5. Comandos del día a día (Docker)

| Acción | Comando |
|---|---|
| Levantar todo | `docker compose up -d` |
| Levantar reconstruyendo (tras cambios de código) | `docker compose up -d --build` |
| Reconstruir solo un servicio | `docker compose up -d --build backend` (o `frontend`, `landing`) |
| Reconstruir sin usar caché (por si algo quedó raro) | `docker compose build --no-cache <servicio>` |
| Parar todo (sin borrar datos) | `docker compose down` |
| Pausar sin eliminar contenedores | `docker compose stop` / `docker compose start` |
| Ver logs en vivo | `docker compose logs -f` |
| Ver logs de un solo servicio | `docker compose logs -f backend` |
| Ver qué está corriendo | `docker compose ps` |

`docker compose down` **no borra el volumen de datos** de Postgres — la base de datos sobrevive a reinicios y reconstrucciones normales.

---

## 6. Desarrollo local sin Docker (opcional, para programadores)

Si vas a modificar el código y prefieres correrlo directo en tu máquina (más rápido para iterar que reconstruir la imagen de Docker cada vez), aquí están los comandos. Requiere haber instalado Python y/o Flutter (sección 1).

### 6.1 Backend (Python / FastAPI)

```bash
cd raccord_backend/api_usuarios
```

Crear un entorno virtual (una carpeta aislada con las dependencias del proyecto, para no mezclar con otros proyectos de Python en tu máquina):
```bash
python -m venv venv
```

Activar el entorno virtual:
- **Windows (PowerShell):** `venv\Scripts\activate`
- **Mac/Linux:** `source venv/bin/activate`

Verás que el nombre `(venv)` aparece al inicio de la línea de la terminal cuando está activo.

Instalar las dependencias del proyecto:
```bash
pip install -r requirements.txt
```
> En Windows, si `pip install` falla con un error de "Control de aplicaciones" bloqueando `pip.exe`, usa en su lugar:
> ```powershell
> python -m pip install -r requirements.txt
> ```

Correr el servidor en modo desarrollo (se reinicia solo cada vez que guardas un cambio):
```bash
uvicorn app.main:app --reload
```
El backend queda disponible en http://localhost:8000. Para esto necesitas también tener una base de datos PostgreSQL y MinIO accesibles con los datos del `.env` (puedes seguir usando los de Docker: `docker compose up -d db minio`, y dejar `DB_HOST=localhost`/`MINIO_ENDPOINT=localhost:9000` en el `.env`, ya que los puertos 5432 y 9000 quedan publicados al sistema).

Para salir del entorno virtual cuando termines: `deactivate`

### 6.2 Frontend (Flutter)

```bash
cd raccord_flutter
```

Instalar las dependencias del proyecto (equivalente a `npm install` en otros lenguajes):
```bash
flutter pub get
```

Correr la app en modo desarrollo con recarga en caliente:
```bash
flutter run -d chrome
```
Esto abre la app en una ventana de Chrome y refleja los cambios de código casi al instante al guardar (hot reload).

Por defecto la app intenta conectarse al backend en `http://127.0.0.1:8000`. Si el backend corre en otra dirección, sobreescribe con:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://otra-direccion:8000
```

**Generar el instalable de Android** (requiere Android Studio/SDK, ver `flutter doctor`):
```bash
flutter build apk --release
```
El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.

**Generar la app de iOS** (requiere Mac con Xcode):
```bash
flutter build ios --release
```

**Generar solo la versión web** (esto es lo que hace el contenedor de Docker automáticamente):
```bash
flutter build web --release
```
El resultado queda en `build/web/`.

---

## 7. Notas y solución de problemas

**Cambios de código no se reflejan (usando Docker):** hay que reconstruir la imagen del servicio que cambió (`docker compose up -d --build <servicio>`), no solo reiniciarlo. Para el frontend, si el navegador sigue mostrando la versión anterior después de reconstruir, hace falta limpiar el caché del sitio una vez (DevTools del navegador → pestaña Application → Storage → botón "Clear site data").

**Puerto ya en uso:** si algún puerto (8000, 8080, 8081, 5432) ya está ocupado por otro programa en la máquina, `docker compose up` fallará. Hay que cerrar ese programa o cambiar el mapeo de puertos en `docker-compose.yml` (por ejemplo `"8082:80"` en vez de `"8081:80"`).

**Correo (2FA, recuperación de contraseña, formulario de contacto de la landing):** requiere que `MAIL_USER`/`MAIL_PASSWORD`/`CONTACT_EMAIL` en el `.env` sean válidos y que la máquina tenga salida a internet.

**Adminer:** para conectarte a la base desde http://localhost:8080, el campo "Servidor" debe ser `db` (el nombre del servicio en `docker-compose.yml`), no `localhost`.

**`flutter doctor` marca errores de Android/iOS:** no es necesario resolverlos si solo vas a correr/compilar la versión web. Esos ítems solo son obligatorios para compilar `.apk` o la app de iOS.

**Un PDF o foto no carga / da 404:** el backend sirve estos archivos él mismo (los descarga de MinIO y los devuelve en la respuesta, ver sección 4.2), así que el navegador nunca habla directo con MinIO para esto — revisa que el contenedor `raccord-minio` esté corriendo (`docker compose ps`) y que las variables `MINIO_ENDPOINT`/`MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY` del backend sean correctas (`docker compose logs -f backend` suele mostrar el error real si no logra conectarse).

**Falla `docker compose build` con un error de "no such host" / no resuelve `registry-1.docker.io`:** no es un problema del proyecto, es que la máquina no tenía internet en ese momento (Docker necesita bajar/verificar las imágenes base la primera vez). Recupera la conexión y reintenta el mismo comando. Una vez las imágenes están construidas, `docker compose up` con los contenedores ya armados **sí funciona sin internet** — excepto el mapa de Google Maps embebido en la sección de Contacto de la landing, que necesita conexión para cargar (si no hay internet, ese recuadro queda en blanco, pero no rompe nada más).

**La landing se ve sin estilos o sin logos:** si editaste `Landing_pages/Main.html` o `Styles.css` a mano, revisa que las rutas respeten mayúsculas/minúsculas exactas (`Styles.css`, no `styles.css`) — en Windows no se nota porque el sistema de archivos no distingue mayúsculas, pero el nginx del contenedor corre en Linux y ahí sí importa. Los logos y la imagen de fondo del hero deben vivir dentro de `Landing_pages/assets/` para quedar empaquetados en la imagen; no uses URLs externas (a un repo de GitHub, por ejemplo) como `src` de una imagen — si ese recurso externo cambia de lugar o el repo es privado, la imagen se rompe sin que el proyecto tenga ningún error.

---

## 8. Arquitectura y seguridad (resumen)

- **Autenticación:** JWT (HS256, `python-jose`), firmado con `SECRET_KEY` y expiración configurable (`ACCESS_TOKEN_EXPIRE_MINUTES`). Login con 2FA por código enviado a correo.
- **Contraseñas:** hasheadas con bcrypt (`passlib`), nunca se guardan ni se transmiten en texto plano.
- **Aislamiento de datos por proyecto:** todo el contenido de producción (guiones, escenas, personajes, actores, desglose, plan de rodaje, galería, crew) queda asociado a un `id_project`, y cada endpoint valida que el usuario autenticado pertenezca a ese proyecto antes de responder — un usuario nunca puede ver ni modificar datos de un proyecto ajeno.
- **Permisos por rol efectivo:** el rol que decide qué puede hacer un usuario es el que tiene **dentro de cada proyecto** (`user_projects.id_rol`), no un rol global fijo — la misma persona puede tener distinto rol en distintos proyectos.
- **Archivos binarios:** PDFs de guiones y fotos (continuidad y perfil) se almacenan en MinIO (S3-compatible), no en la base de datos; el backend intermedia toda descarga para evitar exponer MinIO directamente al navegador.
- **Correo:** SMTP directo contra Gmail (STARTTLS) para recuperación de contraseña, 2FA, invitaciones, bienvenida y el formulario de contacto de la landing.
- **Landing separada de la app:** `Landing_pages/` (marketing, público, sin login) y `raccord_flutter/` (la app, autenticada) son dos despliegues independientes que solo se tocan en dos puntos: el botón "Ingresar" de la landing enlaza a `/login` de la app, y el formulario de contacto de la landing llama a `POST /contact` del mismo backend que usa la app. Ningún dato de sesión ni de proyecto se comparte entre ambas.
- **Endpoint de contacto sin autenticación:** `POST /contact` es el único endpoint público del backend (lo llama cualquier visitante de la landing, sin login). Por eso valida el formato del correo (`EmailStr`), limita la longitud de todos los campos, y descarta en silencio los envíos que llenan un campo honeypot oculto (spam automatizado) sin delatarle al bot que fue bloqueado.
