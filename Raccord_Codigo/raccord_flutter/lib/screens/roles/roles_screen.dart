import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/invite_helpers.dart';
import '../../core/permissions.dart';
import '../../core/session.dart';
import '../../models/catalog.dart';
import '../../models/user.dart';
import '../../services/department_service.dart';
import '../../services/role_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/bulk_upload_button.dart';
import '../../widgets/invite_person_dialog.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/module_access_dialog.dart';
import '../../widgets/state_views.dart';
import '../../core/bulk_import.dart';

/// Mockup 16: Roles del Equipo + Invitar persona (+ Carga masiva).
class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  late Future<List<AppUser>> _future;
  List<Department> _departamentos = [];
  List<RoleModel> _roles = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadCatalogos();
  }

  Future<List<AppUser>> _load() {
    final session = context.read<AuthSession>();
    return UserService(session.api).byProject(session.projectId ?? '');
  }

  Future<void> _loadCatalogos() async {
    final session = context.read<AuthSession>();
    try {
      final departamentos = await DepartmentService(session.api).all();
      final roles = await RoleService(session.api).all();
      if (mounted) {
        setState(() {
        _departamentos = departamentos;
        _roles = roles;
      });
      }
    } catch (_) {
      // si fallan los catálogos, el diálogo de invitar/carga masiva
      // simplemente queda sin opciones hasta que se reintente.
    }
  }

  // Con llaves para que el callback de setState devuelva void y no el
  // Future de _load() (ver crew_list_screen.dart para el detalle del bug).
  void _reload() => setState(() {
        _future = _load();
      });

  // Para "deslizar hacia abajo para recargar" (ver MobileRefresh).
  Future<void> _onPullRefresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  bool _esPendiente(AppUser u) => (u.estado ?? '').toLowerCase() == 'pendiente';
  bool _esSuspendido(AppUser u) => (u.estado ?? '').toLowerCase() == 'suspendido';

  /// Decide si la sesión actual puede suspender/reactivar a [target]:
  /// Administrador y Director sobre todo el proyecto; Jefe de
  /// Departamento SOLO sobre gente de su propio departamento; nadie
  /// puede tocarse a sí mismo; y nadie sin `delete_admin_users` puede
  /// tocar a un Administrador. Esto es solo para decidir qué mostrar —
  /// el backend vuelve a validar todo esto igual.
  bool _puedeGestionarEstado(AuthSession session, AppUser target) {
    if (!session.can('manage_team_status')) return false;
    final me = session.user;
    if (me == null || target.idUser == me.idUser) return false;
    if (target.idRol == Roles.administrador && !session.can('delete_admin_users')) return false;
    if (me.idRol == Roles.jefeDepartamento) {
      return me.idDepartamento != null && me.idDepartamento == target.idDepartamento;
    }
    return true;
  }

  /// Solo Administrador/Director del proyecto ("full_management") puede
  /// abrir el diálogo de personalizar accesos — mismo gate que exige el
  /// backend en PUT/DELETE .../module-access (ver
  /// app/routes/module_access_routes.py).
  bool get _puedePersonalizarAccesos => context.read<AuthSession>().can('full_management');

  Future<void> _openModuleAccessDialog(AppUser user) async {
    final session = context.read<AuthSession>();
    await showDialog<void>(
      context: context,
      builder: (_) => ModuleAccessDialog(
        projectId: session.projectId ?? '',
        idUser: user.idUser,
        nombreCompleto: user.nombreCompleto,
      ),
    );
  }

  Future<void> _toggleEstado(AppUser user) async {
    final suspender = !_esSuspendido(user);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(suspender ? '¿Suspender a ${user.nombreCompleto}?' : '¿Reactivar a ${user.nombreCompleto}?'),
        content: Text(
          suspender
              ? 'No podrá volver a iniciar sesión en este proyecto hasta que lo reactives. '
                  'Toda la información que ya haya subido (escenas, fotos, desglose, etc.) se conserva intacta.'
              : 'Podrá volver a iniciar sesión en este proyecto normalmente.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              suspender ? 'Suspender' : 'Reactivar',
              style: TextStyle(color: suspender ? AppColors.error : AppColors.success),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final session = context.read<AuthSession>();
    try {
      await UserService(session.api).setEstado(user.idUser, suspender ? 'suspendido' : 'activo');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(suspender ? 'Usuario suspendido' : 'Usuario reactivado')),
        );
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canInvite = session.can('invite_users');

    return AppScaffold(
      title: 'Roles del Equipo',
      showBack: true,
      actions: [
        if (canInvite)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BulkUploadButton(
              onRows: _bulkInvite,
              onDone: _reload,
            ),
          ),
      ],
      // "Invitar persona" bajó de la barra superior a un botón flotante
      // (mismo patrón que "Nuevo día" en Plan de Rodaje) — pedido
      // explícito del usuario: el logo nunca debe achicarse, así que la
      // acción principal de esta pantalla se saca de arriba en vez de
      // competir por ese espacio con el wordmark.
      floatingActionButton: canInvite
          ? FloatingActionButton.extended(
              onPressed: () => _openInviteDialog(context),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Invitar persona'),
              backgroundColor: AppColors.moradoTech,
              foregroundColor: Colors.white,
            )
          : null,
      body: FutureBuilder<List<AppUser>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) {
            return ErrorView(message: 'No se pudo cargar el equipo del proyecto.', onRetry: _reload);
          }
          final users = snap.data ?? [];
          if (users.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [EmptyView(message: 'Aún no hay personas vinculadas a este proyecto.', icon: Icons.group_outlined)],
              ),
            );
          }

          final pendientes = users.where(_esPendiente).length;
          final suspendidos = users.where(_esSuspendido).length;
          final activos = users.length - pendientes - suspendidos;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Gestiona los departamentos y roles de cada integrante del proyecto.',
                        style: TextStyle(color: AppColors.grisMedio),
                      ),
                    ),
                    _CounterPill(icon: Icons.group_outlined, label: '$activos activos', color: AppColors.success),
                    const SizedBox(width: 8),
                    _CounterPill(icon: Icons.schedule_outlined, label: '$pendientes pendientes', color: AppColors.warning),
                    if (suspendidos > 0) ...[
                      const SizedBox(width: 8),
                      _CounterPill(icon: Icons.block_outlined, label: '$suspendidos suspendidos', color: AppColors.error),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: MobileRefresh(
                    onRefresh: _onPullRefresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // La tabla de 4 columnas (Expanded con flex) no se
                        // desborda en angosto gracias al `Expanded`, pero
                        // queda ilegible (columnas comprimidas a unos pocos
                        // px). Por debajo de 640px de ancho se reemplaza por
                        // una lista de tarjetas apiladas, una por persona.
                        final wide = constraints.maxWidth > 640;
                        if (wide) {
                          return Column(
                            children: [
                              _TableHeader(),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: users.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, i) => _UserRow(
                                      user: users[i],
                                      departamentoNombre: _departamentoNombre(users[i].idDepartamento),
                                      canManageEstado: _puedeGestionarEstado(session, users[i]),
                                      onToggleEstado: () => _toggleEstado(users[i]),
                                      canCustomizeAccess: _puedePersonalizarAccesos,
                                      onCustomizeAccess: () => _openModuleAccessDialog(users[i]),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _UserCard(
                            user: users[i],
                            departamentoNombre: _departamentoNombre(users[i].idDepartamento),
                            canManageEstado: _puedeGestionarEstado(session, users[i]),
                            onToggleEstado: () => _toggleEstado(users[i]),
                            canCustomizeAccess: _puedePersonalizarAccesos,
                            onCustomizeAccess: () => _openModuleAccessDialog(users[i]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _departamentoNombre(String? idDepartamento) {
    if (idDepartamento == null || idDepartamento.isEmpty) return null;
    for (final d in _departamentos) {
      if (d.idDepartamento == idDepartamento) return d.nombre;
    }
    return idDepartamento;
  }

  Future<void> _openInviteDialog(BuildContext context) async {
    final session = context.read<AuthSession>();
    final invited = await showDialog<bool>(
      context: context,
      builder: (_) => InvitePersonDialog(
        projectId: session.projectId ?? '',
        idClient: session.user?.idClient ?? '',
        departamentos: _departamentos,
        roles: _roles,
      ),
    );
    if (invited == true) _reload();
  }

  // Carga masiva: misma lógica compartida con Crew List (ver
  // core/invite_helpers.dart) — ambas pantallas invitan exactamente
  // igual, solo cambia desde dónde se dispara.
  Future<List<BulkRowResult>> _bulkInvite(List<Map<String, String>> rows) {
    final session = context.read<AuthSession>();
    return bulkInvitePeople(
      api: session.api,
      idProject: session.projectId ?? '',
      idClient: session.user?.idClient ?? '',
      departamentos: _departamentos,
      roles: _roles,
      rows: rows,
    );
  }
}

class _CounterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CounterPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.grisMedio, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4);
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('NOMBRE COMPLETO', style: style)),
          Expanded(flex: 2, child: Text('ÁREA / DEPARTAMENTO', style: style)),
          Expanded(flex: 2, child: Text('ROL', style: style)),
          Expanded(flex: 1, child: Text('ESTADO', style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  final String? departamentoNombre;
  final bool canManageEstado;
  final VoidCallback? onToggleEstado;
  final bool canCustomizeAccess;
  final VoidCallback? onCustomizeAccess;
  const _UserRow({
    required this.user,
    required this.departamentoNombre,
    this.canManageEstado = false,
    this.onToggleEstado,
    this.canCustomizeAccess = false,
    this.onCustomizeAccess,
  });

  @override
  Widget build(BuildContext context) {
    final estado = (user.estado ?? '').toLowerCase();
    final pendiente = estado == 'pendiente';
    final suspendido = estado == 'suspendido';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                      Text(user.mail, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(departamentoNombre ?? '—', overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(Roles.label(user.idRol), overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 1,
            child: StatusPill(
              label: suspendido ? 'Suspendido' : (pendiente ? 'Pendiente' : 'Activo'),
              color: suspendido ? AppColors.error : (pendiente ? AppColors.warning : AppColors.success),
            ),
          ),
          if (canCustomizeAccess)
            IconButton(
              icon: const Icon(Icons.tune, size: 20, color: AppColors.grisMedio),
              tooltip: 'Personalizar accesos',
              onPressed: onCustomizeAccess,
            ),
          if (canManageEstado)
            IconButton(
              icon: Icon(suspendido ? Icons.play_circle_outline : Icons.block_outlined, size: 20, color: suspendido ? AppColors.success : AppColors.error),
              tooltip: suspendido ? 'Reactivar' : 'Suspender',
              onPressed: onToggleEstado,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Versión en tarjeta de `_UserRow`, para pantallas angostas (móvil):
/// en vez de 4 columnas comprimidas, apila nombre+correo arriba y
/// departamento/rol/estado como una fila que envuelve (`Wrap`) debajo.
class _UserCard extends StatelessWidget {
  final AppUser user;
  final String? departamentoNombre;
  final bool canManageEstado;
  final VoidCallback? onToggleEstado;
  final bool canCustomizeAccess;
  final VoidCallback? onCustomizeAccess;
  const _UserCard({
    required this.user,
    required this.departamentoNombre,
    this.canManageEstado = false,
    this.onToggleEstado,
    this.canCustomizeAccess = false,
    this.onCustomizeAccess,
  });

  @override
  Widget build(BuildContext context) {
    final estado = (user.estado ?? '').toLowerCase();
    final pendiente = estado == 'pendiente';
    final suspendido = estado == 'suspendido';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                    Text(user.mail, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (canCustomizeAccess)
                IconButton(
                  icon: const Icon(Icons.tune, size: 20, color: AppColors.grisMedio),
                  tooltip: 'Personalizar accesos',
                  onPressed: onCustomizeAccess,
                ),
              if (canManageEstado)
                IconButton(
                  icon: Icon(suspendido ? Icons.play_circle_outline : Icons.block_outlined, size: 20, color: suspendido ? AppColors.success : AppColors.error),
                  tooltip: suspendido ? 'Reactivar' : 'Suspender',
                  onPressed: onToggleEstado,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.apartment_outlined, label: departamentoNombre ?? '—'),
              _InfoChip(icon: Icons.badge_outlined, label: Roles.label(user.idRol)),
              StatusPill(
                label: suspendido ? 'Suspendido' : (pendiente ? 'Pendiente' : 'Activo'),
                color: suspendido ? AppColors.error : (pendiente ? AppColors.warning : AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grisMedio),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

