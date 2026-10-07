import '../core/json_utils.dart';

class Project {
  final String idProject;
  final String projectName;
  final String formatoDeProduccion;
  final String genero;
  final String? sinopsis;
  final String? director;
  final String idClient;
  // Rol EFECTIVO del usuario actual EN ESTE proyecto puntual (viene de
  // user_projects.id_rol, ver GET /users/{id_user}/projects) — nunca el
  // id_rol global de users.id_rol/JWT. Solo viene poblado cuando el
  // Project sale de ese endpoint (ej. ProjectSelectionScreen); en otros
  // usos (GET /projects/{id}, etc.) queda null. Ver AuthSession.setProject
  // en core/session.dart, que es quien realmente decide qué permisos
  // tiene el usuario dentro del proyecto activo.
  final int? idRol;

  Project({
    required this.idProject,
    required this.projectName,
    required this.formatoDeProduccion,
    required this.genero,
    this.sinopsis,
    this.director,
    required this.idClient,
    this.idRol,
  });

  String get resumen =>
      [formatoDeProduccion, genero, if (director != null && director!.isNotEmpty) 'Dir. $director']
          .where((e) => e.isNotEmpty)
          .join(' · ');

  /// Copia este Project pero con un id_rol distinto — usado cuando se
  /// sabe el rol efectivo por fuera del JSON (ej. justo después de
  /// crear un proyecto, donde el creador siempre queda como
  /// Administrador — ver ProjectService.createAndLink).
  Project withIdRol(int? idRol) => Project(
        idProject: idProject,
        projectName: projectName,
        formatoDeProduccion: formatoDeProduccion,
        genero: genero,
        sinopsis: sinopsis,
        director: director,
        idClient: idClient,
        idRol: idRol,
      );

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      idProject: asString(pick(json, ['id_project'])) ?? '',
      projectName: asString(pick(json, ['project_name'])) ?? '',
      formatoDeProduccion: asString(pick(json, ['formato_de_produccion'])) ?? '',
      genero: asString(pick(json, ['genero'])) ?? '',
      sinopsis: asString(pick(json, ['sinopsis'])),
      director: asString(pick(json, ['director'])),
      idClient: asString(pick(json, ['id_client'])) ?? '',
      idRol: asInt(pick(json, ['id_rol'])),
    );
  }
}

/// Formatos y géneros ofrecidos en el mockup de "Registrar Proyecto".
/// El backend los guarda como texto libre, así que estas listas son
/// solo para la UI (dropdown); no hay un catálogo en la API todavía.
const kFormatosProduccion = [
  'Largometraje',
  'Cortometraje',
  'Serie',
  'Documental',
  'Comercial',
  'Videoclip',
];

const kGenerosProduccion = [
  'Drama',
  'Comedia',
  'Thriller',
  'Terror',
  'Acción',
  'Histórico',
  'Documental',
  'Romance',
  'Ciencia ficción',
  'Otro',
];
