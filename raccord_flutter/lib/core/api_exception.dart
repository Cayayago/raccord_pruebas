/// Excepción lanzada cuando la API responde con success=false, con un
/// código HTTP de error, o cuando la respuesta no se pudo interpretar.
class ApiException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  ApiException(this.message, {this.errorCode, this.statusCode});

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}
