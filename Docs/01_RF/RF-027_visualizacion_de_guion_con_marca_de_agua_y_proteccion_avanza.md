# RF-027 — Visualización de Guion con Marca de Agua y Protección Avanzada

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-027 |
| Título | Visualización de Guion con Marca de Agua y Protección Avanzada |
| Módulo | Gestión de Guiones |
| Prioridad | Crítica |
| Estado | Pendiente |
| RNF asociados | RNF-015, RNF-018 |

---

**Descripción**:El sistema debe permitir visualizar guiones en formato PDF dentro de la aplicación con marca de agua dinámica, bloqueo de capturas de pantalla y protección contra descargas no autorizadas.


**Entradas**:

- Guion seleccionado desde lista de versiones
- Usuario que visualiza (capturado automáticamente)

**Proceso**:

- Validar que usuario tenga permiso para ver guion según su rol:

        Talento: solo versión "En Rodaje"
        Otros roles: todas las versiones


- Cargar PDF desde storage
- Renderizar PDF en visor integrado dentro de la app (NO descarga directa)
- Aplicar marca de agua dinámica en tiempo real superpuesta en cada página:

        Nombre completo del usuario
        Timestamp de visualización
        Nombre del proyecto
        Posición: diagonal, semi-transparente, múltiples repeticiones por página


- En aplicaciones móviles (iOS/Android):

        Deshabilitar capturas de pantalla a nivel de sistema operativo
        Si usuario intenta captura: pantalla se pone negra automáticamente
        Detectar intentos de grabación de pantalla externa: cerrar visor automáticamente


- En la app de escritorio (Windows/macOS, Flutter):

        Deshabilitar clic derecho (menú contextual) dentro de la app
        Interceptar atajos de teclado cuando la app tiene foco: Ctrl+S, Ctrl+P, PrtScr, Ctrl+C
        Nota: el sistema operativo de escritorio no ofrece una API equivalente a FLAG_SECURE (móvil) para bloquear capturas de forma garantizada; estos controles son un disuasivo, y la marca de agua en cada página es la protección principal en esta plataforma


- Permitir navegación por páginas del guion (anterior/siguiente, ir a página específica)
- Permitir zoom para lectura
- Registrar visualización en log de auditoría (RF-009): quién vio qué guion, cuándo, por cuánto tiempo

**Salidas**:

- Guion visualizado con marca de agua en cada página
- Capturas de pantalla bloqueadas
- Registro de visualización en log de auditoría

**Precondiciones**:
- Usuario debe estar autenticado
- Usuario debe tener permiso para ver guion según su rol
- Guion debe estar subido al sistema (RF-026)

**Postcondiciones**:

- Contenido protegido contra capturas y descargas
- Visualización registrada en auditoría para trazabilidad
- Marca de agua identifica al usuario en caso de filtración

**Actores**: Todos los usuarios autorizados según su rol

**Dependencias**:
- RF-003 (Usuario autenticado)
- RF-005 (Sistema de roles)
- RF-015 (Marca de agua dinámica)
- RF-009 (Log de auditoría)
