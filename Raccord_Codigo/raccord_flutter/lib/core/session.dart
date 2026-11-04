import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/module_access.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../services/module_access_service.dart';
import '../services/project_service.dart';
import 'api_client.dart';
import 'permissions.dart';

const _kToken = 'raccord_token';
const _kUser = 'raccord_user'; // guardamos campos sueltos, más simple que json anidado
const _kDeviceId = 'raccord_device_id';
const _kProjectId = 'raccord_project_id';
const _kProjectName = 'raccord_project_name';
const _kProjectRole = 'raccord_project_rol';

/// Estado global de sesión: token JWT, usuario autenticado, proyecto
/// activo y device_id (usado por el flujo de 2FA para "recordar este
/// dispositivo", igual que localStorage.device_id en el frontend web).
///
/// Se persiste en SharedPreferences para sobrevivir a reinicios de la
/// app, y expone un [ApiClient] ya cableado con el token actual.
class AuthSession extends ChangeNotifier {
  String? _token;
  SessionUser? _user;
  String? _deviceId;
  String? _projectId;
  String? _projectName;
  // Rol EFECTIVO del usuario DENTRO del proyecto activo (user_projects.id_rol),
  // NUNCA el id_rol global de users.id_rol/JWT (_user.idRol) — ver
  // discusión completa en app/utils/project_scope.py del backend: una
  // misma persona puede ser Administrador de SU proyecto y, a la vez,
  // Onset (o cualquier otro rol) en un proyecto de alguien más. can()
  // debe reflejar SIEMPRE el rol del proyecto que se está viendo, no el
  // "de origen" del usuario.
  int? _projectRole;
  bool _ready = false;

  // Accesos personalizados por módulo (excepciones puntuales sobre el
  // rol, ver app/utils/module_access.py) del PROPIO usuario en el
  // proyecto activo — modulo -> nivel_efectivo. Solo en memoria (se
  // refresca al bootstrap/setProject, igual que _projectRole); si aún
  // no llegó la respuesta del backend, canSeeModule() no oculta nada
  // (mismo criterio que el resto de este archivo: el peor caso es un
  // ítem de menú visible que el backend rechaza, nunca al revés).
  Map<String, String> _moduleLevels = {};

  String? get token => _token;
  SessionUser? get user => _user;
  String? get deviceId => _deviceId;
  String? get projectId => _projectId;
  String? get projectName => _projectName;
  int? get projectRole => _projectRole;
  bool get isAuthenticated => _token != null && _user != null;
  bool get hasProject => _projectId != null && _projectId!.isNotEmpty;
  bool get ready => _ready;

  // Mientras no haya proyecto activo (ej. pantalla de selección de
  // proyecto) se usa el rol global del JWT como mejor aproximación —
  // ahí no hay "proyecto" contra el cual resolver nada todavía. En
  // cuanto hay un proyecto activo, SIEMPRE manda _projectRole.
  bool can(String permission) => hasPermission(hasProject ? _projectRole : _user?.idRol, permission);

  /// true si el módulo NO quedó forzado a "sin_acceso" por una
  /// excepción puntual (ver ModuloAccesos) — el rol sigue siendo la
  /// base (session.can), esto es solo la capa adicional de arriba.
  bool canSeeModule(String modulo) => _moduleLevels[modulo] != 'sin_acceso';

  late final ApiClient api = ApiClient(tokenProvider: () => _token);

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();

    _deviceId = prefs.getString(_kDeviceId);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_kDeviceId, _deviceId!);
    }

    _token = prefs.getString(_kToken);
    final mail = prefs.getString('${_kUser}_mail');
    if (_token != null && mail != null) {
      _user = SessionUser(
        idUser: prefs.getString('${_kUser}_id') ?? '',
        nombre: prefs.getString('${_kUser}_nombre') ?? '',
        apellido: prefs.getString('${_kUser}_apellido') ?? '',
        mail: mail,
        idRol: prefs.getInt('${_kUser}_rol') ?? 0,
        idClient: prefs.getString('${_kUser}_client'),
        idDepartamento: prefs.getString('${_kUser}_departamento'),
      );
    }

    _projectId = prefs.getString(_kProjectId);
    _projectName = prefs.getString(_kProjectName);
    _projectRole = prefs.getInt(_kProjectRole);

    _ready = true;
    notifyListeners();

    // El rol cacheado puede haber quedado desactualizado (ej. alguien
    // cambió el rol del usuario en este proyecto desde otro
    // dispositivo/sesión) — se refresca en segundo plano sin bloquear
    // el arranque de la app.
    if (hasProject) {
      unawaited(refreshProjectRole());
      unawaited(refreshModuleAccess());
    }
  }

  /// Vuelve a consultar el rol efectivo del usuario en el proyecto
  /// activo (GET /users/{id_user}/projects) y lo persiste. Se usa al
  /// arrancar la app (ver bootstrap) y puede llamarse manualmente si
  /// una pantalla sospecha que el rol pudo haber cambiado.
  Future<void> refreshProjectRole() async {
    if (_user == null || !hasProject) return;
    try {
      final projects = await ProjectService(api).myProjects(_user!.idUser);
      final match = projects.where((p) => p.idProject == _projectId).toList();
      if (match.isEmpty) return;
      _projectRole = match.first.idRol;
      final prefs = await SharedPreferences.getInstance();
      if (_projectRole != null) {
        await prefs.setInt(_kProjectRole, _projectRole!);
      } else {
        await prefs.remove(_kProjectRole);
      }
      notifyListeners();
    } catch (_) {
      // Sin conexión o error de red: se mantiene el rol cacheado hasta
      // el próximo intento — no tumba la app por esto.
    }
  }

  /// Vuelve a consultar los accesos personalizados por módulo del
  /// PROPIO usuario en el proyecto activo (ver ModuleAccessService) y
  /// los cachea en memoria para que canSeeModule() decida qué mostrar
  /// en el menú lateral. Igual que refreshProjectRole: se llama en
  /// segundo plano, nunca bloquea la navegación ni tumba la app si
  /// falla.
  Future<void> refreshModuleAccess() async {
    if (_user == null || !hasProject) return;
    try {
      final accesos = await ModuleAccessService(api).list(_projectId!, _user!.idUser);
      _moduleLevels = {for (final a in accesos) a.modulo: a.nivelEfectivo};
      notifyListeners();
    } catch (_) {
      // Sin conexión, o la persona ya no pertenece a este proyecto:
      // se mantiene lo cacheado (o vacío) hasta el próximo intento.
    }
  }

  Future<void> setSession(String token, SessionUser user) async {
    _token = token;
    _user = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString('${_kUser}_id', user.idUser);
    await prefs.setString('${_kUser}_nombre', user.nombre);
    await prefs.setString('${_kUser}_apellido', user.apellido);
    await prefs.setString('${_kUser}_mail', user.mail);
    await prefs.setInt('${_kUser}_rol', user.idRol);
    if (user.idClient != null) {
      await prefs.setString('${_kUser}_client', user.idClient!);
    }
    if (user.idDepartamento != null) {
      await prefs.setString('${_kUser}_departamento', user.idDepartamento!);
    }

    notifyListeners();
  }

  Future<void> updateUserNames(String nombre, String apellido) async {
    if (_user == null) return;
    _user = SessionUser(
      idUser: _user!.idUser,
      nombre: nombre,
      apellido: apellido,
      mail: _user!.mail,
      idRol: _user!.idRol,
      idClient: _user!.idClient,
      idDepartamento: _user!.idDepartamento,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_kUser}_nombre', nombre);
    await prefs.setString('${_kUser}_apellido', apellido);
    notifyListeners();
  }

  /// [project.idRol] es el rol EFECTIVO en ESE proyecto (viene de
  /// user_projects, ver GET /users/{id_user}/projects — no siempre
  /// viene poblado, ver comentario en models/project.dart). Si falta,
  /// se dispara [refreshProjectRole] para resolverlo contra el backend
  /// antes de dejar que la UI decida qué mostrar con permisos
  /// desactualizados o vacíos.
  Future<void> setProject(Project project) async {
    _projectId = project.idProject;
    _projectName = project.projectName;
    _projectRole = project.idRol;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProjectId, _projectId!);
    await prefs.setString(_kProjectName, _projectName!);
    if (_projectRole != null) {
      await prefs.setInt(_kProjectRole, _projectRole!);
    } else {
      await prefs.remove(_kProjectRole);
    }

    notifyListeners();

    if (_projectRole == null) {
      await refreshProjectRole();
    }
    unawaited(refreshModuleAccess());
  }

  Future<void> clearProject() async {
    _projectId = null;
    _projectName = null;
    _projectRole = null;
    _moduleLevels = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProjectId);
    await prefs.remove(_kProjectName);
    await prefs.remove(_kProjectRole);
    notifyListeners();
  }

  /// Cierra sesión también del lado del SERVIDOR (POST /users/logout
  /// revoca el jti de este token, ver app/utils/token_revocation.py en
  /// el backend) antes de limpiar el estado local. Debe ir primero:
  /// una vez que _token se pone en null, api ya no puede mandar el
  /// Bearer que identifica cuál token hay que revocar.
  ///
  /// Si la llamada falla (sin conexión, token ya vencido, etc.) el
  /// logout local sigue adelante igual — no tiene sentido dejar a la
  /// persona "atrapada" en la app porque el aviso al servidor no pudo
  /// salir; en el peor caso ese token queda válido hasta su
  /// expiración natural, exactamente como pasaba antes de este fix.
  Future<void> logout() async {
    if (_token != null) {
      try {
        await api.post('/users/logout');
      } catch (_) {}
    }

    _token = null;
    _user = null;
    _projectId = null;
    _projectName = null;
    _projectRole = null;
    _moduleLevels = {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove('${_kUser}_id');
    await prefs.remove('${_kUser}_nombre');
    await prefs.remove('${_kUser}_apellido');
    await prefs.remove('${_kUser}_mail');
    await prefs.remove('${_kUser}_rol');
    await prefs.remove('${_kUser}_client');
    await prefs.remove('${_kUser}_departamento');
    await prefs.remove(_kProjectId);
    await prefs.remove(_kProjectName);
    await prefs.remove(_kProjectRole);

    notifyListeners();
  }
}
