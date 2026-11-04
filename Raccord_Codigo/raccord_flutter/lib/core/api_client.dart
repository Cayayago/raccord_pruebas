import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'api_exception.dart';

/// Tiempo máximo que se espera CUALQUIER petición antes de darla por
/// caída y mostrar un error, en vez de dejar la pantalla "cargando"
/// para siempre. Antes no había timeout: si el backend configurado no
/// respondía (ej. IP/puerto mal apuntado desde un celular físico), el
/// usuario se quedaba viendo un spinner sin ningún mensaje, sin forma
/// de saber que algo estaba mal.
const kApiRequestTimeout = Duration(seconds: 8);

/// Timeout específico para subir archivos (fotos, PDFs) — 8s se queda
/// corto para una foto de cámara sin comprimir (varios MB) sobre una
/// red real (a diferencia de JSON liviano en localhost). 30s da margen
/// de sobra sin dejar a la persona esperando para siempre si el
/// backend/red realmente está caído.
const kApiUploadTimeout = Duration(seconds: 30);

/// Envoltorio delgado sobre [http] que:
/// - arma la URL base + Bearer token en cada petición protegida
/// - decodifica el envelope {success, message, data, error} que usa
///   toda la API de Raccord (ver app/utils/response.py)
/// - convierte respuestas no exitosas en [ApiException]
/// - corta cualquier petición colgada a los [kApiRequestTimeout]
class ApiClient {
  final String? Function() tokenProvider;
  final http.Client _http;

  ApiClient({required this.tokenProvider, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = ApiConfig.baseUrl;
    final full = path.startsWith('http') ? path : '$base$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, '$v')),
    });
  }

  Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = tokenProvider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final res = await _http.get(_uri(path, query), headers: _headers(auth: auth)).timeout(kApiRequestTimeout, onTimeout: _onTimeout);
    return _parse(res);
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    final res = await _http
        .post(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(kApiRequestTimeout, onTimeout: _onTimeout);
    return _parse(res);
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    final res = await _http
        .put(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(kApiRequestTimeout, onTimeout: _onTimeout);
    return _parse(res);
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) async {
    final res = await _http
        .patch(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? {}),
        )
        .timeout(kApiRequestTimeout, onTimeout: _onTimeout);
    return _parse(res);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final res = await _http.delete(_uri(path), headers: _headers(auth: auth)).timeout(kApiRequestTimeout, onTimeout: _onTimeout);
    return _parse(res);
  }

  /// Sube un archivo binario (multipart/form-data) — usado para el PDF
  /// de guiones (POST /scripts/{id}/archivo) y las fotos de
  /// continuidad (POST /scenes/{id}/fotos). El backend espera el
  /// campo bajo el nombre `fieldName` (FastAPI: `file: UploadFile`).
  /// `fields` son campos de texto adicionales del mismo formulario
  /// (FastAPI: `Form(...)`) — ej. tipo_foto, descripcion.
  ///
  /// `bytes`/`filename` son opcionales (a diferencia de antes, que los
  /// exigía siempre): las Notificaciones (ver notification_service.dart)
  /// reusan este mismo método para un formulario multipart cuya foto es
  /// opcional — sin bytes, se manda el formulario sin archivo adjunto
  /// (el backend ya trata `file: UploadFile | None = File(None)`).
  Future<dynamic> postFile(
    String path, {
    required String fieldName,
    List<int>? bytes,
    String? filename,
    String? contentType,
    Map<String, String>? fields,
    bool auth = true,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    final headers = _headers(auth: auth)..remove('Content-Type'); // multipart arma su propio boundary
    request.headers.addAll(headers);
    if (fields != null) request.fields.addAll(fields);
    if (bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename ?? 'archivo',
        contentType: contentType != null ? MediaType.parse(contentType) : null,
      ));
    }
    // Antes SOLO el envío tenía timeout — la lectura del cuerpo de la
    // respuesta (fromStream) podía quedarse esperando para siempre sin
    // avisar nada si el backend tardaba en terminar de procesar/guardar
    // el archivo. Eso era lo que dejaba la UI trabada en "subiendo
    // foto..." indefinidamente con fotos de cámara (más pesadas que las
    // de galería/archivo, que sí solían terminar a tiempo).
    final streamed = await _http.send(request).timeout(kApiUploadTimeout, onTimeout: _onTimeout);
    final res = await http.Response.fromStream(streamed).timeout(kApiUploadTimeout, onTimeout: _onTimeout);
    return _parse(res);
  }

  /// Descarga bytes crudos (no JSON) — usado para leer el PDF de un
  /// guion (GET /scripts/{id}/archivo) antes de mostrarlo en el visor.
  Future<List<int>> getBytes(String path, {bool auth = true}) async {
    final res = await _http
        .get(_uri(path), headers: _headers(auth: auth)..remove('Content-Type'))
        .timeout(kApiRequestTimeout, onTimeout: _onTimeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'No se pudo descargar el archivo (${res.statusCode})';
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map && decoded['detail'] is String) message = decoded['detail'];
      } catch (_) {}
      throw ApiException(message, statusCode: res.statusCode);
    }
    return res.bodyBytes;
  }

  /// Mensaje único para cualquier petición que se pasó de
  /// [kApiRequestTimeout] sin respuesta — normalmente porque
  /// ApiConfig.baseUrl apunta a una dirección/puerto que no responde
  /// (ej. servidor caído, o IP mal configurada desde un dispositivo
  /// físico). errorCode 'TIMEOUT' para que la UI lo distinga de un
  /// error de credenciales/validación si hace falta.
  // Devuelve Never (nunca retorna, siempre lanza): por eso sirve tal
  // cual como onTimeout tanto para Future<http.Response> (get/post/...)
  // como para Future<http.StreamedResponse> (send, usado en postFile)
  // — Never es subtipo de cualquier tipo, así que encaja en ambas
  // firmas sin necesitar un callback distinto por cada una.
  Never _onTimeout() {
    throw ApiException(
      'El servidor no respondió a tiempo. Verifica tu conexión e inténtalo de nuevo.',
      errorCode: 'TIMEOUT',
    );
  }

  dynamic _parse(http.Response res) {
    Map<String, dynamic>? envelope;

    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) envelope = decoded;
      } catch (_) {
        // Respuesta no JSON (ej. error de proxy/red) -> se maneja abajo.
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (envelope == null) return null;

      if (envelope['success'] == false) {
        throw ApiException(
          envelope['message']?.toString() ?? 'La operación no fue exitosa',
          errorCode: envelope['error']?.toString(),
          statusCode: res.statusCode,
        );
      }

      return envelope['data'];
    }

    // Errores HTTP (401/403/404/422/500...). FastAPI también puede
    // responder {"detail": "..."} para errores levantados por
    // HTTPException (ej. middleware de auth), y {"detail": [...]}
    // para errores 422 de validación de Pydantic.
    String message = 'Error de conexión con el servidor (${res.statusCode})';
    String? errorCode = envelope?['error']?.toString();

    if (envelope != null) {
      final detail = envelope['detail'] ?? envelope['message'];
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          message = first['msg'].toString();
        }
      }
    }

    throw ApiException(message, errorCode: errorCode, statusCode: res.statusCode);
  }
}
