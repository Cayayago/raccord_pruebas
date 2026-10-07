# Entrevista 1: Script (Continuista)

## I. Introducción y Contexto

**Entrevistador:** Hola, gracias por tu tiempo. Estamos trabajando en el diseño de un sistema de información para mejorar la gestión de la continuidad en producciones de cine y televisión. ¿Podrías contarnos brevemente cuál es tu rol y cómo te relacionas con los procesos de continuidad, vestuario, utilería, maquillaje o guiones en una producción?

**Script:** Claro, soy la Script, o Continuista. Mi rol es crucial para asegurar que todo sea consistente entre tomas y escenas, incluso si se graban en días diferentes. Estoy en el set constantemente, tomando notas detalladas de vestuario, maquillaje, peinado, posición de actores, utilería, hora del día en la ficción, y cualquier detalle que afecte la línea temporal o visual. Trabajo de cerca con dirección, fotografía, vestuario, maquillaje y arte para garantizar que no haya errores que obliguen a regrabar. También llevo un registro del estado del guion y los partes de rodaje.

## II. Problemas Actuales y Oportunidades

**Entrevistador:** Actualmente, ¿cuáles son los mayores desafíos o "dolores de cabeza" que experimentas en relación con la continuidad en las producciones?

**Script:** Uf, varios. El mayor dolor de cabeza es la descentralización de la información. Tengo mis notas, vestuario las suyas, maquillaje las suyas, y aunque intentamos comunicarnos, a veces algo se escapa. Esto lleva a errores de continuidad que no se detectan hasta el montaje, lo que significa ¡regrabar! Otro problema es la rapidez con la que necesito compartir fotos. A veces hago una foto de un detalle de vestuario y la necesito enviar a vestuario, pero también a maquillaje por si afecta el peinado. Si la foto está en mi teléfono, tengo que buscarla, enviarla por WhatsApp... es lento.

**Entrevistador:** ¿Podrías describir alguna situación específica en la que una inconsistencia o un error de continuidad haya causado problemas significativos?

**Script:** ¡Claro! En una serie, estábamos grabando una escena de acción donde un personaje recibía un rasguño en la cara y su camisa se rompía. Grabamos el inicio de la secuencia por la mañana y el final por la tarde. Por la mañana, el rasguño estaba en el lado derecho, pero por la tarde, el maquillador nuevo, que no había visto las fotos previas ni la continuidad escrita a tiempo, lo puso en el lado izquierdo. La camisa rota también tenía una rasgadura diferente. Nos dimos cuenta en el máster, y tuvimos que regrabar media jornada de rodaje con los actores principales. Fue un desastre de tiempo y dinero, todo por un fallo de comunicación y acceso a la información precisa.

**Entrevistador:** En cuanto a la información confidencial (guiones, fotos de set, etc.), ¿cómo se maneja actualmente? ¿Existen preocupaciones sobre la seguridad o el control de esta información?

**Script:** Principalmente por correo electrónico y WhatsApp. Los guiones se comparten en PDFs, a veces con marca de agua, pero se distribuyen mucho. Las fotos del set son un riesgo enorme; a menudo las tomo con mi teléfono y luego las envío a los departamentos. ¡Es muy fácil que una foto de un personaje o un detalle clave se filtre a redes sociales! Hay una preocupación constante, sí. Me gustaría que no se pudieran descargar o que tuvieran marcas de agua automáticas.

**Entrevistador:** ¿Qué herramientas o métodos utilizas actualmente para gestionar la continuidad y la comunicación en el set (mensajería, hojas de cálculo, notas manuales, etc.)? ¿Qué te gusta o no te gusta de estas herramientas?

**Script:**  
- Uso mi cuaderno de continuidad para las notas escritas, con dibujos y esquemas.  
- Para las fotos, mi teléfono móvil y luego las comparto por WhatsApp o a veces por correo.  
- Para los guiones y partes de rodaje, PDFs.  

Lo que me gusta de mi cuaderno es que es inmediato, puedo dibujar rápido. Lo que no me gusta es que no es compartido y es fácil que se pierda o se dañe. WhatsApp es rápido para enviar fotos, pero las fotos se mezclan con otras conversaciones y es difícil recuperarlas por escena o personaje. Además, ocupa mucho espacio en el teléfono y la calidad de la imagen a veces se reduce. Las hojas de cálculo son buenas para listas, pero no para lo visual o para cambios rápidos.

**Entrevistador:** Si pudieras cambiar algo del proceso actual de gestión de continuidad, ¿qué sería lo primero que harías?

**Script:** Tendría un punto centralizado donde toda la información de continuidad —fotos, notas, cambios de guion, desgloses— esté accesible al instante para todos los departamentos relevantes, con su permiso claro. Y que fuera fácil de buscar por escena, día, personaje.

## III. Requisitos Funcionales (RFs)

### Módulo de Continuidad Visual

**Entrevistador:** ¿Cómo se debería etiquetar o categorizar este material fotográfico para que sea fácil de encontrar (existe un estándar?)? ¿Qué detalles son importantes registrar?

**Script:** ¡Absolutamente! Necesitamos un estándar, por ejemplo:  
`PROYECTO_EPISODIO_ESCENA_TOMA_PERSONAJE_DETALLE_VERSION`

Detalles importantes:  
- Proyecto  
- Episodio/Película  
- Número de Escena  
- Número de Toma  
- Personaje(s) involucrado(s)  
- Fecha del Rodaje  
- Hora Ficticia (mañana/tarde/noche)  
- Descripción del detalle (ej. "Vestuario Camisa A - Sucia")  
- Comentarios adicionales  
- Estado de la Continuidad (OK, Pendiente, Error a corregir)  

La búsqueda debe poder hacerse por cualquiera de esos campos.

**Entrevistador:** ¿Sería útil un sistema que analizara automáticamente las imágenes para identificar elementos clave (ej. vestuario específico, accesorios, peinado)? ¿Qué tan preciso esperas que sea?

**Script:** Sería extremadamente útil, casi un sueño. No espero que sea 100% perfecto al principio, pero si puede darme un punto de partida o alertarme sobre posibles inconsistencias visuales obvias (ej. "rasguño en lado opuesto"), me ahorraría mucho tiempo. Con un 80-85% de precisión ya sería un avance.

**Entrevistador:** ¿Cómo te gustaría que se vea la página visualmente?

**Script:** Clara, intuitiva y rápida. Miniaturas de fotos, ampliación con metadatos, vista tipo "línea de tiempo", texto fácil de leer/editar y modo oscuro para set.

### Módulo de Planeación y Comunicación

**Entrevistador:** ¿Cómo se organiza actualmente el calendario de rodaje y los desgloses?

**Script:** Recibo los desgloses y calendarios por correo electrónico, generalmente en PDF o Excel. La primera ayudante de dirección los prepara. A veces hay cambios de última hora y se envían por WhatsApp.

**Entrevistador:** ¿Qué tipo de información debería incluir un calendario centralizado del rodaje?

**Script:**  
- Número de Escena  
- Descripción breve  
- Localización  
- Personajes presentes  
- Hora ficticia  
- Página(s) de guion  
- Equipo técnico requerido  
- Vestuario específico o cambios  
- Maquillaje especial  
- Utilería clave  
- Notas de Dirección / Advertencias  

**Entrevistador:** ¿Qué tan importante es recibir notificaciones instantáneas sobre cambios?

**Script:** ¡Críticamente importante! Deben llegar a todos los departamentos afectados, en la app y con alerta sonora. También un resumen diario por correo.

**Entrevistador:** ¿Quién debería poder crear o modificar eventos?

**Script:**  
- Primera ayudante de dirección: crear/modificar calendario.  
- Jefes de departamento (incluida yo): añadir notas específicas.  
- Todos: ver calendario (actores solo lo que les corresponde).  

**Entrevistador:** ¿Necesitas comunicación interna en la app?

**Script:** Sí, con funciones:  
- Comunicados a todo el equipo  
- Mensajes a departamentos específicos o individuos  
- Adjuntar fotos o documentos  
- Registro de mensajes leídos  
- Chats por escena  

### Módulo de Seguridad

**Entrevistador:** ¿Quiénes necesitan tener acceso y qué nivel?  

**Script:**  
- Acceso total: Script, Vestuario, Maquillaje, Utilería, Arte, 1ª Ayudante de Dirección.  
- Solo lectura: Director (todo), Fotografía (continuidad y guiones), Actores (sus escenas), Producción (calendario, partes de rodaje).  

**Entrevistador:** ¿Qué tan importante es proteger la información contra descargas no autorizadas?  

**Script:** Fundamental. Fotos y guiones con marcas de agua automáticas. Visualización solo dentro de la app.  

**Entrevistador:** ¿Niveles de permisos?  

**Script:**  
- Script: subir fotos de continuidad.  
- Vestuario: marcar vestuario como final.  
- Asistente dirección: editar calendario.  
- Actores: ver solo su guion y llamado.  

**Entrevistador:** ¿Qué pasa con el acceso de alguien que deja el proyecto?  

**Script:** Debe revocarse de inmediato.  

**Entrevistador:** ¿Quién gestiona permisos y roles?  

**Script:** Productor de Línea o Jefe de Producción.  

**Entrevistador:** ¿Se debería usar criptografía?  

**Script:** Sí, para proteger datos confidenciales.  
### General

**Entrevistador:** ¿Qué informes te gustaría generar?  

**Script:**  
- Informe de Continuidad por Escena  
- Listado de Vestuario/Maquillaje por Personaje  
- Informe de Cambios de Guion  
- Parte de Rodaje  

**Entrevistador:** ¿Otras funcionalidades esenciales?  

**Script:**  
- Visor de guion integrado con anotaciones  
- Comparación de versiones de guion  

## IV. Requisitos No Funcionales (RNFs)

### Rendimiento
- Usuarios simultáneos: 20–30 en set.  
- Modo offline con sincronización automática.  
- Subida diaria: 50–100 fotos (2–5 MB c/u).  

### Usabilidad
- Multiplataforma (tablet prioridad, móvil y escritorio también).  

### Fiabilidad y Disponibilidad
- Disponibilidad casi 100% en rodaje.  
- Backups automáticos al menos cada hora.  
- Restauración rápida (minutos/horas).  

### Escalabilidad
- Desde cortometrajes hasta producciones grandes.  

### Seguridad
- Cifrado de datos.  
- Autenticación de dos factores.  
- Historial de accesos.  

### Mantenibilidad
- El sistema debe evolucionar con nuevas funcionalidades.  

## V. Restricciones

- Módulo base: **Continuidad Visual**.  
- Debe funcionar en iOS (iPad).  
- Cumplimiento de políticas de confidencialidad de la productora.  
- Presupuesto y facilidad de implementación como limitantes.  

## VI. Cierre

**Entrevistador:** ¿Algo más que añadir?  

**Script:** Velocidad e inmediatez son clave en el set. Confiabilidad absoluta.  

**Entrevistador:** ¿A quién más deberíamos entrevistar?  

**Script:** Al Jefe de Vestuario, Jefe de Maquillaje y Productor de Línea.