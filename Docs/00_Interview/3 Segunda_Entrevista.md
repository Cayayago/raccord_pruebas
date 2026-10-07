# Entrevista 2: Jefe de Vestuario

## I. Introducción y Contexto

**Entrevistador:**  
Hola, gracias por tu tiempo. Estamos trabajando en el diseño de un sistema de información para mejorar la gestión de la continuidad en producciones de cine y televisión. ¿Podrías contarnos brevemente cuál es tu rol y cómo te relacionas con los procesos de continuidad, vestuario, utilería, maquillaje o guiones en una producción?

**Jefe de Vestuario:**  
¡Hola! Soy el Jefe de Vestuario. Mi equipo es responsable de todo el vestuario que usan los actores, desde la preproducción (diseño, compras, alquileres) hasta el set (vestir a los actores, mantener la continuidad, limpieza, arreglos). Me relaciono con la continuidad de forma muy directa: tengo que asegurarme de que cada prenda, cada rasguño, cada mancha esté exactamente igual entre tomas. También trabajo con guiones para entender la evolución de los personajes y sus cambios de vestuario, y con maquillaje y peluquería para coordinar los looks.

## II. Problemas Actuales y Oportunidades

**Entrevistador:**  
Actualmente, ¿cuáles son los mayores desafíos o "dolores de cabeza" que experimentas en relación con la continuidad en las producciones?

**Jefe de Vestuario:**  
- Gestión del inventario y estado de la ropa (múltiples copias, diferentes estados: limpio, roto, con sangre, etc.).  
- Falta de registro visual centralizado (las fotos de script no siempre son completas ni organizadas).  
- Comunicación tardía de cambios de guion que afectan vestuario.

**Entrevistador:**  
¿Podrías describir alguna situación específica en la que una inconsistencia o un error de continuidad haya causado problemas significativos?

**Jefe de Vestuario:**  
En una película de época, una actriz tenía un vestido que debía ensuciarse progresivamente. Había 3 copias del vestido en diferentes estados de suciedad. Por un cambio de rodaje y falta de referencia visual, se usó el vestido incorrecto (demasiado sucio). El error no se notó hasta tarde y la productora tuvo que pagar un día extra de rodaje y restauración del vestuario.

**Entrevistador:**  
En cuanto a la información confidencial (guiones, fotos de set, etc.), ¿cómo se maneja actualmente? ¿Existen preocupaciones sobre la seguridad?

**Jefe de Vestuario:**  
- Guiones: recibidos en PDF o impresos.  
- Fotos: tomadas en móviles y compartidas por WhatsApp.  
- Alta preocupación por filtraciones, especialmente de vestuarios icónicos o de efectos especiales.  
- Escaso control una vez que las fotos están en un dispositivo personal.

**Entrevistador:**  
¿Qué herramientas o métodos utilizas actualmente? ¿Qué te gusta o no de ellas?

**Jefe de Vestuario:**  
- **Excel**: inventario y listas de cambios (funcional, pero rígido y nada visual).  
- **WhatsApp**: fotos rápidas (instantáneo pero caótico, sin organización por escena/personaje).  
- **Libretas**: para notas rápidas.  

Le gusta: detalle y estructura de Excel.  
No le gusta: falta de integración con fotos y caos en la organización visual.


**Entrevistador:**  
Si pudieras cambiar algo del proceso actual, ¿qué sería lo primero?

**Jefe de Vestuario:**  
Un **inventario digital de vestuario** con fotos claras de cada prenda y sus estados, vinculado a escenas y personajes.

## III. Requisitos Funcionales (RFs)

### Módulo de Continuidad Visual

- **Etiquetas importantes:**  
- Personaje  
- Escena  
- Toma  
- Fecha de rodaje  
- Descripción de la prenda (ej. "Camisa a cuadros")  
- Marca/Diseñador  
- Estado de la prenda (limpio, sucio, roto, con sangre, etc.)  
- Accesorios (gafas, joyas)  
- Peinado/maquillaje relevante  
- Notas de vestuario  

- **Estandarización de nombres:**  
`PROYECTO_PERSONAJE_VESTUARIO_ESTADO_ESCENA`

- **Deseable:**  
- Sistema de análisis automático de imágenes (identificación de prendas, accesorios, diferencias entre fotos).  
- Precisión aceptable: ~80%.  
- Interfaz visual tipo galería, con navegación por personaje y escena.

### Módulo de Planeación y Comunicación

- **Calendario de rodaje:**  
- Escenas, locaciones, personajes.  
- Vestuario requerido por personaje.  
- Estados del vestuario (ej. limpio/sucio).  
- Notas específicas de vestuario.  
- Pruebas de vestuario programadas.  

- **Notificaciones:**  
- Instantáneas ante cambios de rodaje.  
- Alertas en app móvil con sonido.  
- Crítico para cambios de escena/personaje/estado del vestuario.  

- **Roles en el calendario:**  
- Primera AD: crea y edita el calendario general.  
- Vestuario: añade/modifica solo detalles específicos.  
- Todos los departamentos: acceso de lectura.  

- **Comunicación interna:**  
- Chat por departamento, por personaje o por escena.  
- Envío de fotos y notas rápidas.  
- Posibilidad de marcar mensajes como "urgente".

### Módulo de Seguridad

- **Roles y accesos:**  
- Equipo de vestuario: ver/modificar detalles de vestuario.  
- Diseñador de vestuario: acceso total al módulo.  
- Script y primera AD: ver información de vestuario.  
- Director y productor: acceso de solo lectura.  
- Actores: acceso muy limitado.  

- **Protección de información:**  
- Evitar descargas no autorizadas.  
- Marca de agua automática en fotos compartidas (usuario + fecha).  
- Revocación inmediata de accesos cuando alguien deja el proyecto.  

- **Permisos granulares:**  
- Solo diseñador aprueba diseños finales.  
- - Vestuaristas registran estados de prendas pero no editan diseños.  
- Productor de Línea/Jefe de Producción: administración de permisos.  
- **Seguridad avanzada:**  
- Uso de criptografía para fotos y documentos.


### Informes deseados

- Inventario completo de vestuario (con fotos).  
- Listado de vestuario por personaje y escena.  
- Informe de mantenimiento/estado de vestuario.  
- Informe de desglose por día de rodaje.  
- Historial de uso de cada prenda (quién, cuándo, estado).

## IV. Requisitos No Funcionales (RNFs)

### Rendimiento
- Usuarios simultáneos: 25–30 (5–10 solo en vestuario).  
- Soporte **offline** en locaciones sin señal, con sincronización automática al reconectar.  
- Carga diaria: 50–100 fotos (3–6 MB cada una, cientos de MB por día).  

### Usabilidad
- Prioridad: **tablets (iPad)** en set.  
- También en móviles (consultas rápidas) y escritorio(preproducción e inventario).  

### Fiabilidad y Disponibilidad
- Sistema **muy crítico** durante rodajes.  
- Copias de seguridad automáticas cada 30–60 min.  
- Restauración de datos en minutos.  

### Escalabilidad
- Debe adaptarse a **diferentes tamaños de proyectos** (cortometrajes, series, películas grandes).