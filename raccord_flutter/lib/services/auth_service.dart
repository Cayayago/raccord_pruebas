import '../core/api_client.dart';
import '../models/user.dart';

class LoginResult {
  final String token;
  final SessionUser user;
  final bool deviceVerified;

  LoginResult(this.token, this.user, {this.deviceVerified = false});
}

/// /users/login, /users/2fa/*, /register, /users/recover-password,
/// /users/reset-password — todo lo que no requiere sesión todavía.
class AuthService {
  final ApiClient api;
  AuthService(this.api);

  Future<LoginResult> login(String mail, String contrasena) async {
    final data = await api.post('/users/login', auth: false, body: {
      'mail': mail,
      'contrasena': contrasena,
    });
    final map = Map<String, dynamic>.from(data as Map);
    return LoginResult(
      map['access_token'] as String,
      SessionUser.fromJson(Map<String, dynamic>.from(map['usuario'] as Map)),
    );
  }

  // OJO: contrasena va en las 3 llamadas de 2FA porque el backend la
  // revalida en cada paso (antes no se enviaba y cualquier contraseña
  // dejaba pasar hasta la pantalla de código — el código de correo
  // era el único chequeo real).
  Future<bool> check2faRequired(String mail, String deviceId, String contrasena) async {
    final data = await api.post('/users/2fa/check', auth: false, body: {
      'mail': mail,
      'device_id': deviceId,
      'contrasena': contrasena,
    });
    final map = Map<String, dynamic>.from(data as Map);
    return map['requires_2fa'] == true;
  }

  Future<void> send2faCode(String mail, String deviceId, String contrasena) async {
    await api.post('/users/2fa/send', auth: false, body: {
      'mail': mail,
      'device_id': deviceId,
      'contrasena': contrasena,
    });
  }

  Future<LoginResult> verify2faCode(String mail, String codigo, String deviceId, String contrasena) async {
    final data = await api.post('/users/2fa/verify', auth: false, body: {
      'mail': mail,
      'codigo': codigo,
      'device_id': deviceId,
      'contrasena': contrasena,
    });
    final map = Map<String, dynamic>.from(data as Map);
    return LoginResult(
      map['access_token'] as String,
      SessionUser.fromJson(Map<String, dynamic>.from(map['usuario'] as Map)),
      deviceVerified: map['device_verified'] == true,
    );
  }

  /// Registro de empresa + primer usuario. No inicia sesión
  /// automáticamente (el backend no devuelve token en /register).
  Future<void> register({
    required String razonSocial,
    required String representanteLegal,
    required String emailEmpresa,
    String? address,
    String? telephone,
    String? numberCellphone,
    required String document,
    required String idDocument,
    required String nombre,
    required String apellido,
    required String mail,
    required String msisdn,
    required String contrasena,
  }) async {
    await api.post('/register', auth: false, body: {
      'razon_social': razonSocial,
      'representante_legal': representanteLegal,
      'email_empresa': emailEmpresa,
      if (address != null && address.isNotEmpty) 'address': address,
      if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      if (numberCellphone != null && numberCellphone.isNotEmpty) 'number_cellphone': numberCellphone,
      'document': document,
      'id_document': idDocument,
      'nombre': nombre,
      'apellido': apellido,
      'mail': mail,
      'msisdn': msisdn,
      'contrasena': contrasena,
    });
  }

  Future<void> recoverPassword(String mail) async {
    await api.post('/users/recover-password', auth: false, body: {'mail': mail});
  }

  Future<void> resetPassword(String mail, String codigo, String nuevaContrasena) async {
    await api.post('/users/reset-password', auth: false, body: {
      'mail': mail,
      'codigo': codigo,
      'nueva_contrasena': nuevaContrasena,
    });
  }
}
