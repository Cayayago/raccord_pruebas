# RNF-005 — Complejidad de Contraseña (Validación Inmediata)

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-005 |
| Título | Complejidad de Contraseña (Validación Inmediata) |
| Categoría | Seguridad / Usabilidad |
| Prioridad | Media |
| Estado | Pendiente |
| RF asociados | RF-001, RF-003, RF-006, RF-007 |

---

**Descripción**: El sistema debe validar la política de contraseñas (RF-006) en tiempo real mientras el usuario escribe, mostrando indicadores visuales de cumplimiento sin esperar a enviar el formulario.

**Métrica**:
- Validación en tiempo real (onchange/oninput)
- Feedback visual inmediato (<100ms tras cada tecla)
- Indicadores visuales:

        Verde: requisito cumplido
        Rojo: requisito no cumplido
        Barra de fortaleza: Débil / Media / Fuerte
- Requisitos mostrados:

        Mínimo 12 caracteres
        Al menos 1 mayúscula
        Al menos 1 minúscula
        Al menos 1 número
        Al menos 1 carácter especial


**Aplica a**:

        RF-001 (Registro)
        RF-003 (Registro de usuarios adicionales)
        RF-006 (Política de contraseñas)
        RF-007 (Recuperación de contraseña)

**Estándar/Norma**:
- OWASP Password Storage Cheat Sheet
- ISO/IEC 27001

**Método de Verificación**:
- Pruebas de interfaz verificando que indicadores cambian en tiempo real
- Medición de tiempo de respuesta de validación (<100ms)
- Pruebas de usabilidad con 5 usuarios

**Fuente**:

- Buenas prácticas de UX
- Reducir frustración del usuario al descubrir errores después de enviar
