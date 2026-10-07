import '../core/json_utils.dart';

/// Usuario en sesión (lo que devuelve /users/login dentro de "usuario").
class SessionUser {
  final String idUser;
  final String nombre;
  final String apellido;
  final String mail;
  final int idRol;
  final String? idClient;
  // Departamento del usuario en sesión — usado para decidir, del lado
  // del cliente, si un Jefe de Departamento (1003) puede suspender/
  // reactivar a otra persona (solo si es de su mismo departamento). La
  // validación real vive en el backend; esto solo evita mostrar un
  // botón que igual sería rechazado.
  final String? idDepartamento;

  SessionUser({
    required this.idUser,
    required this.nombre,
    required this.apellido,
    required this.mail,
    required this.idRol,
    this.idClient,
    this.idDepartamento,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      idUser: asString(pick(json, ['id_user'])) ?? '',
      nombre: asString(pick(json, ['nombre'])) ?? '',
      apellido: asString(pick(json, ['apellido'])) ?? '',
      mail: asString(pick(json, ['mail'])) ?? '',
      idRol: asInt(pick(json, ['id_rol'])) ?? 0,
      idClient: asString(pick(json, ['id_client'])),
      idDepartamento: asString(pick(json, ['id_departamento'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_user': idUser,
        'nombre': nombre,
        'apellido': apellido,
        'mail': mail,
        'id_rol': idRol,
        'id_client': idClient,
        'id_departamento': idDepartamento,
      };
}

/// Registro completo de usuario (respuesta de GET /users/{id} y de la
/// lista de /users/project/{id}).
class AppUser {
  final String idUser;
  final String nombre;
  final String apellido;
  final String? identificacion;
  final String? idIdentificacion;
  final String mail;
  final String? msisdn;
  final String? direccion;
  final DateTime? fechaDeNacimiento;
  final String? estado;
  final DateTime? fechaDeCreacion;
  final int? idRol;
  final String? idDepartamento;

  AppUser({
    required this.idUser,
    required this.nombre,
    required this.apellido,
    this.identificacion,
    this.idIdentificacion,
    required this.mail,
    this.msisdn,
    this.direccion,
    this.fechaDeNacimiento,
    this.estado,
    this.fechaDeCreacion,
    this.idRol,
    this.idDepartamento,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final fechaNacimiento = asString(pick(json, ['fecha_de_nacimiento']));
    final fechaCreacion = asString(pick(json, ['fecha_de_creacion']));
    return AppUser(
      idUser: asString(pick(json, ['id_user'])) ?? '',
      nombre: asString(pick(json, ['nombre'])) ?? '',
      apellido: asString(pick(json, ['apellido'])) ?? '',
      identificacion: asString(pick(json, ['identificacion'])),
      idIdentificacion: asString(pick(json, ['id_identificacion'])),
      mail: asString(pick(json, ['mail'])) ?? '',
      msisdn: asString(pick(json, ['msisdn'])),
      direccion: asString(pick(json, ['direccion'])),
      fechaDeNacimiento: fechaNacimiento != null ? DateTime.tryParse(fechaNacimiento) : null,
      estado: asString(pick(json, ['estado'])),
      fechaDeCreacion: fechaCreacion != null ? DateTime.tryParse(fechaCreacion) : null,
      idRol: asInt(pick(json, ['id_rol'])),
      idDepartamento: asString(pick(json, ['id_departamento'])),
    );
  }
}
