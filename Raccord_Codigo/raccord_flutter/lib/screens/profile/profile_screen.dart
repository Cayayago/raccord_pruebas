import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/permissions.dart';
import '../../core/session.dart';
import '../../models/catalog.dart';
import '../../models/document_type.dart';
import '../../models/user.dart';
import '../../services/department_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/state_views.dart';

/// Mi Perfil: datos personales editables + campos de solo lectura
/// (correo, fecha de creación, departamento, proyecto — estos cuatro
/// solo los cambia un Administrador/Director desde la gestión de
/// usuarios, nunca la propia persona) + foto de perfil (MinIO) +
/// cambio de contraseña (exige confirmar la actual).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _future;

  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _msisdn = TextEditingController();
  final _direccion = TextEditingController();
  final _idIdentificacion = TextEditingController();
  final _fechaNacimientoCtrl = TextEditingController();
  String _tipoIdentificacion = kTiposDocumento.first;
  DateTime? _fechaNacimiento;
  bool _savingInfo = false;

  Future<List<int>>? _avatarBytes;
  bool _uploadingAvatar = false;

  // Solo Administrador (1001) y Director (1002) pueden cambiar su
  // propio departamento desde este formulario; el resto lo ve de solo
  // lectura (su departamento lo asigna un Admin/Director desde Roles).
  List<Department> _departamentos = [];
  String? _selectedDepartamentoId;

  final _passwordActual = TextEditingController();
  final _passwordNueva = TextEditingController();
  final _passwordConfirmar = TextEditingController();
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _msisdn.dispose();
    _direccion.dispose();
    _idIdentificacion.dispose();
    _fechaNacimientoCtrl.dispose();
    _passwordActual.dispose();
    _passwordNueva.dispose();
    _passwordConfirmar.dispose();
    super.dispose();
  }

  Future<_ProfileData> _load() async {
    final session = context.read<AuthSession>();
    final user = await UserService(session.api).get(session.user?.idUser ?? '');

    _nombre.text = user.nombre;
    _apellido.text = user.apellido;
    _msisdn.text = user.msisdn ?? '';
    _direccion.text = user.direccion ?? '';
    // Un usuario recién invitado queda en BD con id_identificacion =
    // "TEMP-<correo>" (placeholder único requerido por la columna
    // unique+not-null — ver register_controller.invite_users). Nunca se
    // debe mostrar ese placeholder: el campo se ve vacío hasta que la
    // persona ingresa su documento real, sin importar su rol.
    final idIdentificacionReal = (user.idIdentificacion != null && !user.idIdentificacion!.startsWith('TEMP-'))
        ? user.idIdentificacion!
        : '';
    _idIdentificacion.text = idIdentificacionReal;
    if (user.identificacion != null && kTiposDocumento.contains(user.identificacion)) {
      _tipoIdentificacion = user.identificacion!;
    }
    _fechaNacimiento = user.fechaDeNacimiento;
    _fechaNacimientoCtrl.text = _fechaNacimiento != null ? _fmtDate(_fechaNacimiento!) : '';

    String? departamentoNombre;
    try {
      _departamentos = await DepartmentService(session.api).all();
      if (user.idDepartamento != null && user.idDepartamento!.isNotEmpty) {
        final match = _departamentos.where((d) => d.idDepartamento == user.idDepartamento);
        departamentoNombre = match.isNotEmpty ? match.first.nombre : user.idDepartamento;
      }
    } catch (_) {
      departamentoNombre = user.idDepartamento;
    }
    _selectedDepartamentoId = user.idDepartamento;

    _reloadAvatar(user.idUser);

    return _ProfileData(user: user, departamentoNombre: departamentoNombre);
  }

  void _reloadAvatar(String idUser) {
    final session = context.read<AuthSession>();
    // Con llaves — mismo motivo que en crew_list_screen.dart (evita
    // 'setState() callback argument returned a Future').
    setState(() {
      _avatarBytes = UserService(session.api).photoBytes(idUser);
    });
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // Para "deslizar hacia abajo para recargar" (ver MobileRefresh) — NO
  // se usa mientras se está editando el formulario, así que recargar
  // acá (que sí pisa los controllers con lo que venga del servidor) es
  // seguro: es justo lo que la persona pide al deslizar.
  Future<void> _onPullRefresh() async {
    final nuevo = _load();
    setState(() => _future = nuevo);
    try {
      await nuevo;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mi Perfil',
      showBack: true,
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) {
            return ErrorView(
              message: 'No se pudo cargar tu perfil.',
              // Con llaves para que el callback de setState devuelva void y
              // no el Future de _load() (ver crew_list_screen.dart).
              onRetry: () => setState(() {
                _future = _load();
              }),
            );
          }
          final data = snap.data!;
          final user = data.user;
          final session = context.watch<AuthSession>();
          // Rol EFECTIVO en el proyecto activo (user_projects.id_rol), no
          // el rol global de la cuenta (users.id_rol/user.idRol) — ver
          // comentario junto al StatusPill más abajo.
          final effectiveRol = session.hasProject ? session.projectRole : user.idRol;
          // Bloqueado solo para el Administrador (1001): un admin no
          // pertenece a un departamento operativo propio. El resto de
          // roles (Director, Jefe de Departamento, Onset, Usuario) sí
          // puede editar su propio departamento desde Mi Perfil.
          final canEditDepartamentoAqui = effectiveRol != 1001;

          return MobileRefresh(
            onRefresh: _onPullRefresh,
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            // Align + topCenter en vez de solo ConstrainedBox: un
            // ConstrainedBox solo no se centra a sí mismo dentro del
            // ancho disponible, así que en pantallas anchas (Web/
            // Desktop) el formulario quedaba pegado al borde izquierdo
            // en vez de centrado como el resto de pantallas tipo tarjeta.
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _avatarSection(user),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        Text(user.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 4),
                        // El badge debe reflejar el rol EFECTIVO en el
                        // proyecto activo (user_projects.id_rol), no el
                        // rol global de la cuenta (users.id_rol): una
                        // misma persona puede ser Administrador de su
                        // propio proyecto y, a la vez, Usuario en un
                        // proyecto ajeno al que fue invitada — mostrar
                        // siempre el rol global aquí confundía a
                        // cualquiera que viera "Administrador" mientras
                        // sus permisos reales eran los de Usuario.
                        StatusPill(label: Roles.label(effectiveRol), color: AppColors.moradoTech),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Datos Personales'),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: AppTextField(label: 'Nombres', controller: _nombre)),
                      const SizedBox(width: 16),
                      Expanded(child: AppTextField(label: 'Apellidos', controller: _apellido)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Email',
                          controller: TextEditingController(text: user.mail),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: AppTextField(label: 'Celular', controller: _msisdn, keyboardType: TextInputType.phone)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppDropdown<String>(
                          label: 'Tipo de Identificación',
                          value: _tipoIdentificacion,
                          items: kTiposDocumento,
                          labelBuilder: tipoDocumentoLabel,
                          onChanged: (v) => setState(() => _tipoIdentificacion = v ?? _tipoIdentificacion),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: AppTextField(label: 'Número de Documento', controller: _idIdentificacion)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: AppTextField(label: 'Dirección de Residencia', controller: _direccion)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          label: 'Fecha de Nacimiento',
                          controller: _fechaNacimientoCtrl,
                          readOnly: true,
                          onTap: _pickFechaNacimiento,
                          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Fecha de Creación del Perfil',
                          controller: TextEditingController(
                            text: user.fechaDeCreacion != null ? _fmtDate(user.fechaDeCreacion!) : '—',
                          ),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: canEditDepartamentoAqui
                            ? AppDropdown<String>(
                                label: 'Nombre del Departamento',
                                value: _departamentos.any((d) => d.idDepartamento == _selectedDepartamentoId)
                                    ? _selectedDepartamentoId
                                    : null,
                                hint: 'Selecciona un departamento',
                                items: _departamentos.map((d) => d.idDepartamento).toList(),
                                labelBuilder: (id) => _departamentos.firstWhere((d) => d.idDepartamento == id).nombre,
                                onChanged: (v) => setState(() => _selectedDepartamentoId = v),
                              )
                            : AppTextField(
                                label: 'Nombre del Departamento',
                                controller: TextEditingController(text: data.departamentoNombre ?? 'Sin asignar'),
                                enabled: false,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Nombre del Proyecto',
                    controller: TextEditingController(text: context.read<AuthSession>().projectName ?? 'Sin proyecto'),
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _savingInfo ? null : _saveInfo,
                    child: _savingInfo
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar cambios'),
                  ),
                  const SizedBox(height: 36),
                  const Divider(),
                  const SizedBox(height: 20),
                  _sectionTitle('Cambiar Contraseña'),
                  const SizedBox(height: 8),
                  const Text(
                    'Para cambiar tu contraseña primero debes confirmar la actual.',
                    style: TextStyle(color: AppColors.grisMedio, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Contraseña Actual', controller: _passwordActual, obscureText: true),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: AppTextField(label: 'Contraseña Nueva', controller: _passwordNueva, obscureText: true)),
                      const SizedBox(width: 16),
                      Expanded(child: AppTextField(label: 'Confirmar Contraseña', controller: _passwordConfirmar, obscureText: true)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _savingPassword ? null : _savePassword,
                    child: _savingPassword
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Actualizar Contraseña'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16));

  Widget _avatarSection(AppUser user) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.azulProfundo,
            child: ClipOval(
              child: SizedBox(
                width: 88,
                height: 88,
                child: FutureBuilder<List<int>>(
                  future: _avatarBytes,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)));
                    }
                    if (snap.hasError || snap.data == null) {
                      return Center(
                        child: Text(
                          user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      );
                    }
                    return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: 88, height: 88);
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: AppColors.moradoTech,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: _uploadingAvatar
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    // file_picker 13.x: pickFile() (singular) devuelve el
    // PlatformFile directo; los bytes se leen aparte, async, con
    // readAsBytes().
    final picked = await FilePicker.pickFile(type: FileType.image);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();

    setState(() => _uploadingAvatar = true);
    final session = context.read<AuthSession>();

    try {
      await UserService(session.api).uploadOwnPhoto(
        bytes: bytes,
        filename: picked.name,
        contentType: _contentTypeFor(picked.name),
      );
      _reloadAvatar(session.user?.idUser ?? '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickFechaNacimiento() async {
    final initial = _fechaNacimiento ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
        _fechaNacimientoCtrl.text = _fmtDate(picked);
      });
    }
  }

  Future<void> _saveInfo() async {
    setState(() => _savingInfo = true);
    final session = context.read<AuthSession>();
    // Mismo criterio que en el build: rol EFECTIVO en el proyecto activo,
    // no el rol global de la cuenta.
    final effectiveRol = session.hasProject ? session.projectRole : session.user?.idRol;
    final canEditDepartamento = effectiveRol != 1001;

    try {
      await UserService(session.api).updateOwnProfile({
        'nombre': _nombre.text.trim(),
        'apellido': _apellido.text.trim(),
        'identificacion': _tipoIdentificacion,
        'id_identificacion': _idIdentificacion.text.trim(),
        'msisdn': _msisdn.text.trim(),
        'direccion': _direccion.text.trim(),
        if (_fechaNacimiento != null) 'fecha_de_nacimiento': _fechaNacimiento!.toIso8601String(),
        if (canEditDepartamento && _selectedDepartamentoId != null) 'id_departamento': _selectedDepartamentoId,
      });
      await session.updateUserNames(_nombre.text.trim(), _apellido.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }

  Future<void> _savePassword() async {
    final actual = _passwordActual.text;
    final nueva = _passwordNueva.text;
    final confirmar = _passwordConfirmar.text;

    if (actual.isEmpty || nueva.isEmpty || confirmar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa los 3 campos de contraseña')));
      return;
    }
    if (nueva != confirmar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La nueva contraseña y su confirmación no coinciden')));
      return;
    }
    if (nueva.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La nueva contraseña debe tener al menos 8 caracteres')));
      return;
    }

    setState(() => _savingPassword = true);
    final session = context.read<AuthSession>();

    try {
      await UserService(session.api).changePassword(contrasenaActual: actual, nuevaContrasena: nueva);
      _passwordActual.clear();
      _passwordNueva.clear();
      _passwordConfirmar.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada correctamente')));
      }
    } on ApiException catch (e) {
      // Ej. "INVALID_PASSWORD" si la contraseña actual no coincide.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }
}

class _ProfileData {
  final AppUser user;
  final String? departamentoNombre;
  _ProfileData({required this.user, this.departamentoNombre});
}
