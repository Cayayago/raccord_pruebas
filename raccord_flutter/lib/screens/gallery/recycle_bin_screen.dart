import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../models/gallery_photo.dart';
import '../../services/gallery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/state_views.dart';

/// Papelera de Reciclaje de fotos de continuidad (2026-09-23, pedido
/// explícito del usuario): Onset, Jefe de Departamento y Director
/// pueden mover una foto acá (ver GalleryService.delete /
/// "delete_photos"), pero SOLO Jefe de Departamento y Director pueden
/// restaurarla o eliminarla DEFINITIVAMENTE ("manage_recycle_bin").
///
/// El Administrador SÍ puede ver esta pantalla ("view_recycle_bin")
/// pero de solo lectura — no ve los botones de restaurar/eliminar
/// definitivo, igual que ya no ve el ícono de eliminar en la Galería
/// normal (ver app/utils/permissions.py del backend).
class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  late Future<List<GalleryPhoto>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<GalleryPhoto>> _load() {
    final session = context.read<AuthSession>();
    return GalleryService(session.api).papelera(session.projectId ?? '');
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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    // Solo Jefe de Departamento y Director pueden restaurar o eliminar
    // definitivo — el Administrador ve la papelera pero sin botones.
    final canManage = session.can('manage_recycle_bin');

    return AppScaffold(
      title: 'Papelera de Reciclaje',
      showBack: true,
      body: FutureBuilder<List<GalleryPhoto>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) {
            final message = snap.error is ApiException ? (snap.error as ApiException).message : 'No se pudo cargar la papelera de reciclaje.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final fotos = snap.data ?? [];
          if (fotos.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyView(
                    message: 'La papelera de reciclaje está vacía.',
                    icon: Icons.delete_outline,
                  ),
                ],
              ),
            );
          }

          return MobileRefresh(
            onRefresh: _onPullRefresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              itemCount: fotos.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, i) => _RecycleBinCard(
                photo: fotos[i],
                canManage: canManage,
                onChanged: _reload,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecycleBinCard extends StatefulWidget {
  final GalleryPhoto photo;
  final bool canManage;
  final VoidCallback onChanged;

  const _RecycleBinCard({
    required this.photo,
    required this.canManage,
    required this.onChanged,
  });

  @override
  State<_RecycleBinCard> createState() => _RecycleBinCardState();
}

class _RecycleBinCardState extends State<_RecycleBinCard> {
  bool _busy = false;

  String _fechaLabel(DateTime? fecha) {
    if (fecha == null) return '';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  Future<void> _restaurar() async {
    setState(() => _busy = true);
    final session = context.read<AuthSession>();
    try {
      await GalleryService(session.api).restaurar(widget.photo.idFoto);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto restaurada a la galería')));
      }
      widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _eliminarDefinitivo() async {
    final confirmed = await confirmDelete(
      context,
      message: '¿Eliminar esta foto DEFINITIVAMENTE? Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;

    setState(() => _busy = true);
    final session = context.read<AuthSession>();
    try {
      await GalleryService(session.api).eliminarDefinitivo(widget.photo.idFoto);
      widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foto = widget.photo;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<List<int>>(
                  future: GalleryService(context.read<AuthSession>().api).archivoBytes(foto.idFoto),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    if (snap.hasError || snap.data == null) {
                      return const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.grisMedio));
                    }
                    return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover);
                  },
                ),
                if (_busy)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${foto.numeroDeEscenaOrigen != null ? 'ESC ${foto.numeroDeEscenaOrigen} · ' : ''}${foto.tipoFoto}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                if (foto.fechaEliminacion != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Eliminada el ${_fechaLabel(foto.fechaEliminacion)}',
                      style: const TextStyle(color: AppColors.grisMedio, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.canManage)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.restore_outlined, size: 20, color: AppColors.azulProfundo),
                    tooltip: 'Restaurar',
                    onPressed: _busy ? null : _restaurar,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_outlined, size: 20, color: AppColors.error),
                    tooltip: 'Eliminar definitivamente',
                    onPressed: _busy ? null : _eliminarDefinitivo,
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Text(
                'Solo Jefe de Departamento o Director pueden restaurar o eliminar',
                style: TextStyle(color: AppColors.grisMedio, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
