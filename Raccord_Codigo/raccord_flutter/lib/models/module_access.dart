import '../core/json_utils.dart';

/// Espejo en Dart de app/utils/module_access.py — catálogo de los 9
/// módulos reales del menú y los 5 niveles de acceso. Se usa SOLO para
/// el diálogo "Personalizar accesos" (Roles del Equipo); la
/// aplicación real de la excepción siempre la hace el backend.
class ModuloAccesos {
  ModuloAccesos._();

  static const Map<String, String> modulos = {
    'guion': 'Guión',
    'escenas': 'Escenas',
    'desglose': 'Desglose',
    'plan_rodaje': 'Plan de Rodaje',
    'personajes': 'Personajes',
    'cast': 'Cast List',
    'galeria': 'Galería',
    'crew_list': 'Crew List',
    'roles': 'Roles',
  };

  static const Map<String, String> niveles = {
    'sin_acceso': 'Sin acceso',
    'ver': 'Ver',
    'comentar': 'Comentar',
    'editar': 'Editar',
    'administrar': 'Administrar',
  };

  static const Map<String, int> nivelRango = {
    'sin_acceso': 0,
    'ver': 1,
    'comentar': 2,
    'editar': 3,
    'administrar': 4,
  };

  static String labelModulo(String modulo) => modulos[modulo] ?? modulo;
  static String labelNivel(String nivel) => niveles[nivel] ?? nivel;
}

/// Nivel de acceso (rol + excepción, si existe) de UNA persona a UN
/// módulo puntual — ver GET /projects/{id}/users/{id}/module-access.
class ModuleAccessModel {
  final String modulo;
  final String label;
  final String nivelRol;
  final String nivelRolLabel;
  final String? nivelExcepcion;
  final bool esExcepcion;
  final String nivelEfectivo;
  final String nivelEfectivoLabel;

  ModuleAccessModel({
    required this.modulo,
    required this.label,
    required this.nivelRol,
    required this.nivelRolLabel,
    required this.nivelExcepcion,
    required this.esExcepcion,
    required this.nivelEfectivo,
    required this.nivelEfectivoLabel,
  });

  factory ModuleAccessModel.fromJson(Map<String, dynamic> json) => ModuleAccessModel(
        modulo: asString(pick(json, ['modulo'])) ?? '',
        label: asString(pick(json, ['label'])) ?? '',
        nivelRol: asString(pick(json, ['nivel_rol'])) ?? 'sin_acceso',
        nivelRolLabel: asString(pick(json, ['nivel_rol_label'])) ?? '',
        nivelExcepcion: asString(pick(json, ['nivel_excepcion'])),
        esExcepcion: asBool(pick(json, ['es_excepcion'])) ?? false,
        nivelEfectivo: asString(pick(json, ['nivel_efectivo'])) ?? 'sin_acceso',
        nivelEfectivoLabel: asString(pick(json, ['nivel_efectivo_label'])) ?? '',
      );
}
