# Diccionario de base de Datos - Raccord

Los siguientes son los tipos de datos listados que encontramos:
- Type: tipo_documento - CC, TI, NIT, PA, CE.
- Type: formatos - serie , miniserie ,pelicula, largometraje,  mediometraje, cortometraje, documental , spot publicitario , 
video musical, video corporativo, video educativo, micro-formato,mockumentary.
- Type: generos - accion, comedia, aventura, drama, terror, ciencia ficcion, fantasia, suspenso, musical, western, belico, romance, crimen, misterio, animacion, biopic,documental, video, artes marciales,thriller,Histórico,epoca,familiar, deportivo,horror, paranormal, y otro.
- Type: estado_usuario - activo, inactivo, pendiente y suspendido.
- Type: estado_guion -'Borrador', 'Revisión', 'Aprobado', 'En Rodaje', 'Archivado'
- Type: jerarquias_rol - 'productora','direccion','alto','medio','bajo'.
- Type: generosex - masculino, femenino y otro.
- Type: vistalugar - 'int','ext','int/ext','ext/int'.
- Type: momentodia - 'dia','noche','amanecer','atardecer','amanecer/dia','dia/noche'.

## 1 Client

Encontraremos todos los datos de los clientes de Raccord.

| campo               | tipo         | descripción                                                                                |
|---------------------|--------------|--------------------------------------------------------------------------------------------|
| id_cliente          | int          | pk, comienza desde el 1001                                                                 |
| Document            | enum         | Solo se puede agregar los siguiente tipo de datos: CC, TI, NIT, PA,CE.                     |
| Razon social        | varchar(50)  | se menciona el nombre de la productora o personal natural.                                 |
| Representante Legal | varchar(100) | nombre del representante legal de la productora o de persona natural que crea el proyecto. |
| Email               | varchar(100)| correo de notificaciones de la productora o cliente.                                       |      
| Adress              | varchar(100)| Dirreción o ubicacion de la casa matriz de la productora.                                  |
| Telephone           |varchar(15)| numero de telefono de la productora, puede estar vacio este campo.                         |
| number Cellphone    |varchar(20)| Numero de celular o movil del la productura o represe ntante legal.                        |

## 2 project

Estarán listados todos los proyectos que se están realizando las diferentes productoras, usan el sistema de gestión de continuidad de Raccord.

| campo                 | tipo         | descripción|
|-----------------------|--------------|------------|
| id_project            | text         |pk, comienza con la nomeclatura proj0001|
| Project name          | varchar(500) |Nombre de la producción|
| Formato de pruducción | enum         |Solo debe llevar los siguientes campos(Serie, Miniserie,Largometraje, mediometraje,cortometraje,Docuemental,Spot publicitario, Video musical, Video corporativo, Video Educativo, Micro-formato y Mockumentary.|
| sinopsis              | Text         | El Director o la productora menciona brevemente de que se trata el formato.|
| genero                | enum         | Los generos que se pueden elegir son los siguientes: accion, comedia, aventura, drama, terror, ciencia ficcion, fantasia, suspenso,musical,western,belico, romance, crimen, misterio, animacion, biopic,documental, video, artes marciales,thriller,Histórico,epoca,familiar, deportivo,horror, paranormal,drama y otro.|
|director| varchar(100) |se menciona el nombre del director o directores que dirigen el proyecto|
|id_cliente|int|fk, es llave foranea de cliente.|

## 3 users
Estarán listados todos los usuarios que han sido creados o que se han registrado. 

| campo               | tipo   |descripción|
|---------------------|--------|-----------|
| id_user             | int    |pk, comienza desde el numero 3001.|
| nombre              | varchar(50) |nombre del usuario.|
| apellido            | varchar(50) |apellidos del usuario.|
| identificación      | enum   |Solo se puede agregar los siguiente tipo de datos: CC, TI, NIT, PA,CE.|
| id identificacion   | text   |se menciona el numero del documento de identidad.|
| mail                | text   |se menciona el mail del usuario, donde llegara las notificaciones.|
| msisdn              | text   |se guarda el numero de celular del usuario.|
| direccion           | text   |se menciona la direccion de residencia del usuario, es opcional.|
| fecha de nacimiento | date   |se menciona la fecha de nacimiento del usuario, es opcional.|
| estado              | enum   |este menciona el estado del usuario, aqui mencionamos los siguientes estados:activo, inactivo, suspendido,pendiente.|
| fecha de creación   |timestamptz|se menciona la fecha de creacion del usuario.|
| ultimo acceso       |timestamptz|se menciona el ultimo acceso que tuvo el usuario en la plataforma.|
| contraseña          |varchar(500)|se guarda la contraseña, pero el espacio se debe a que se requiere suficiente para guardar el hash generado por algoritmos modernos como bcrypt|
|id_departamento|text|fk, llave foranea de la tabla departamento.|
|id_rol|int|fk, llave foranea de tabla roles.|
|id_project|text|fk, llave foranea de tabla project.|
## 4 Guion

Se encontraran todos los guiones que han subido nuestros clientes.

| campo             | tipo         | descripcion  |
|-------------------|--------------|--------------|
| id_guion          | int          |pk,comienza desde el numero 1.|
| nombre            | varchar(100) |nombre que le dan al guión.|
| numero de version | varchar(45)  |numero de version del guion.|
| estado            | enum         |los estan disponibles los siguientes valores: Borrador, Revisió,Aprobado, En Rodaje,Archivado.|
| descripcion       | text         |breve descripcion del guión, es opcional|
| archivo           | text         |URL de la ubicacion del archivo.|
| fecha de emisión  | date         |fecha en la que se subio el guión.|
|id_project|text|fk, llave forane de la tabla project.|


## 5 Escenas
Se encuentran todas las escenas listadas del projecto.

|campo|tipo| descripcion                            |
|-----|----|----------------------------------------|
|id_escena|text| pk, la nomeclatura definida es esc001. |
|numero de escena|varchar(100)|numero de escena definido por la direccion del projecto|
|encabezado|text|titulo se la escenas.|
|descripcion|text|descripcion de la escena.|
|modo vista|enum|aqui encontraremos si la toma se hace en Int, ext, int/ext y ext/int.
|momento del dia|enum|se menciona si la escena se debe hacer: dia, noche, amanecer, atardecer,amanecer/dia y dia/noche.
|pagina|int|se menciona en que pagina del guón esta la escena.|
|ciudad|text|se menciona la ciudad en la cual se hara la grabación.|
|fecha de grabación|date|se menciona el dia de grabacion de esa escena.|
|dia dramatico|int|se menciona el dia dramatico de la historia.|
|id_guion|int|fk, llave foranea de la tabla guion.|
|id_rodaje|text|fk, llave foranea de la tabla plan de rodaje o rodaje.|
|id_desglose|text|fk, llave foranea de la tabla de desglose.|

## 6 Desglose
aqui encontramos el desglose, donde se menciona las caractericas, tecnicas, artisticas y logisticas necesarios para la producción.

| campo       |tipo|descripcion|
|-------------|----|-----------|
| id_desglose |text|pk,la nomeclatura comienza con el numero desg1.
|version|varchar(50)|se menciona la version del desglose que se esta realizando.|
|semana de grabación|int|se menciona la semana de grabación propuesta o real.|
|dia de rodaje|int|se menciona el dia de rodaje, que no es el mismo de fecha de rodaje.(hoy viernes,manaña hay grabación y solo se ha grabado el lunes y marte spor ende mañana es el 3 dia de grabación).|
|horario de incio|time|se menciona la hora de incio o rango de horas en las que se trabaja.|
|horario de fin|time|se menciona la fin o rango de horas en las que se trabaja.|
|location|varcgar(100)|Se escribe el nombre de la locacio completo, es ciudad de Bogota,por ende la locacion se toma como calle 7, cerca Plaza de Bolivar.|
|requerimientos|text|se menciona las necesidades que tiene cada uno de los departamentos.|
|activo|bool|esta por default como verdadero,pero es para identificar es el desglose esta vigente o no.|

## 7 Plan de Rodaje - Rodaje.
Aqui encontramos el plan de rodaje, que es el cronograma detallado que organiza todas las actividades necesarias para la filmación de una película o proyecto audiovisual.

| campo               |tipo|descripcion|
|---------------------|----|-----------|
| id_rodaje           |text|pk,la nomeclatura comienza con el numero rod1.|
| version             |varchar(50)|se menciona la version del desglose que se esta realizando.|
| semana de grabación |int|se menciona la semana de grabación propuesta o real.|
| dia de rodaje       |int|se menciona el dia de rodaje, que no es el mismo de fecha de rodaje.(hoy viernes,manaña hay grabación y solo se ha grabado el lunes y marte spor ende mañana es el 3 dia de grabación).|
| horario de incio    |time|se menciona la hora de incio o rango de horas en las que se trabaja.|
| horario de fin      |time|se menciona la fin o rango de horas en las que se trabaja.|
| location            |varcgar(100)|Se escribe el nombre de la locacio completo, es ciudad de Bogota,por ende la locacion se toma como calle 7, cerca Plaza de Bolivar.|
| notas               |text|se menciona aclaracion que crean que son pertinentes.|
| activo              |bool|esta por default como verdadero,pero es para identificar es el desglose esta vigente o no.|


## 8 Departamentos
Encontraremos listados todos los departamento que se encuentran en una producción.

| campo           | tipo         |descripcion|
|-----------------|--------------|-----------|
| id_departamento | text         |pk, la nomeclatura definida es area01.|
| nombre          | varchar(45)  |nombre del departamento o area.|
| ubicación       |text|se menciona donde se encuentra este equipo.|

## 9 Personajes
se menciona todos los personas que se encuentren para el projecto audiovisual.

|campo|tipo| descripcion                                                  |
|-----|----|--------------------------------------------------------------|
|id_personaje|text| pk, la nomeclatura se denomina cast1.                        |
|codigo personaje|varchar(35)| Se menciona el codifo del personaje que le da la producción. |
|nombre|varchar(45)| nombre del personaje en el proyecto audiovisual.             |
|edad|int| se menciona la edad del personaje.                           |

## 10 Actores
se menciona los actores que haren parte del proyecto audiovisual.

|campo| tipo                                                               | descripcion                                                                                                 |
|-----|--------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
|id_actor| text                                                               | pk, la nomeclatura se denomina act1.                                                                        |                                                                                                        
|nombre| varchar(45)                                                        | nombre del actor.                                                                                           |
|apellido| varchar(45)                                                        | apellido del actor.                                                                                         |
|nacionalidad| varchar(50)                                                        | nacionalidad del actor.                                                                                     |
|genero| enum                                                               | genero de actor. Masculino, femenino y otro.                                                                |
|fecha de nacimiento| date                                                               | se menciona la fecha de nacimiento del actor.                                                               |
|talla zapatos| varchar(10)                                                        | se menciona la talla de zapatos del actor.                                                                  |
|ancho de espalda| varchar(30)                                                        | ancho de espalda del actor.                                                                                 |
|pecho| varchar(30)                                                        | contorno del pecho.                                                                                         |
|cintura| varchar(30)                                                        | contorno de cintura.                                                                                        |
|cadera| varchar(30)                                                        | contorno de cadera.                                                                                         |
|largo manga| varchar(30)                                                        | largo de manga, es decir de hombro hasta la muñeca.                                                         |
|largo de pierna| varchar(30                                                         | largo de piernda, desde la cintura hasta el talon.                                                          |
|talla de anillo| text                                                               | talla del anillo.                                                                                           
|contorno cabeza| varchar(30)                                                        | se menciona el contorno de cabeza para todo el tema de sombreros u otros.                                   |
|contorno cuello| varchar(30)                                                        | contorno de cuello para corbatas, collares, u otros.                                                        |
|color cabello| varchar(45)                                                        | color de cabello del actor.                                                                                 |
|textura del cabello| varchar(45)| tipo de cabello del actor, liso, ondulado,entres otros.                                                     |
|tipo piel| varchar(45)                                                        | se menciona el tipo de piel que tiene el actor o actriz, seca, grasa,..                                     |
|color ojos| varchar(45)                                                        | se menciona el color de ojos de la persona actor o actriz.                                                  |
|alergias| text                                                               | se menciona cada alergia que tenga la persona.                                                              |
|habilidades especiales| text                                                               | se menciona las habalidades que pueda realizar, por ejmplo, nadar, cabalagar, etc.                          |
|restricciones| text                                                               | se menciona que restricciones tiene o posee la persona.                                                     |
|comentarios adicionales| text                                                               | se deja este espacio para dejar comentarios sobre la personas, en caso de no tener el item que se requiere. |
|doble riesgo| bool                                                               | se menciona si ese actor es un doble de riesgo.                                                             |
|id_personaje|text|fk, llave forane de la tabla personajes.|

## 11 rol
Se menciona los tipo roles que encontramos en Raccord para cierto proyecto.

|campo|tipo|descripcion|
|-----|----|-----------|
|id_rol|int|pk, la nomeclatura comienza en 1001.|
|nombre|varchar(45)| nomnbre que se le da al rol.|
|nivel de jerarquia|enum| los campos que encontramos aqui son productora, direccion, alto, medio y bajo.|
|descripcion|text|se menciona brevemente la funcion de ese rol.|
|activo|bool| a traves de este campo sabemos si el rol esta en funcionamiento o no.|

## 12 permisos
se menciona los tipos de permisos que se encuentran en Raccord.

|campo| tipo                                                    | descripcion                                                                                                                  |
|-----|---------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
|id_permiso| int                                                     | pk, su numeclatura comienza en 2001.                                                                                         |
|codigo| varchar(50)                                             | codigo del permiso que lo identifica de una forma tecnica, por ejemplo: guiones.read,usuarios.create.                        |
|nombre| varchar(100)                                            | se describe lo que hace el permiso, pero de una forma legible y entendible, por ejemplo: crear usuarios, eliminar usuarios.  |
|modulo| varchar(50)                                             | se menciona a que modulo del programa afecta este permiso: guiones, continuidad, informes. (Posibilidad cambiarlo por enum). |
|descripcion| text| breve descripcion de lo que el permiso pueda hacer.                                                                          |
|activo| bool                                                    | a traves de este campo se menciona si el permiso se encuentra activo.                                                        |

## 13 rol_has_permisos
tabla debil donde converge los roles y permisos.

|campo|tipo|descripcion|
|-----|----|-----------|
|rol_idrol|int|fk, llave foranea de la tabla rol.|
|permisos_idpermiso|int|fk, llave foranea de la tabla permisos.|

## 14 Escena_Personaje
tabla debil donde converge la tabla de escenas y persoanjes a traves de conexion de muchos a muchos.

| campo        | tipo | descripcion                               |
|--------------|------|-------------------------------------------|
| id_escenas   | text | fk, llave foranea de la tabla escenas.    |
| id_personaje | text | fk, llave foranea de la tabla personajes. |













