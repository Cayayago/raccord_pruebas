# RNF-028 — Escalabilidad de Usuarios Concurrentes

## Identificación

| Campo | Valor |
|---|---|
| ID | RNF-028 |
| Título | Escalabilidad de Usuarios Concurrentes |
| Categoría | Escalabilidad |
| Prioridad | Alta |
| Estado | Pendiente |
| RF asociados | General / Transversal |

---

**Descripción**: El sistema debe soportar operación simultánea de 50 usuarios concurrentes sin degradación de rendimiento, con arquitectura que permita escalar horizontalmente hasta 200+ usuarios añadiendo servidores.

**Métrica**:

- 50 usuarios concurrentes: 100% de funcionalidad sin degradación
- Tiempos de respuesta se mantienen dentro de límites establecidos (RNF-001 a RNF-011)
- Capacidad de escalar a 200+ usuarios sin cambios de código
- Escalado horizontal mediante:

        Load balancer (Nginx)
        Múltiples instancias de aplicación
        Base de datos con réplicas de lectura


**Aplica a**:

- Infraestructura backend completa
- API REST
- Base de datos
- Aplicaciones cliente (móvil/web)

**Estándar/Norma**: ISO/IEC 25010 - Capacidad

**Método de Verificación**:
- Pruebas de carga con Apache JMeter o Locust
- Simular 50 usuarios concurrentes durante 1 hora
- Ejecutar mix de acciones: subir fotos, buscar, ver calendario, mensajes
- Verificar tiempos de respuesta dentro de métricas
- Añadir segunda instancia de servidor y verificar escalado correcto
