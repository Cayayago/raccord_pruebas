import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/bulk_import.dart';
import '../../core/invite_helpers.dart';
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
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';

/// Crew List: directorio de TODAS las personas que YA TIENEN CUENTA en
/// la plataforma para este proyecto — pedido explícito del usuario
/// (2026-09-01): "los datos se tomarán de los registros o personas que
/// ya están registradas en la plataforma", con Nombre, Apellidos,
/// Departamento, Celular, Mail y si está activa o no.
///
/// Antes esta pantalla mostraba un directorio de texto libre aparte
/// (`CrewMember`, personal sin cuenta de acceso) — se reemplazó por
/// completo por la lista real de usuarios del proyecto
/// (`GET /users/project/{id}`, el mismo endpoint que ya usa "Roles del
/// Equipo"), reusando también su mismo mecanismo de invitar/cargar
/// masivo (`InvitePersonDialog` + `bulkInvitePeople`) en vez de
/// duplicarlo. Se diferencia de "Roles del Equipo" en que aquí el
/// foco es el directorio de contacto (nombre, apellidos, celular,
/// correo), no la gestión de roles/suspensión — eso sigue viviendo
/// solo en Roles del Equipo.
///
/// Quién puede agregar/cargar masivo: Administrador (1001), Director
/// (1002) y Jefe de Departamento (1003) — el permiso `invite_users` ya
/// es exactamente ese conjunto de roles, así que se reusa tal cual.
class CrewListScreen extends StatefulWidget {
  const CrewListScreen({super.key});

  @override
  State<CrewListScreen> createState() => _CrewListScreenState();
}

class _CrewListScreenState extends State<CrewListScreen> {
  late Future<List<AppUser>> _future;
  List<Department> _departamentos = [];
  List<RoleModel> _roles = [];
  // Búsqueda por nombre de la persona + filtro por departamento (dos
  // controles separados, no un único cuadro combinado) y paginación —
  // pedido explícito del usuario (2026-09-02), mismo widget que Escenas
  // y Personajes (ver PaginationBar).
  String _query = '';
  String? _idDepartamentoFiltro;
  int _page = 0;
  int _pageSize = 10;

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
      // si fallan los catálogos, el diálogo de agregar/carga masiva
      // simplemente queda sin opciones hasta que se reintente.
    }
  }

  // OJO: setState(() => _future = _load()) parece inofensivo pero NO lo
  // es — como es un body de una sola expresión, Dart hace que el
  // callback "devuelva" el Future de _load() en vez de void. Flutter
  // detecta eso y lanza 'setState() callback argument returned a
  // Future' ANTES de llegar a marcar el widget para reconstruir, así
  // que la pantalla nunca se actualizaba: por eso "Reintentar" se
  // quedaba pegado en el mismo error sin importar cuántas veces se
  // tocara. Con llaves ({ ... }) el callback es un bloque que no
  // devuelve nada, evitando el problema.
  void _reload() => setState(() {
        _future = _load();
      });

  // Para el gesto de "deslizar hacia abajo para recargar" (ver
  // MobileRefresh): dispara la recarga y espera a que termine, para que
  // el ícono de refresco no desaparezca antes de tiempo. Si la recarga
  // falla, el propio FutureBuilder ya se encarga de mostrar el
  // ErrorView correspondiente — acá solo evitamos que el error se
  // propague sin manejar.
  Future<void> _onPullRefresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  String? _departamentoNombre(String? idDepartamento) {
    if (idDepartamento == null || idDepartamento.isEmpty) return null;
    for (final d in _departamentos) {
      if (d.idDepartamento == idDepartamento) return d.nombre;
    }
    return idDepartamento;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canManage = session.can('invite_users');

    return AppScaffold(
      title: 'Crew List',
      showBack: true,
      actions: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BulkUploadButton(onRows: _bulkInvite, onDone: _reload),
          ),
      ],
      // "Agregar Persona" bajó de la barra superior a un botón flotante
      // (mismo patrón que "Nuevo día" en Plan de Rodaje y "Invitar
      // persona" en Roles del Equipo) — el logo nunca debe achicarse, así
      // que la acción principal se saca de arriba.
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openInviteDialog(context),
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Agregar Persona'),
              backgroundColor: AppColors.moradoTech,
              foregroundColor: Colors.white,
            )
          : null,
      body: FutureBuilder<List<AppUser>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) {
            // Antes se mostraba siempre el mismo mensaje genérico, sin
            // importar la causa real (403 por acceso restringido al
            // módulo, error de red, etc.) — eso hacía imposible
            // diagnosticar el problema solo con lo que se ve en
            // pantalla. Ahora, si es un error del backend (ApiException),
            // se muestra su mensaje real tal cual lo manda el servidor.
            final message = snap.error is ApiException ? (snap.error as ApiException).message : 'No se pudo cargar el crew list.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final all = snap.data ?? [];
          var filtered = _query.isEmpty
              ? all
              : all.where((u) => '${u.nombre} ${u.apellido}'.toLowerCase().contains(_query.toLowerCase())).toList();
          if (_idDepartamentoFiltro != null) {
            filtered = filtered.where((u) => u.idDepartamento == _idDepartamentoFiltro).toList();
          }
          final totalPages = filtered.isEmpty ? 1 : ((filtered.length - 1) ~/ _pageSize) + 1;
          final page = _page.clamp(0, totalPages - 1);
          final start = page * _pageSize;
          final pageItems = filtered.skip(start).take(_pageSize).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar por nombre de la persona...',
                        ),
                        onChanged: (v) => setState(() {
                          _query = v;
                          _page = 0;
                        }),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Departamento: ', style: TextStyle(color: AppColors.grisMedio)),
                        DropdownButton<String?>(
                          value: _idDepartamentoFiltro,
                          underline: const SizedBox.shrink(),
                          dropdownColor: AppColors.surfaceVariant,
                          hint: const Text('Todos'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                            ..._departamentos.map((d) => DropdownMenuItem<String?>(value: d.idDepartamento, child: Text(d.nombre))),
                          ],
                          onChanged: (v) => setState(() {
                            _idDepartamentoFiltro = v;
                            _page = 0;
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyView(
                          message: all.isEmpty ? 'Todavía no hay personas registradas en la plataforma.' : 'Sin resultados.',
                          icon: all.isEmpty ? Icons.badge_outlined : Icons.search_off,
                        )
                      : MobileRefresh(
                          onRefresh: _onPullRefresh,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Misma regla que Roles del Equipo: por debajo
                              // de 640px la tabla de 6 columnas queda
                              // ilegible, se reemplaza por tarjetas apiladas.
                              final wide = constraints.maxWidth > 640;
                              if (wide) {
                                return Column(
                                  children: [
                                    const _CrewTableHeader(),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: ListView.separated(
                                          // AlwaysScrollableScrollPhysics: sin esto,
                                          // el gesto de "jalar para refrescar" no se
                                          // activa cuando la página actual tiene pocos
                                          // resultados y el contenido no llena la
                                          // pantalla.
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          itemCount: pageItems.length,
                                          separatorBuilder: (_, __) => const Divider(height: 1),
                                          itemBuilder: (context, i) => _CrewUserRow(
                                            user: pageItems[i],
                                            departamentoNombre: _departamentoNombre(pageItems[i].idDepartamento),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: pageItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) => _CrewUserCard(
                                  user: pageItems[i],
                                  departamentoNombre: _departamentoNombre(pageItems[i].idDepartamento),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PaginationBar(
                    page: page,
                    totalPages: totalPages,
                    totalItems: filtered.length,
                    pageSize: _pageSize,
                    itemLabel: 'persona(s)',
                    onPageChanged: (p) => setState(() => _page = p),
                    onPageSizeChanged: (size) => setState(() {
                      _pageSize = size;
                      _page = 0;
                    }),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
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

  // Carga masiva: misma lógica compartida con Roles del Equipo (ver
  // core/invite_helpers.dart) — agregar a alguien acá SIEMPRE crea una
  // cuenta real con rol, exactamente igual que "Invitar persona" en
  // Roles del Equipo.
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

class _CrewTableHeader extends StatelessWidget {
  const _CrewTableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.grisMedio, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4);
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('NOMBRE', style: style)),
          Expanded(flex: 2, child: Text('APELLIDOS', style: style)),
          Expanded(flex: 2, child: Text('DEPARTAMENTO', style: style)),
          Expanded(flex: 2, child: Text('CELULAR', style: style)),
          Expanded(flex: 3, child: Text('MAIL', style: style)),
          Expanded(flex: 1, child: Text('ACTIVO', style: style)),
        ],
      ),
    );
  }
}

class _CrewUserRow extends StatelessWidget {
  final AppUser user;
  final String? departamentoNombre;
  const _CrewUserRow({required this.user, required this.departamentoNombre});

  @override
  Widget build(BuildContext context) {
    final estado = (user.estado ?? '').toLowerCase();
    final pendiente = estado == 'pendiente';
    final suspendido = estado == 'suspendido';
    final activo = !pendiente && !suspendido;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(user.nombre, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(user.apellido, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(departamentoNombre ?? '—', overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text((user.msisdn != null && user.msisdn!.isNotEmpty) ? user.msisdn! : '—', overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(user.mail, style: const TextStyle(color: AppColors.grisMedio), overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 1,
            child: StatusPill(
              label: activo ? 'Activo' : (pendiente ? 'Pendiente' : 'Inactivo'),
              color: activo ? AppColors.success : (pendiente ? AppColors.warning : AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Versión en tarjeta de `_CrewUserRow` para pantallas angostas
/// (móvil): nombre+apellidos+correo apilados arriba, departamento/
/// celular/estado como chips que envuelven (`Wrap`) debajo.
class _CrewUserCard extends StatelessWidget {
  final AppUser user;
  final String? departamentoNombre;
  const _CrewUserCard({required this.user, required this.departamentoNombre});

  @override
  Widget build(BuildContext context) {
    final estado = (user.estado ?? '').toLowerCase();
    final pendiente = estado == 'pendiente';
    final suspendido = estado == 'suspendido';
    final activo = !pendiente && !suspendido;

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
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.apartment_outlined, label: departamentoNombre ?? '—'),
              _InfoChip(icon: Icons.phone_outlined, label: (user.msisdn != null && user.msisdn!.isNotEmpty) ? user.msisdn! : '—'),
              StatusPill(
                label: activo ? 'Activo' : (pendiente ? 'Pendiente' : 'Inactivo'),
                color: activo ? AppColors.success : (pendiente ? AppColors.warning : AppColors.error),
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
