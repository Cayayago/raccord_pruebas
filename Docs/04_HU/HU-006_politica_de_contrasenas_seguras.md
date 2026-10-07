# HU-006 — Política de Contraseñas Seguras

## Identificación

| Campo | Valor |
|---|---|
| ID | HU-006 |
| Título | Política de Contraseñas Seguras |
| Prioridad | Alta |
| Estado | Completada |
| RF asociado | RF-006 |

---

## Historia

*Como* usuario del sistema,
*quiero* que mi contraseña cumpla reglas mínimas de seguridad,
*para* proteger mi cuenta y la información confidencial del proyecto.

## Criterios de Aceptación

- El sistema exige mínimo 12 caracteres con mayúscula, minúscula, número y carácter especial.
- El sistema rechaza contraseñas iguales a las últimas 3 usadas por el usuario.
- La contraseña se almacena hasheada con bcrypt (12 rounds), nunca en texto plano.
- Si alguna validación falla, se muestra el mensaje específico del error incumplido.
