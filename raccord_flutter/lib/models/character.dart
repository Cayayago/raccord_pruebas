import '../core/json_utils.dart';

class CharacterModel {
  final String? idPersonaje;
  final String nombre;
  final int edad;
  final String codigoPersonaje;
  // Obligatorio para crear (ver character_schema.py en el backend): a
  // qué proyecto pertenece este personaje. Se fija al crear y nunca se
  // reenvía en updates (ver nota en character_controller.py).
  final String? idProject;

  CharacterModel({
    this.idPersonaje,
    required this.nombre,
    required this.edad,
    required this.codigoPersonaje,
    this.idProject,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      idPersonaje: asString(pick(json, ['id_personaje'])),
      nombre: asString(pick(json, ['nombre'])) ?? '',
      edad: asInt(pick(json, ['edad'])) ?? 0,
      codigoPersonaje: asString(pick(json, ['codigo_personaje'])) ?? '',
      idProject: asString(pick(json, ['id_project'])),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'nombre': nombre,
        'edad': edad,
        'codigo_personaje': codigoPersonaje,
        if (idProject != null) 'id_project': idProject,
      };
}

const kGenerosActor = ['masculino', 'fenemino', 'otro']; // 'fenemino': typo real del enum en BD

// Catálogos de seguimiento de casting — pedido explícito del usuario
// (2026-09-02) al comparar la ficha técnica contra un Cast List real.
// Deben coincidir con StatusConfirmacion/CategoriaCast en
// actor_schema.py del backend.
const kStatusConfirmacionActor = ['Confirmado', 'No confirmado'];
const kCategoriasCast = ['Principal', 'Secundario', 'Personal de Apoyo'];

// Catálogos de maquillaje y caracterización — pedido explícito del
// usuario (2026-09-03) para no depender de texto libre. El backend
// guarda estos campos como texto plano (sin ENUM/Literal, ver
// actor_schema.py) justamente para que este catálogo pueda crecer sin
// requerir una migración; por eso las pantallas arman la lista del
// dropdown con estos valores + el valor ya guardado si no está en la
// lista (fichas viejas con texto libre no se rompen).
const kTexturasCabello = ['Liso', 'Ondulado', 'Rizado', 'Crespo', 'Afro', 'Otro'];
const kColoresOjos = ['Café', 'Negro', 'Verde', 'Azul', 'Miel', 'Gris', 'Ámbar', 'Otro'];
const kTiposPiel = ['Grasa', 'Seca', 'Mixta', 'Normal', 'Sensible', 'Otro'];
const kTonosPiel = ['Blanco', 'Trigueño', 'Moreno', 'Negro', 'Amarillo', 'Oliva', 'Otro'];

// Lista de países (nombre en español, orden alfabético) para el campo
// Nacionalidad — pedido explícito del usuario (2026-09-04): que salgan
// todos los países en una lista desplegable en vez de texto libre.
const kPaises = [
  'Afganistán', 'Albania', 'Alemania', 'Andorra', 'Angola', 'Antigua y Barbuda',
  'Arabia Saudita', 'Argelia', 'Argentina', 'Armenia', 'Australia', 'Austria',
  'Azerbaiyán', 'Bahamas', 'Bangladés', 'Barbados', 'Baréin', 'Bélgica', 'Belice',
  'Benín', 'Bielorrusia', 'Birmania', 'Bolivia', 'Bosnia y Herzegovina', 'Botsuana',
  'Brasil', 'Brunéi', 'Bulgaria', 'Burkina Faso', 'Burundi', 'Bután', 'Cabo Verde',
  'Camboya', 'Camerún', 'Canadá', 'Catar', 'Chad', 'Chile', 'China', 'Chipre',
  'Colombia', 'Comoras', 'Corea del Norte', 'Corea del Sur', 'Costa de Marfil',
  'Costa Rica', 'Croacia', 'Cuba', 'Dinamarca', 'Dominica', 'Ecuador', 'Egipto',
  'El Salvador', 'Emiratos Árabes Unidos', 'Eritrea', 'Eslovaquia', 'Eslovenia',
  'España', 'Estados Unidos', 'Estonia', 'Esuatini', 'Etiopía', 'Filipinas',
  'Finlandia', 'Fiyi', 'Francia', 'Gabón', 'Gambia', 'Georgia', 'Ghana', 'Granada',
  'Grecia', 'Guatemala', 'Guyana', 'Guinea', 'Guinea-Bisáu', 'Guinea Ecuatorial',
  'Haití', 'Honduras', 'Hungría', 'India', 'Indonesia', 'Irak', 'Irán', 'Irlanda',
  'Islandia', 'Islas Marshall', 'Islas Salomón', 'Israel', 'Italia', 'Jamaica',
  'Japón', 'Jordania', 'Kazajistán', 'Kenia', 'Kirguistán', 'Kiribati', 'Kuwait',
  'Laos', 'Lesoto', 'Letonia', 'Líbano', 'Liberia', 'Libia', 'Liechtenstein',
  'Lituania', 'Luxemburgo', 'Macedonia del Norte', 'Madagascar', 'Malasia',
  'Malaui', 'Maldivas', 'Malí', 'Malta', 'Marruecos', 'Mauricio', 'Mauritania',
  'México', 'Micronesia', 'Moldavia', 'Mónaco', 'Mongolia', 'Montenegro',
  'Mozambique', 'Namibia', 'Nauru', 'Nepal', 'Nicaragua', 'Níger', 'Nigeria',
  'Noruega', 'Nueva Zelanda', 'Omán', 'Países Bajos', 'Pakistán', 'Palaos',
  'Panamá', 'Papúa Nueva Guinea', 'Paraguay', 'Perú', 'Polonia', 'Portugal',
  'Reino Unido', 'República Centroafricana', 'República Checa',
  'República del Congo', 'República Democrática del Congo', 'República Dominicana',
  'Ruanda', 'Rumanía', 'Rusia', 'Samoa', 'San Cristóbal y Nieves', 'San Marino',
  'San Vicente y las Granadinas', 'Santa Lucía', 'Santo Tomé y Príncipe',
  'Senegal', 'Serbia', 'Seychelles', 'Sierra Leona', 'Singapur', 'Siria',
  'Somalia', 'Sri Lanka', 'Sudáfrica', 'Sudán', 'Sudán del Sur', 'Suecia',
  'Suiza', 'Surinam', 'Tailandia', 'Tanzania', 'Tayikistán', 'Timor Oriental',
  'Togo', 'Tonga', 'Trinidad y Tobago', 'Túnez', 'Turkmenistán', 'Turquía',
  'Tuvalu', 'Ucrania', 'Uganda', 'Uruguay', 'Uzbekistán', 'Vanuatu',
  'Vaticano', 'Venezuela', 'Vietnam', 'Yemen', 'Yibuti', 'Zambia', 'Zimbabue',
  'Otra',
];

class ActorModel {
  final String? idActor;
  final String nombre;
  final String apellido;
  final String genero;
  // Nullable: pedido explícito del usuario (2026-09-03) — solo
  // nombre/apellido son obligatorios de verdad para poder crear el
  // actor y desbloquear la subida de sus 2 fotos de inmediato; el resto
  // de la ficha técnica (esta fecha incluida) se completa después. Ver
  // sql/020_actor_campos_opcionales.sql y actor_schema.py del backend.
  final DateTime? fechaDeNacimiento;

  final String? tallaZapatos;
  final String? anchoEspalda;
  final String? pecho;
  final String? cintura;
  final String? cadera;
  final String? largoManga;
  final String? largoPierna;
  final String? tallaAnillo;
  final String? contornoCabeza;
  final String? contornoCuello;

  final String? colorCabello;
  final String texturaCabello;
  final String tipoPiel;
  final String colorOjos;
  final String? tonoPiel;

  final String? alergias;
  final String? habilidadesEspeciales;
  final String? restricciones;
  final String? comentariosAdicionales;

  final String? nacionalidad;
  final bool dobleRiesgo;
  final String? idPersonaje;
  // Obligatorio para crear (ver actor_schema.py en el backend).
  final String? idProject;

  // Contacto de producción + seguimiento de casting — pedido explícito
  // del usuario (2026-09-02), no forman parte de la ficha física.
  final String? cedula;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final String? statusConfirmacion;
  final String? llamados;
  final String? fechasTentativas;
  final bool? guionEnviado;
  final String? ensayos;
  final String? categoriaCast;

  ActorModel({
    this.idActor,
    required this.nombre,
    required this.apellido,
    required this.genero,
    this.fechaDeNacimiento,
    this.tallaZapatos,
    this.anchoEspalda,
    this.pecho,
    this.cintura,
    this.cadera,
    this.largoManga,
    this.largoPierna,
    this.tallaAnillo,
    this.contornoCabeza,
    this.contornoCuello,
    this.colorCabello,
    required this.texturaCabello,
    required this.tipoPiel,
    required this.colorOjos,
    this.tonoPiel,
    this.alergias,
    this.habilidadesEspeciales,
    this.restricciones,
    this.comentariosAdicionales,
    this.nacionalidad,
    required this.dobleRiesgo,
    this.idPersonaje,
    this.idProject,
    this.cedula,
    this.direccion,
    this.telefono,
    this.correo,
    this.statusConfirmacion,
    this.llamados,
    this.fechasTentativas,
    this.guionEnviado,
    this.ensayos,
    this.categoriaCast,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory ActorModel.fromJson(Map<String, dynamic> json) {
    final fecha = asString(pick(json, ['fecha_de_nacimiento']));
    return ActorModel(
      idActor: asString(pick(json, ['id_actor'])),
      nombre: asString(pick(json, ['nombre'])) ?? '',
      apellido: asString(pick(json, ['apellido'])) ?? '',
      genero: asString(pick(json, ['genero'])) ?? 'otro',
      fechaDeNacimiento: fecha != null ? DateTime.tryParse(fecha) : null,
      tallaZapatos: asString(pick(json, ['talla_zapatos'])),
      anchoEspalda: asString(pick(json, ['ancho_espalda'])),
      pecho: asString(pick(json, ['pecho'])),
      cintura: asString(pick(json, ['cintura'])),
      cadera: asString(pick(json, ['cadera'])),
      largoManga: asString(pick(json, ['largo_manga'])),
      largoPierna: asString(pick(json, ['largo_pierna'])),
      tallaAnillo: asString(pick(json, ['talla_anillo'])),
      contornoCabeza: asString(pick(json, ['contorno_cabeza'])),
      contornoCuello: asString(pick(json, ['contorno_cuello'])),
      colorCabello: asString(pick(json, ['color_cabello'])),
      texturaCabello: asString(pick(json, ['textura_cabello'])) ?? '',
      tipoPiel: asString(pick(json, ['tipo_piel'])) ?? '',
      colorOjos: asString(pick(json, ['color_ojos'])) ?? '',
      tonoPiel: asString(pick(json, ['tono_piel'])),
      alergias: asString(pick(json, ['alergias'])),
      habilidadesEspeciales: asString(pick(json, ['habilidades_especiales'])),
      restricciones: asString(pick(json, ['restricciones'])),
      comentariosAdicionales: asString(pick(json, ['comentarios_adicionales'])),
      nacionalidad: asString(pick(json, ['nacionalidad'])),
      dobleRiesgo: asBool(pick(json, ['doble_riesgo'])) ?? false,
      idPersonaje: asString(pick(json, ['id_personaje'])),
      idProject: asString(pick(json, ['id_project'])),
      cedula: asString(pick(json, ['cedula'])),
      direccion: asString(pick(json, ['direccion'])),
      telefono: asString(pick(json, ['telefono'])),
      correo: asString(pick(json, ['correo'])),
      statusConfirmacion: asString(pick(json, ['status_confirmacion'])),
      llamados: asString(pick(json, ['llamados'])),
      fechasTentativas: asString(pick(json, ['fechas_tentativas'])),
      guionEnviado: asBool(pick(json, ['guion_enviado'])),
      ensayos: asString(pick(json, ['ensayos'])),
      categoriaCast: asString(pick(json, ['categoria_cast'])),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'nombre': nombre,
        'apellido': apellido,
        'genero': genero,
        if (fechaDeNacimiento != null) 'fecha_de_nacimiento': fechaDeNacimiento!.toIso8601String().split('T').first,
        if (tallaZapatos != null && tallaZapatos!.isNotEmpty) 'talla_zapatos': tallaZapatos,
        if (anchoEspalda != null && anchoEspalda!.isNotEmpty) 'ancho_espalda': anchoEspalda,
        if (pecho != null && pecho!.isNotEmpty) 'pecho': pecho,
        if (cintura != null && cintura!.isNotEmpty) 'cintura': cintura,
        if (cadera != null && cadera!.isNotEmpty) 'cadera': cadera,
        if (largoManga != null && largoManga!.isNotEmpty) 'largo_manga': largoManga,
        if (largoPierna != null && largoPierna!.isNotEmpty) 'largo_pierna': largoPierna,
        if (tallaAnillo != null && tallaAnillo!.isNotEmpty) 'talla_anillo': tallaAnillo,
        if (contornoCabeza != null && contornoCabeza!.isNotEmpty) 'contorno_cabeza': contornoCabeza,
        if (contornoCuello != null && contornoCuello!.isNotEmpty) 'contorno_cuello': contornoCuello,
        if (colorCabello != null && colorCabello!.isNotEmpty) 'color_cabello': colorCabello,
        'textura_cabello': texturaCabello,
        'tipo_piel': tipoPiel,
        'color_ojos': colorOjos,
        if (tonoPiel != null && tonoPiel!.isNotEmpty) 'tono_piel': tonoPiel,
        if (alergias != null && alergias!.isNotEmpty) 'alergias': alergias,
        if (habilidadesEspeciales != null && habilidadesEspeciales!.isNotEmpty)
          'habilidades_especiales': habilidadesEspeciales,
        if (restricciones != null && restricciones!.isNotEmpty) 'restricciones': restricciones,
        if (comentariosAdicionales != null && comentariosAdicionales!.isNotEmpty)
          'comentarios_adicionales': comentariosAdicionales,
        if (nacionalidad != null && nacionalidad!.isNotEmpty) 'nacionalidad': nacionalidad,
        'doble_riesgo': dobleRiesgo,
        if (idPersonaje != null && idPersonaje!.isNotEmpty) 'id_personaje': idPersonaje,
        if (idProject != null) 'id_project': idProject,
        if (cedula != null && cedula!.isNotEmpty) 'cedula': cedula,
        if (direccion != null && direccion!.isNotEmpty) 'direccion': direccion,
        if (telefono != null && telefono!.isNotEmpty) 'telefono': telefono,
        if (correo != null && correo!.isNotEmpty) 'correo': correo,
        if (statusConfirmacion != null && statusConfirmacion!.isNotEmpty) 'status_confirmacion': statusConfirmacion,
        if (llamados != null && llamados!.isNotEmpty) 'llamados': llamados,
        if (fechasTentativas != null && fechasTentativas!.isNotEmpty) 'fechas_tentativas': fechasTentativas,
        if (guionEnviado != null) 'guion_enviado': guionEnviado,
        if (ensayos != null && ensayos!.isNotEmpty) 'ensayos': ensayos,
        if (categoriaCast != null && categoriaCast!.isNotEmpty) 'categoria_cast': categoriaCast,
      };
}
