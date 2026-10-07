import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../models/gallery_photo.dart';
import '../../models/scene.dart';
import '../../services/gallery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/photo_viewer_dialog.dart';
import '../../widgets/state_views.dart';

/// Fotos de continuidad de una escena, sin carga (eso vive en
/// SceneEditScreen) — es lo que abre el ícono de ojo en la lista de
/// Escenas. El visor de cada foto sí permite editar/eliminar según
/// permisos (mismo criterio que en Galería y Continuidad Visual).
class SceneGalleryScreen extends StatefulWidget {
  final Scene scene;
  const SceneGalleryScreen({super.key, required this.scene});

  @override
  State<SceneGalleryScreen> createState() => _SceneGalleryScreenState();
}

class _SceneGalleryScreenState extends State<SceneGalleryScreen> {
  Future<List<GalleryPhoto>>? _photos;

  @override
  void initState() {
    super.initState();
    final idEscena = widget.scene.idEscena;
    if (idEscena != null) {
      final session = context.read<AuthSession>();
      _photos = GalleryService(session.api).byScene(idEscena);
    }
  }

  void _reload() {
    final idEscena = widget.scene.idEscena;
    if (idEscena == null) return;
    final session = context.read<AuthSession>();
    // Con llaves para que el callback de setState devuelva void y no el
    // Future de byScene() (ver mismo fix en scene_edit_screen.dart).
    setState(() {
      _photos = GalleryService(session.api).byScene(idEscena);
    });
  }

  // Para "deslizar hacia abajo para recargar" (ver MobileRefresh).
  Future<void> _onPullRefresh() async {
    _reload();
    try {
      await _photos;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canEdit = session.can('upload_photos');
    final canDelete = session.can('delete_photos');

    return AppScaffold(
      title: '${widget.scene.encabezado} · Fotos',
      showBack: true,
      body: FutureBuilder<List<GalleryPhoto>>(
        future: _photos,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: 'No se pudieron cargar las fotos.', onRetry: _reload);
          final photos = snap.data ?? [];
          if (photos.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyView(
                    message: 'Esta escena todavía no tiene fotos de continuidad.',
                    icon: Icons.photo_library_outlined,
                  ),
                ],
              ),
            );
          }
          return MobileRefresh(
            onRefresh: _onPullRefresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: photos.length,
              // `MaxCrossAxisExtent` calcula columnas según el ancho real en
              // vez de un `crossAxisCount` fijo — menos columnas en móvil,
              // más en tablet/desktop.
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, i) => _GalleryTile(
                photo: photos[i],
                allPhotos: photos,
                index: i,
                canEdit: canEdit,
                canDelete: canDelete,
                onDeleted: _reload,
                onUpdated: _reload,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final GalleryPhoto photo;
  final List<GalleryPhoto> allPhotos;
  final int index;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;

  const _GalleryTile({
    required this.photo,
    required this.allPhotos,
    required this.index,
    required this.canEdit,
    required this.canDelete,
    required this.onDeleted,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: AppColors.surfaceVariant,
          child: FutureBuilder<List<int>>(
            future: GalleryService(context.read<AuthSession>().api).archivoBytes(photo.idFoto),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)));
              }
              if (snap.hasError || snap.data == null) {
                return const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.grisMedio));
              }
              return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
            },
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    showPhotoViewerDialog(
      context,
      photo: photo,
      photos: allPhotos,
      initialIndex: index,
      canEdit: canEdit,
      canDelete: canDelete,
      onDeleted: onDeleted,
      onUpdated: onUpdated,
    );
  }
}
