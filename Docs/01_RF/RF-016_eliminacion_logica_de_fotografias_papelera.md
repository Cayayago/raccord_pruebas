# RF-016 — Eliminación Lógica de Fotografías (Papelera)

## Identificación

| Campo | Valor |
|---|---|
| ID | RF-016 |
| Título | Eliminación Lógica de Fotografías (Papelera) |
| Módulo | Gestión de Fotografías de Continuidad |
| Prioridad | Media |
| Estado | Pendiente |
| RNF asociados | — |

---

**Descripción**: El sistema debe permitir al Script eliminar fotografías, pero en lugar de borrarlas permanentemente, moverlas a una papelera de reciclaje durante 30 días antes de eliminación definitiva.

**Entradas**:

- Fotografía seleccionada
- Acción: Eliminar

**Proceso**:

- Validar que usuario sea Script (único autorizado para eliminar)
- Mostrar confirmación: "¿Está seguro de eliminar esta fotografía? Se moverá a papelera por 30 días"
        Si confirma:

            NO eliminar archivo de storage
            Marcar registro en base de datos con estado "Eliminado" y timestamp de eliminación
            Mover fotografía a sección "Papelera" visible solo para Script y Administrador Total
            Configurar eliminación automática definitiva en 30 días
            Registrar eliminación en log de auditoría

- Script y Administrador Total pueden:

        Ver papelera con fotografías eliminadas
        Restaurar fotografía

- Tras 30 días: proceso automático elimina permanentemente fotografía de storage y base de datos

**Salidas**:

- Fotografía movida a papelera (estado "Eliminado")
- Fotografía excluida de búsquedas normales
- Registro de eliminación en log de auditoría
- Eliminación definitiva tras 30 días

**Precondiciones**:

- Usuario debe ser Script o Administrador Total
- Fotografía debe existir y estar en estado "Activo"

**Postcondiciones**:

- Fotografía recuperable durante 30 días
-Tras 30 días: eliminación permanente e irreversible

**Actores**:

* Script (elimina)
* Administrador Total (puede restaurar o eliminar definitivamente)

**Dependencias**:

- RF-010 (Fotografías deben existir)
- RF-009 (Log de auditoría)
- Cron job para eliminación automática tras 30 días
