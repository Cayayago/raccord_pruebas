import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../models/catalog.dart';
import '../../models/notification.dart';
import '../../services/department_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/state_views.dart';

/// Tablón de Notificaciones (2026-09-27, pedido explícito del usuario):
/// informativo de cara a todo el equipo del proyecto. Solo Jefe de
/// Departamento y Director pueden publicar ("publish_notifications"),
/// eligiendo si es "General" (todo el proyecto) o "Específica" (uno o
/// más departamentos puntuales — ambos roles pueden elegir varios a la
/// vez, un Jefe puede tener a cargo más de un equipo).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppNotification>> _load() {
    final session = context.read<AuthSession>();
    return NotificationService(session.api).all(session.projectId ?? '');
  }

  // Con llave para que el callback de setState devuelva void, no el
  // Future de _load() (ver crew_list_screen.dart para el detalle del bug).
  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _onPullRefresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _marcarLeida(AppNotification n) async {
    if (n.leida) return;
    final session = context.read<AuthSession>();
    try {
      await NotificationService(session.api).marcarLeida(n.idNotificacion);
      _reload();
    } catch (_) {
      // Silencioso: no marcar como leída no es crítico para la lectura misma.
    }
  }

  Future<void> _abrirPublicar() async {
    final session = context.read<AuthSession>();
    final creada = await showDialog<bool>(
      context: context,
      builder: (_) => _PublishNotificationDialog(session: session),
    );
    if (creada == true) _reload();
  }

  String _fechaLabel(DateTime? fecha) {
    if (fecha == null) return '';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canPublish = session.can('publish_notifications');

    return AppScaffold(
      title: 'Notificaciones',
      showBack: true,
      actions: canPublish
          ? [
              AppBarActionButton(
                icon: Icons.campaign_outlined,
                label: 'Publicar',
                onPressed: _abrirPublicar,
              ),
            ]
          : null,
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) {
            final message = snap.error is ApiException ? (snap.error as ApiException).message : 'No se pudieron cargar las notificaciones.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final notificaciones = snap.data ?? [];
          if (notificaciones.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyView(
                    message: 'Todavía no hay notificaciones para el equipo.',
                    icon: Icons.notifications_none,
                  ),
                ],
              ),
            );
          }

          return MobileRefresh(
            onRefresh: _onPullRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notificaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = notificaciones[i];
                return _NotificationCard(
                  notification: n,
                  onTap: () => _marcarLeida(n),
                  fechaLabel: _fechaLabel(n.fechaCreacion),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final String fechaLabel;

  const _NotificationCard({required this.notification, required this.onTap, required this.fechaLabel});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final esGeneral = n.tipoAlcance == kAlcanceGeneral;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: n.leida ? AppColors.border : AppColors.azulProfundo, width: n.leida ? 1 : 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!n.leida)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(color: AppColors.azulProfundo, shape: BoxShape.circle),
                  ),
                Expanded(
                  child: Text(
                    esGeneral ? 'General' : 'Específica · ${n.departamentos.map((d) => d.nombre).join(', ')}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: esGeneral ? AppColors.azulProfundo : AppColors.coral,
                    ),
                  ),
                ),
                if (n.origen == kOrigenPlanRodaje)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.event_note_outlined, size: 14, color: AppColors.grisMedio),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(n.texto, style: const TextStyle(fontSize: 14)),
            if (n.tieneFoto) ...[
              const SizedBox(height: 10),
              _NotificationPhoto(idNotificacion: n.idNotificacion),
            ],
            const SizedBox(height: 8),
            Text(
              '${n.autorNombre ?? 'Alguien'} · $fechaLabel',
              style: const TextStyle(color: AppColors.grisMedio, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPhoto extends StatelessWidget {
  final String idNotificacion;
  const _NotificationPhoto({required this.idNotificacion});

  @override
  Widget build(BuildContext context) {
    final session = context.read<AuthSession>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: FutureBuilder<List<int>>(
        future: NotificationService(session.api).fotoBytes(idNotificacion),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 140,
              child: Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          if (snap.hasError || snap.data == null) {
            return const SizedBox(
              height: 140,
              child: Center(child: Icon(Icons.broken_image_outlined, color: AppColors.grisMedio)),
            );
          }
          return Image.memory(
            Uint8List.fromList(snap.data!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 180,
          );
        },
      ),
    );
  }
}

/// Diálogo para publicar una notificación — solo Jefe de Departamento y
/// Director llegan acá (ver `canPublish` en la pantalla). Alcance
/// General o Específica; en Específica se pueden elegir VARIOS
/// departamentos (pedido explícito del usuario 2026-09-27).
class _PublishNotificationDialog extends StatefulWidget {
  final AuthSession session;
  const _PublishNotificationDialog({required this.session});

  @override
  State<_PublishNotificationDialog> createState() => _PublishNotificationDialogState();
}

class _PublishNotificationDialogState extends State<_PublishNotificationDialog> {
  final _texto = TextEditingController();
  String _alcance = kAlcanceGeneral;
  final Set<String> _departamentosElegidos = {};
  late Future<List<Department>> _departamentosFuture;

  PlatformFile? _foto;
  bool _publicando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _departamentosFuture = DepartmentService(widget.session.api).all();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final picked = await FilePicker.pickFiles(type: FileType.image);
    if (picked.isEmpty) return;
    setState(() => _foto = picked.first);
  }

  Future<void> _publicar() async {
    if (_texto.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el texto de la notificación.');
      return;
    }
    if (_alcance == kAlcanceEspecifica && _departamentosElegidos.isEmpty) {
      setState(() => _error = 'Elige al menos un departamento.');
      return;
    }

    setState(() {
      _publicando = true;
      _error = null;
    });

    try {
      final fotoBytes = _foto != null ? await _foto!.readAsBytes() : null;
      await NotificationService(widget.session.api).crear(
        widget.session.projectId ?? '',
        tipoAlcance: _alcance,
        idsDepartamentos: _departamentosElegidos.toList(),
        texto: _texto.text.trim(),
        fotoBytes: fotoBytes,
        fotoNombre: _foto?.name,
        fotoTipo: _foto != null ? 'image/${_foto!.extension ?? 'jpeg'}' : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _publicando = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No se pudo publicar la notificación.';
        _publicando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Publicar notificación', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 16),
                const Text('Alcance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: kAlcanceGeneral, label: Text('General'), icon: Icon(Icons.public, size: 16)),
                    ButtonSegment(value: kAlcanceEspecifica, label: Text('Específica'), icon: Icon(Icons.groups_outlined, size: 16)),
                  ],
                  selected: {_alcance},
                  onSelectionChanged: (s) => setState(() => _alcance = s.first),
                ),
                if (_alcance == kAlcanceEspecifica) ...[
                  const SizedBox(height: 14),
                  const Text('Departamentos (puedes elegir varios)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  FutureBuilder<List<Department>>(
                    future: _departamentosFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final departamentos = snap.data ?? [];
                      if (departamentos.isEmpty) {
                        return const Text('No hay departamentos creados todavía.', style: TextStyle(color: AppColors.grisMedio, fontSize: 12));
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: departamentos.map((d) {
                          final elegido = _departamentosElegidos.contains(d.idDepartamento);
                          return FilterChip(
                            label: Text(d.nombre),
                            selected: elegido,
                            onSelected: (v) => setState(() {
                              if (v) {
                                _departamentosElegidos.add(d.idDepartamento);
                              } else {
                                _departamentosElegidos.remove(d.idDepartamento);
                              }
                            }),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),
                const Text('Mensaje', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _texto,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Escribe el aviso para el equipo...'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _elegirFoto,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(_foto == null ? 'Adjuntar foto (opcional)' : _foto!.name),
                    ),
                    if (_foto != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Quitar foto',
                        onPressed: () => setState(() => _foto = null),
                      ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _publicando ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.azulProfundo),
                      onPressed: _publicando ? null : _publicar,
                      child: _publicando
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Publicar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
