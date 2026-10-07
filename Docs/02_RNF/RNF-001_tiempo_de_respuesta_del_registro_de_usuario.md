# RNF-001 — Tiempo de Respuesta del Registro de Usuario

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-001 |
| Título | Tiempo de Respuesta del Registro de Usuario |
| Categoría | Rendimiento |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | RF-001, RF-003, RF-005 |

---

**Descripción**: El proceso de registro de usuario (RF-001, RF-002, RF-003) debe completarse y confirmar al usuario en menos de 3 segundos desde que envía el formulario hasta que recibe mensaje de confirmación en pantalla.

**Métrica**:

- Tiempo total de procesamiento < 3 segundos (percentil 95)
- Incluye: validaciones, creación en base de datos, generación de contraseña (si aplica)
- NO incluye: envío de email de activación (ese es asíncrono)


**Aplica a**:

- RF-001 (Auto-registro del primer usuario)
- RF-005 (Usuarios pre-cargados por desarrolladores)
- RF-003 (Registro de usuarios adicionales)

**Estándar/Norma**: ISO/IEC 25010 - Eficiencia de desempeño

**Método de Verificación**:

- Pruebas automatizadas con Selenium
- Medir tiempo desde click en "Registrar" hasta mensaje "Usuario creado exitosamente"
- 50 registros consecutivos
- Promedio y p95 deben cumplir métrica

**Fuente**:

- Estándares de usabilidad web
- Usuario espera respuesta inmediata en formularios
