# Raccord — App Flutter (multiplataforma)

Reinicio del frontend de Raccord en Flutter, para tener una sola base de
código para Android, iOS, Web y Desktop, en reemplazo del frontend React
(`Raccord_Codigo/raccord_frontend`).

## Qué incluye

- Autenticación completa contra `api_usuarios`: login, 2FA (check/send/verify),
  registro de empresa + usuario, recuperación y reseteo de contraseña.
- Selección y creación de proyectos (`/projects`, `/projects/create`,
  `/users/{id}/projects`).
- Dashboard del proyecto con menú de los 8 módulos del mockup.
- Roles del equipo + invitar personas (`/users/project/{id}`, `/users/invite`).
- Guiones, Escenas, Personajes, ficha técnica de Actor, Crew List, Plan de
  Rodaje, Desglose de producción y Galería de fotos de continuidad — todos
  conectados a los endpoints reales del backend (`/scripts`, `/scenes`,
  `/characters`, `/actors`, `/shooting-days`, `/breakdown/*`,
  `/gallery-photos`).
- Perfil de usuario (ver/editar).
- Paleta de marca tomada de `LandingScreen.css` y logos/tipografía tomados de
  `Marketing/Logos` y `Marketing/Fuentes`.

### Aislamiento de datos por proyecto y permisos

Todos los módulos de contenido (escenas, guiones, personajes, actores,
desglose, plan de rodaje, galería) están *scoped* al proyecto activo: cada
petición al backend viaja con `id_project` y el backend valida que el
usuario pertenezca a ese proyecto antes de responder — nadie ve datos de un
proyecto ajeno solo por adivinar un ID.

Además, `AuthSession.can()` (`lib/core/session.dart`) resuelve permisos
usando el **rol efectivo del usuario en el proyecto activo**
(`user_projects.id_rol`), no su rol global de la cuenta. Esto permite que la
misma persona sea, por ejemplo, Administrador en su propio proyecto y Onset
en un proyecto ajeno al que fue invitada, con los permisos correctos en cada
uno.

## Cómo correrlo

Este proyecto se generó a mano (sin `flutter create`) porque el sandbox donde
se escribió no tenía salida de red hacia el SDK de Flutter. Antes de abrirlo:

```bash
cd raccord_flutter
flutter create .          # regenera android/, ios/, web/, etc. sin tocar lib/
flutter pub get
flutter run                # o: flutter run -d chrome
```

`flutter create .` es seguro de ejecutar sobre una carpeta con `lib/` y
`pubspec.yaml` ya existentes: solo agrega el andamiaje nativo que falta, no
sobreescribe tu código.

### Apuntar al backend

Por defecto la app usa `http://127.0.0.1:8000` (igual que el `.env.example`
del backend). Para otro origen (dispositivo físico, backend remoto, emulador
Android):

```bash
flutter run --dart-define=API_BASE_URL=http://TU_IP_O_DOMINIO:8000
```

En emulador Android, si no pasas `API_BASE_URL`, la app ya apunta
automáticamente a `http://10.0.2.2:8000` (el alias que usa el emulador para
el localhost de tu máquina).

Recuerda agregar el origen que uses a `allow_origins` en el CORS del backend
(`app/main.py`) si es distinto a `localhost:3000` / `localhost:5173`.

## Estructura

```
lib/
  core/       cliente HTTP, sesión (JWT + proyecto activo), permisos, utils
  models/     modelos de datos (parseo tolerante del JSON de la API)
  services/   una clase por recurso de la API (auth, project, role, ...)
  theme/      colores y ThemeData de marca
  widgets/    componentes compartidos (AppScaffold, ModuleCard, campos, ...)
  screens/    una carpeta por módulo, replicando los mockups de Marketing/Mockup
```

## Pendiente / próximos pasos sugeridos

- Reemplazar el wordmark "Raccord" (dibujado con texto + gradiente) por el
  archivo de fuente real del logotipo cuando esté disponible en
  `Marketing/Fuentes`.
- Sumar tests de widget para los formularios críticos (login, crear proyecto).
- Evaluar `flutter_secure_storage` en vez de `shared_preferences` para el
  token JWT en builds de producción.
