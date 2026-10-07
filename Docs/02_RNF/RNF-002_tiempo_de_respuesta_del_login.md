# RNF-002 — Tiempo de Respuesta del Login

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-002 |
| Título | Tiempo de Respuesta del Login |
| Categoría | Rendimiento |
| Prioridad | Crítica |
| Estado | Pendiente |
| RF asociados | RF-003 |

---

**Descripción**: El proceso de inicio de sesión completo (validación de credenciales + generación de código 2FA + envío) debe completarse en menos de 7 segundos desde que usuario envía email/contraseña hasta que recibe código 2FA.

**Métrica**:

- Tiempo total < 5 segundos (percentil 95)
- Desglose:

        Validación de credenciales: < 2 segundo
        Generación de código 2FA: < 5 segundos
        Envío de código (email/SMS): < 60 segundos (ver RNF-003)


- Validación de código 2FA: < 2 segundos


**Aplica a**:
 RF-003 (Inicio de Sesión con Autenticación de Dos Factores)

**Estándar/Norma**: ISO/IEC 25010 - Eficiencia de desempeño

**Método de Verificación**:

- Pruebas automatizadas con 100 logins consecutivos
- Medir tiempos con timestamps en cada paso
- Pruebas con base de datos de 500 usuarios
- Verificar p95 cumple métrica

**Fuente**:

- Objetivo Específico 3 (notificaciones <30 segundos)
- Oscar menciona "tiene que suceder al instante"
