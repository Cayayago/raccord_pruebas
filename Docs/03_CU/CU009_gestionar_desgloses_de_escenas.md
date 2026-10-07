# CU009 — Gestionar Desgloses de Escenas

## Identificación

| Campo | Valor |
|---|---|
| ID | CU009 |
| Título | Gestionar Desgloses de Escenas |
| Módulo | Módulo 3: Planeación y Comunicación |
| Actor primario | Administrador y Sub-admi |
| Frecuencia | Media |
| Estado | Pendiente |

---

#### Actores

- **Primario:** Administrador y Sub-admi
- **Secundario:** Sistema calendario (CU007), Sistema fotografías (CU004), Sistema LOG

#### Descripción

Permite a la Primera AD y al Script crear y modificar desgloses detallados por escena individual. Cada desglose incluye: Número de escena, Descripción narrativa breve, Interior/Exterior, Día/Noche, Personajes con diálogo, Personajes secundarios/extras, Vestuario requerido por personaje con estado (limpio/sucio/roto), Maquillaje especial requerido, Utilería hero (objetos clave en acción), Vehículos, Efectos especiales, Armas/elementos regulados, y Notas de producción. Los desgloses se vinculan automáticamente a las fotografías de continuidad de la misma escena. Todos los departamentos pueden visualizar desgloses completos.

#### Precondiciones

- Ejecutor Primera AD o Script autenticado
- Proyecto activo, personajes registrados
- Número escena único en proyecto

#### Postcondiciones

**Creación:**
- Desglose en BD
- UUID generado
- Vestuario por personaje en subtabla
- Evento calendario actualizado automáticamente (si existe)
- Vinculado a fotos (búsqueda auto por num_escena)
- Visible todos deptos
- Registro en LOG

**Modificación:**
- Campos actualizados
- Timestamp modificado
- Notificación a Primera AD si vinculado a evento
- Registro en LOG

**Visualización:**
- Todos deptos ven completo
- Organizado por secciones
- Botones "Ver Fotografías" y "Ver Evento" disponibles

**Vinculación bidireccional:**
- Desde desglose→galería filtrada
- Desde foto→desglose en modal

#### Flujo Principal

1. Primera AD o Script abre "Desgloses"
2. Usuario hace clic "Nueva Escena"
3. Sistema muestra formulario de desglose
4. Usuario completa: Num escena, Descripción, INT/EXT, Día/Noche, Personajes diálogo, Secundarios/extras, Vestuario por personaje + estado, Maquillaje, Utilería hero, Vehículos, Efectos, Armas, Notas producción
5. Sistema valida número escena único
6. Sistema genera UUID
7. Sistema crea desglose en BD
8. Sistema guarda vestuario por personaje en subtabla
9. Si escena ya está en evento calendario: sistema actualiza evento automáticamente
10. Sistema vincula desglose a fotografías existentes (búsqueda por num_escena)
11. Sistema registra creación en LOG
12. Desglose queda visible para todos los departamentos

#### Flujos Alternativos

**FA-001: Importar Desgloses desde Excel** : Primera AD/Script selecciona archivo Excel → Sistema valida formato → Importa múltiples desgloses → Valida nums escena únicos → Crea en lote → Notifica completado

**FA-002: Plantilla de Desglose Reutilizable** : Script crea desglose con elementos comunes → Guarda como "Plantilla" → Al crear nueva escena → Selecciona plantilla → Sistema pre-llena campos

#### Flujos Excepcionales

**FE-001: Número Escena Duplicado** : Sistema detecta num_escena ya existe → Rechaza creación → Muestra "Escena ya registrada" → Sugiere editar existente o usar num diferente

#### Frecuencia

Media
