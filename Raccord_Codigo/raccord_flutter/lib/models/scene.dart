import '../core/json_utils.dart';

// "Espacio" (INT/EXT) y "Momento" (Día/Noche/...) son dos catálogos
// independientes — pedido explícito del usuario: en toda la app deben
// mostrarse y editarse como dos campos separados, nunca como un único
// valor combinado tipo "int/noche" (la única excepción es el texto
// libre del encabezado de la escena, que no se toca).
const kModosVista = ['int', 'ext', 'int/ext', 'ext/int'];
const kMomentosDia = ['dia', 'noche', 'amanecer', 'atardecer', 'anochecer'];
const kEstadosEscena = ['Pendiente', 'En proceso', 'Finalizada', 'Eliminada'];

/// Etiqueta legible de cada valor de `momentoDia` (ej. 'dia' -> 'Día').
const kMomentoLabels = {
  'dia': 'Día',
  'noche': 'Noche',
  'amanecer': 'Amanecer',
  'atardecer': 'Atardecer',
  'anochecer': 'Anochecer',
};

/// Devuelve la etiqueta legible de [momento] (o '?' si no hay valor) —
/// nunca lanza, para no tumbar una pantalla por un dato viejo que ya no
/// esté en el catálogo (ej. una combinación tipo "amanecer/dia" creada
/// antes de este cambio).
String labelMomento(String? momento) {
  if (momento == null || momento.isEmpty) return '?';
  return kMomentoLabels[momento] ?? momento;
}

/// Un ícono (emoji) pequeño y claro por cada momento del día — pedido
/// explícito del usuario para REEMPLAZAR el color como forma de
/// distinguir día/noche/etc. en Plan de Rodaje: el cliente ya usa
/// colores para su propia segmentación y el color-coding de la app
/// interfería con eso. El texto (ver [labelMomento]) se mantiene, el
/// ícono solo sustituye el color, nunca al texto.
///
/// NOTA: la UI ya NO usa estos emojis directamente (ver
/// `iconoMomentoData` en shooting_days_screen.dart) — Flutter Web no
/// trae ninguna fuente que incluya estos glifos y el navegador tiraba
/// la advertencia de consola "Could not find a set of Noto fonts...".
/// Se dejan acá por si algún export de texto plano (CSV) los necesita.
const kMomentoIconos = {
  'dia': '☀️',
  'noche': '🌙',
  'amanecer': '🌄', // "Sunrise Over Mountains"
  'atardecer': '🌇', // "Sunset"
  'anochecer': '🌆', // "Cityscape at Dusk"
};

String iconoMomento(String? momento) {
  if (momento == null) return '';
  return kMomentoIconos[momento] ?? '';
}

class Scene {
  final String? idEscena;
  final String numeroDeEscena;
  final String encabezado;
  final String? descripcion;
  final String? idGuion;
  final String? modoVista;
  final String? momentoDia;
  final String? ciudad;
  final int? pagina;
  final DateTime? fechaDeGrabacion;
  final int? diaDramatico;
  final String? idRodaje;
  final String? idDesglose;
  final String estado;

  // Datos PROPIOS del Plan de Rodaje (no de la escena narrativa) — se
  // editan desde esa pantalla, no desde el editor general de Escenas.
  // Ver app/models/scene_model.py y sql/007_plan_rodaje_datos_propios.sql.
  final String? locacionRodaje;
  final String? tiempoEstimado;
  final String? horaInicioRodaje; // "HH:MM:SS" (formato hora backend)
  final String? notasRodaje;
  final int? ordenRodaje;
  // Agrupación manual (1, 2, 3...) para filtrar escenas por "bloque de
  // grabación" — independiente del día de rodaje asignado. Visible y
  // editable tanto en Plan de Rodaje como filtrable en Escenas.
  final int? bloqueGrabacion;
  // Comentarios libres de la escena, editables desde el panel
  // "Información de la Escena" en Continuidad Visual — distinto de
  // `descripcion` (sinopsis narrativa fijada al crear la escena) y de
  // `notasRodaje` (específicas del día de rodaje). Pedido explícito del
  // usuario (2026-09-02).
  final String? comentarios;

  // Cast (reparto) de la escena, embebido por el backend en
  // GET /scenes/project/{id} (ver scene_controller.py) — solo viene
  // presente ahí; en otros endpoints de Scene es null. Antes Plan de
  // Rodaje pedía esto por separado con un GET /scenes/{id}/cast POR
  // escena (SceneService.cast), que con ~129 escenas en un proyecto
  // real disparaba ~129 peticiones HTTP y tardaba decenas de segundos
  // en un dispositivo físico. Cada item trae las mismas claves que
  // SceneService.cast(): id_personaje, nombre, edad, codigo_personaje.
  final List<Map<String, dynamic>>? cast;

  Scene({
    this.idEscena,
    required this.numeroDeEscena,
    required this.encabezado,
    this.descripcion,
    this.idGuion,
    this.modoVista,
    this.momentoDia,
    this.ciudad,
    this.pagina,
    this.fechaDeGrabacion,
    this.diaDramatico,
    this.idRodaje,
    this.idDesglose,
    this.estado = 'Pendiente',
    this.locacionRodaje,
    this.tiempoEstimado,
    this.horaInicioRodaje,
    this.notasRodaje,
    this.ordenRodaje,
    this.bloqueGrabacion,
    this.comentarios,
    this.cast,
  });

  String get modoYMomento {
    final parts = <String>[];
    if (modoVista != null) parts.add(modoVista!.toUpperCase());
    if (momentoDia != null) parts.add(momentoDia!);
    return parts.join(' · ');
  }

  factory Scene.fromJson(Map<String, dynamic> json) {
    final fecha = asString(pick(json, ['fecha_de_grabacion']));
    final rawCast = json['cast'];
    return Scene(
      idEscena: asString(pick(json, ['id_escena'])),
      numeroDeEscena: asString(pick(json, ['numero_de_escena'])) ?? '',
      encabezado: asString(pick(json, ['encabezado'])) ?? '',
      descripcion: asString(pick(json, ['descripcion'])),
      idGuion: asString(pick(json, ['id_guion'])),
      modoVista: asString(pick(json, ['modo_vista'])),
      momentoDia: asString(pick(json, ['momento_dia'])),
      ciudad: asString(pick(json, ['ciudad'])),
      pagina: asInt(pick(json, ['pagina'])),
      fechaDeGrabacion: fecha != null ? DateTime.tryParse(fecha) : null,
      diaDramatico: asInt(pick(json, ['dia_dramatico'])),
      idRodaje: asString(pick(json, ['id_rodaje'])),
      idDesglose: asString(pick(json, ['id_desglose'])),
      estado: asString(pick(json, ['estado'])) ?? 'Pendiente',
      locacionRodaje: asString(pick(json, ['locacion_rodaje'])),
      tiempoEstimado: asString(pick(json, ['tiempo_estimado'])),
      horaInicioRodaje: asString(pick(json, ['hora_inicio_rodaje'])),
      notasRodaje: asString(pick(json, ['notas_rodaje'])),
      ordenRodaje: asInt(pick(json, ['orden_rodaje'])),
      bloqueGrabacion: asInt(pick(json, ['bloque_grabacion'])),
      comentarios: asString(pick(json, ['comentarios'])),
      cast: rawCast is List ? rawCast.whereType<Map<String, dynamic>>().toList() : null,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'numero_de_escena': numeroDeEscena,
        'encabezado': encabezado,
        if (descripcion != null && descripcion!.isNotEmpty) 'descripcion': descripcion,
        if (idGuion != null) 'id_guion': idGuion,
        if (modoVista != null) 'modo_vista': modoVista,
        if (momentoDia != null) 'momento_dia': momentoDia,
        if (ciudad != null && ciudad!.isNotEmpty) 'ciudad': ciudad,
        if (pagina != null) 'pagina': pagina,
        if (fechaDeGrabacion != null)
          'fecha_de_grabacion': fechaDeGrabacion!.toIso8601String().split('T').first,
        if (diaDramatico != null) 'dia_dramatico': diaDramatico,
        if (idRodaje != null && idRodaje!.isNotEmpty) 'id_rodaje': idRodaje,
        if (idDesglose != null && idDesglose!.isNotEmpty) 'id_desglose': idDesglose,
        'estado': estado,
        if (locacionRodaje != null && locacionRodaje!.isNotEmpty) 'locacion_rodaje': locacionRodaje,
        if (tiempoEstimado != null && tiempoEstimado!.isNotEmpty) 'tiempo_estimado': tiempoEstimado,
        if (horaInicioRodaje != null && horaInicioRodaje!.isNotEmpty) 'hora_inicio_rodaje': horaInicioRodaje,
        if (notasRodaje != null && notasRodaje!.isNotEmpty) 'notas_rodaje': notasRodaje,
        if (ordenRodaje != null) 'orden_rodaje': ordenRodaje,
        if (bloqueGrabacion != null) 'bloque_grabacion': bloqueGrabacion,
        if (comentarios != null && comentarios!.isNotEmpty) 'comentarios': comentarios,
      };
}
