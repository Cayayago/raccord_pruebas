import '../core/json_utils.dart';

/// Modelos "catálogo" pequeños: rol, departamento, cliente. Comparten
/// forma simple id/nombre y se usan sobre todo para dropdowns.

class RoleModel {
  final int idRol;
  final String nombre;
  final String? nivelJerarquia;
  final String? descripcion;
  final bool activo;

  RoleModel({
    required this.idRol,
    required this.nombre,
    this.nivelJerarquia,
    this.descripcion,
    this.activo = true,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      idRol: asInt(pick(json, ['id_rol'])) ?? 0,
      nombre: asString(pick(json, ['nombre'])) ?? '',
      nivelJerarquia: asString(pick(json, ['nivel_jerarquia'])),
      descripcion: asString(pick(json, ['descripcion'])),
      activo: asBool(pick(json, ['activo'])) ?? true,
    );
  }
}

class Department {
  final String idDepartamento;
  final String nombre;
  final String ubicacion;

  Department({required this.idDepartamento, required this.nombre, required this.ubicacion});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      idDepartamento: asString(pick(json, ['id_departamento'])) ?? '',
      nombre: asString(pick(json, ['nombre'])) ?? '',
      ubicacion: asString(pick(json, ['ubicacion'])) ?? '',
    );
  }
}

class ClientModel {
  final String? idClient;
  final String document;
  final String razonSocial;
  final String representanteLegal;
  final String email;

  ClientModel({
    this.idClient,
    required this.document,
    required this.razonSocial,
    required this.representanteLegal,
    required this.email,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      idClient: asString(pick(json, ['id_client'])),
      document: asString(pick(json, ['document'])) ?? '',
      razonSocial: asString(pick(json, ['razon_social'])) ?? '',
      representanteLegal: asString(pick(json, ['representante_legal'])) ?? '',
      email: asString(pick(json, ['email'])) ?? '',
    );
  }
}
