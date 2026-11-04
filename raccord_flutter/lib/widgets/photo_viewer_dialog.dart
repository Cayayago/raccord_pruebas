import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/session.dart';
import '../core/watermark.dart';
import '../models/character.dart';
import '../models/gallery_photo.dart';
import '../services/character_service.dart';
import '../services/gallery_service.dart';
import '../theme/app_theme.dart';
import 'app_text_field.dart';
import 'character_autocomplete_field.dart';
import 'state_views.dart';

/// Visor de una foto de continuidad con marco estilo Polaroid: la
/// imagen arriba, y la franja blanca de abajo con los detalles (tipo,
/// personaje, descripción, notas) — a pedido explícito del usuario
/// (2026-09-08), esos detalles ahora también se pueden EDITAR ahí
/// mismo, sin tener que volver a subir la foto.
///
/// Antes existían 3 copias casi idénticas de este visor, cada una de
/// solo lectura, en gallery_screen.dart, scene_gallery_screen.dart y
/// scene_edit_screen.dart. Este widget las reemplaza a las 3 (ver
/// PATCH /fotos/{id_foto} en gallery_photo_routes.py).
///
/// [canEdit] reutiliza el mismo permiso que subir fotos
/// ("upload_photos") — quien puede subir, puede editar los detalles
/// después. [canDelete] sigue siendo su propio permiso
/// ("delete_photos"), separado a pedido explícito anterior.
/// [onUpdated]/[onDeleted] son opcionales: el llamador los usa para
/// refrescar su propia lista/grid si la tiene cacheada.
///
/// [photos]/[initialIndex]: la lista completa que se está mostrando
/// (en el mismo orden visual que el llamador) y la posición de [photo]
/// dentro de ella — habilita las flechas anterior/siguiente para
/// navegar sin cerrar el visor. Si el llamador no tiene una lista a
/// mano, puede pasar `[photo]`/`0` y las flechas simplemente no salen.
Future<void> showPhotoViewerDialog(
  BuildContext context, {
  required GalleryPhoto photo,
  required List<GalleryPhoto> photos,
  required int initialIndex,
  required bool canEdit,
  required bool canDelete,
  VoidCallback? onDeleted,
  VoidCallback? onUpdated,
  String? etiquetaEscena,
}) {
  return showDialog(
    context: context,
    builder: (_) => _PhotoViewerDialog(
      photos: photos,
      initialIndex: initialIndex,
      canEdit: canEdit,
      canDelete: canDelete,
      onDeleted: onDeleted,
      onUpdated: onUpdated,
      etiquetaEscena: etiquetaEscena,
    ),
  );
}

class _PhotoViewerDialog extends StatefulWidget {
  final List<GalleryPhoto> photos;
  final int initialIndex;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback? onDeleted;
  final VoidCallback? onUpdated;
  final String? etiquetaEscena;

  const _PhotoViewerDialog({
    required this.photos,
    required this.initialIndex,
    required this.canEdit,
    required this.canDelete,
    this.onDeleted,
    this.onUpdated,
    this.etiquetaEscena,
  });

  @override
  State<_PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<_PhotoViewerDialog> {
  late List<GalleryPhoto> _photos;
  late int _index;
  bool _editing = false;
  bool _saving = false;
  bool _downloading = false;

  late String _tipoFoto;
  late final TextEditingController _personaje;
  late final TextEditingController _descripcion;
  late final TextEditingController _notas;
  late Future<List<CharacterModel>> _personajesFuture;

  GalleryPhoto get _photo => _photos[_index];

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.photos);
    _index = widget.initialIndex.clamp(0, _photos.length - 1);
    _syncControllersFromPhoto();
    final session = context.read<AuthSession>();
    _personajesFuture = CharacterService(session.api).all(session.projectId ?? '');
  }

  void _syncControllersFromPhoto() {
    _tipoFoto = kTiposFoto.contains(_photo.tipoFoto) ? _photo.tipoFoto : kTiposFoto.first;
    _personaje = TextEditingController(text: _photo.personajeCodigo ?? '');
    _descripcion = TextEditingController(text: _photo.descripcion ?? '');
    _notas = TextEditingController(text: _photo.notasContinuidad ?? '');
  }

  @override
  void dispose() {
    _personaje.dispose();
    _descripcion.dispose();
    _notas.dispose();
    super.dispose();
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _tipoFoto = kTiposFoto.contains(_photo.tipoFoto) ? _photo.tipoFoto : kTiposFoto.first;
      _personaje.text = _photo.personajeCodigo ?? '';
      _descripcion.text = _photo.descripcion ?? '';
      _notas.text = _photo.notasContinuidad ?? '';
    });
  }

  // Cambia de foto sin cerrar el diálogo (flechas anterior/siguiente):
  // descarta cualquier edición sin guardar de la foto actual y
  // reinicia los controladores con los datos de la nueva.
  void _goTo(int newIndex) {
    if (newIndex < 0 || newIndex >= _photos.length || newIndex == _index) return;
    setState(() {
      _index = newIndex;
      _editing = false;
      _tipoFoto = kTiposFoto.contains(_photo.tipoFoto) ? _photo.tipoFoto : kTiposFoto.first;
      _personaje.text = _photo.personajeCodigo ?? '';
      _descripcion.text = _photo.descripcion ?? '';
      _notas.text = _photo.notasContinuidad ?? '';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final session = context.read<AuthSession>();
    try {
      final actualizada = await GalleryService(session.api).update(_photo.idFoto, {
        'tipo_foto': _tipoFoto,
        'personaje_codigo': _personaje.text.trim(),
        'descripcion': _descripcion.text.trim(),
        'notas_continuidad': _notas.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _photos[_index] = actualizada;
        _editing = false;
        _saving = false;
      });
      widget.onUpdated?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete() async {
    // Soft-delete: se mueve a la Papelera de Reciclaje, no se borra
    // para siempre (ver recycle_bin_screen.dart).
    final confirmed = await confirmDelete(
      context,
      message: '¿Mover esta foto a la papelera de reciclaje?',
    );
    if (!confirmed) return;

    final session = context.read<AuthSession>();
    try {
      await GalleryService(session.api).delete(_photo.idFoto);
      if (mounted) Navigator.of(context).pop();
      widget.onDeleted?.call();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // true en Android/iOS (nunca en Web/Windows, donde no existe una
  // "Galería del sistema" a la que guardar) — mismo criterio que la
  // descarga masiva de gallery_screen.dart.
  bool get _guardarEnGaleriaNativa => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  (String, String) _splitNombreArchivo(String archivoNombre) {
    final idx = archivoNombre.lastIndexOf('.');
    if (idx <= 0 || idx == archivoNombre.length - 1) return (archivoNombre, 'jpg');
    return (archivoNombre.substring(0, idx), archivoNombre.substring(idx + 1));
  }

  MimeType _mimeFor(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MimeType.jpeg;
      case 'png':
        return MimeType.png;
      default:
        return MimeType.other;
    }
  }

  /// Descarga la foto que se está viendo ahora mismo — automático, sin
  /// pasos extra: en Android/iOS se guarda directo en la Galería del
  /// sistema (álbum "Raccord", igual que la descarga masiva); en
  /// Web/Windows abre el selector "Guardar como". Lleva la misma marca
  /// de agua que el resto de descargas de la app (guion, PDFs, fotos).
  Future<void> _download() async {
    setState(() => _downloading = true);
    final session = context.read<AuthSession>();
    try {
      final bytesOriginales = await GalleryService(session.api).archivoBytes(_photo.idFoto);
      final (nombreBase, extensionOriginal) = _splitNombreArchivo(_photo.archivoNombre);
      final marcaAguaTexto = watermarkTextFor(session);

      // Si la marca de agua falla (ej. archivo que no es una imagen
      // válida), se descarga igual la foto original sin marca, en vez
      // de bloquear la descarga completa (mismo criterio que en
      // gallery_screen.dart).
      Uint8List bytesFinal;
      String extension;
      try {
        bytesFinal = await watermarkImageBytes(Uint8List.fromList(bytesOriginales), marcaAguaTexto);
        extension = 'png'; // watermarkImageBytes siempre devuelve PNG
      } catch (_) {
        bytesFinal = Uint8List.fromList(bytesOriginales);
        extension = extensionOriginal;
      }

      if (_guardarEnGaleriaNativa) {
        try {
          await Gal.putImageBytes(bytesFinal, name: nombreBase, album: 'Raccord');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto guardada correctamente')));
          }
        } on GalException catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.type.message)));
        }
      } else {
        final savedPath = await FileSaver.instance.saveAs(
          name: nombreBase,
          bytes: bytesFinal,
          fileExtension: extension,
          mimeType: _mimeFor(extension),
        );
        // savedPath == null: la persona cerró el selector "Guardar
        // como" sin elegir carpeta — no es un error, no hace falta
        // avisar nada.
        if (mounted && savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto guardada correctamente')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo descargar la foto.')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<AuthSession>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 10))],
          ),
          // Marco Polaroid: margen blanco fino a los lados/arriba; la
          // franja de abajo (donde van los detalles) queda más ancha.
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          // `key` con el id de la foto: fuerza a
                          // FutureBuilder a arrancar un future nuevo al
                          // navegar con las flechas (si no, Flutter podría
                          // reusar el estado del frame anterior y quedarse
                          // mostrando la imagen vieja un instante).
                          child: FutureBuilder<List<int>>(
                            key: ValueKey(_photo.idFoto),
                            future: GalleryService(session.api).archivoBytes(_photo.idFoto),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.contain);
                            },
                          ),
                        ),
                      ),
                      if (_photos.length > 1) ...[
                        Positioned(
                          left: 4,
                          top: 0,
                          bottom: 0,
                          child: Center(child: _navArrow(Icons.chevron_left, _index > 0 ? () => _goTo(_index - 1) : null)),
                        ),
                        Positioned(
                          right: 4,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _navArrow(Icons.chevron_right, _index < _photos.length - 1 ? () => _goTo(_index + 1) : null),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                '${_index + 1} / ${_photos.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Fuerza tema claro en la franja blanca del Polaroid,
              // independiente de si la app está en modo oscuro — el
              // papel de una foto Polaroid es blanco siempre.
              Theme(
                data: ThemeData.light(),
                // `Theme` solo cambia lo que los widgets leen vía
                // Theme.of(context) (colores del input, del dropdown,
                // etc.). Los `Text` simples (como las etiquetas de
                // AppTextField/AppDropdown, que no fijan color propio a
                // propósito, para verse bien en dark E light) heredan
                // el `DefaultTextStyle` que ya venía puesto por el
                // `Material` oscuro del Dialog exterior — por eso salían
                // blanco-sobre-blanco. Un `Material` nuevo acá adentro
                // recalcula ese DefaultTextStyle a partir del tema claro
                // que acabamos de fijar arriba.
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 12, 6, 14),
                    child: _editing ? _buildEditForm() : _buildDetails(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback? onPressed) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: onPressed != null ? Colors.white : Colors.white24),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.etiquetaEscena != null && widget.etiquetaEscena!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(widget.etiquetaEscena!, style: const TextStyle(color: AppColors.negro, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_photo.tipoFoto}${_photo.personajeCodigo != null && _photo.personajeCodigo!.isNotEmpty ? ' · ${_photo.personajeCodigo}' : ''}',
                    style: const TextStyle(color: AppColors.negro, fontWeight: FontWeight.w700),
                  ),
                  if (_photo.descripcion != null && _photo.descripcion!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_photo.descripcion!, style: const TextStyle(color: AppColors.grisOscuro)),
                    ),
                  if (_photo.notasContinuidad != null && _photo.notasContinuidad!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_photo.notasContinuidad!, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: _downloading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.grisOscuro),
                    )
                  : const Icon(Icons.download_outlined, color: AppColors.grisOscuro, size: 20),
              tooltip: 'Descargar foto',
              onPressed: _downloading ? null : _download,
            ),
            if (widget.canEdit)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.grisOscuro, size: 20),
                tooltip: 'Editar detalles',
                onPressed: () => setState(() => _editing = true),
              ),
            if (widget.canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.grisOscuro, size: 20),
                tooltip: 'Eliminar foto',
                onPressed: _delete,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDropdown<String>(
          label: 'Tipo de foto',
          value: _tipoFoto,
          items: kTiposFoto,
          labelBuilder: (e) => e,
          onChanged: _saving ? (_) {} : (v) => setState(() => _tipoFoto = v ?? _tipoFoto),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<CharacterModel>>(
          future: _personajesFuture,
          builder: (context, snap) {
            return CharacterAutocompleteField(
              label: 'Personaje',
              hint: 'Ej: Pe → Pedro, Pietro...',
              personajes: snap.data ?? const <CharacterModel>[],
              initialValue: _personaje.text,
              onSelected: _saving ? (_) {} : (p) => setState(() => _personaje.text = p.codigoPersonaje),
            );
          },
        ),
        if (_personaje.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Código: ${_personaje.text}', style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
          ),
        const SizedBox(height: 10),
        AppTextField(label: 'Descripción', controller: _descripcion, enabled: !_saving, maxLines: 2),
        const SizedBox(height: 10),
        AppTextField(label: 'Notas de continuidad', controller: _notas, enabled: !_saving, maxLines: 2),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _saving ? null : _cancelEdit,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.azulProfundo),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ],
    );
  }
}
