# HU-003 — Inicio de Sesión con Autenticación de Dos Factores

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-003 |
| Título | Inicio de Sesión con Autenticación de Dos Factores |
| Prioridad | Crítica |
| Estado | Completada |
| RF asociado | RF-003 |

---

## Historia

*Como* usuario registrado,
*quiero* iniciar sesión con mi correo y contraseña y confirmar con un código de doble factor,
*para* acceder de forma segura a la información de mis proyectos.

## Criterios de Aceptación

- El sistema valida email y contraseña antes de solicitar el código 2FA.
- Ante credenciales incorrectas se muestra un mensaje genérico y se registra el intento fallido.
- Tras 3 intentos fallidos consecutivos la cuenta se bloquea temporalmente 15 minutos.
- El código 2FA enviado es válido por 5 minutos.
- Un inicio de sesión exitoso redirige al usuario según su rol y queda registrado en el log de auditoría.
