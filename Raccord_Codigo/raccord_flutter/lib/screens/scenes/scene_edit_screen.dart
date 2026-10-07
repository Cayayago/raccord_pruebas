import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/responsive.dart';
import '../../core/session.dart';
import '../../models/character.dart';
import '../../models/gallery_photo.dart';
import '../../models/scene.dart';
import '../../services/character_service.dart';
import '../../services/gallery_service.dart';
import '../../services/scene_service.dart';
import '../../services/script_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/character_autocomplete_field.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/photo_viewer_dialog.dart';
import '../../widgets/state_views.dart';
import 'scenes_screen.dart' show colorForEstadoEscena;

/// Mockup 6.1: edición de escena + Continuidad Visual (subir y ver las
/// fotos de esa escena). Layout de dos paneles en pantallas anchas;
/// en angostas se apilan verticalmente.
class SceneEditScreen extends StatefulWidget {
  final Scene scene;
  const SceneEditScreen({super.key, required this.scene});

  @override
  State<SceneEditScreen> createState() => _SceneEditScreenState();
}

class _SceneEditScreenState extends State<SceneEditScreen> {
  late final _numero = TextEditingController(text: widget.scene.numeroDeEscena);
  late final _encabezado = TextEditingController(text: widget.scene.encabezado);
  late final _ciudad = TextEditingController(text: widget.scene.ciudad ?? '');
  late final _diaDramatico = TextEditingController(text: widget.scene.diaDramatico?.toString() ?? '');
  late final _fecha = TextEditingController(
    text: widget.scene.fechaDeGrabacion != null ? widget.scene.fechaDeGrabacion!.toIso8601String().split('T').first : '',
  );
  // Campo libre de comentarios de la escena — pedido explícito del
  // usuario (2026-09-02), ver Scene.comentarios en models/scene.dart.
  late final _comentarios = TextEditingController(text: widget.scene.comentarios ?? '');
  late String _estado = widget.scene.estado;
  bool _savingInfo = false;
  bool _changed = false;

  Future<List<Map<String, dynamic>>>? _cast;
  Future<List<GalleryPhoto>>? _photos;

  // Catálogo completo de personajes del proyecto, para el autocompletado
  // (añadir al cast de la escena, y el campo "Personaje" al subir
  // fotos). No depende de la escena, se carga una sola vez.
  List<CharacterModel> _personajes = [];
  // Cambia cada vez que se agrega un personaje al cast, para forzar que
  // CharacterAutocompleteField reinicie su campo de texto interno
  // (Autocomplete no expone un controller externo para limpiarlo).
  int _addPersonajeTick = 0;

  // Vista dividida: mismo patrón que Desglose/Escenas — muestra el PDF
  // del guion de esta escena al lado de su información.
  bool _vistaDividida = false;
  Future<List<int>>? _pdfBytes;

  // isMobileScreen() usa MediaQuery.of(context), que todavía no está
  // disponible dentro de initState() (el árbol de widgets no terminó de
  // montarse) — llamarlo ahí tira "dependOnInheritedWidgetOfExactType...
  // called before initState() completed". Por eso esa parte se movió a
  // didChangeDependencies(), que es el lugar correcto para leer
  // MediaQuery/Theme por primera vez. Este flag evita repetir la carga
  // cada vez que cambian las dependencias (ej. al rotar la pantalla).
  bool _didInitDependencies = false;

  @override
  void initState() {
    super.initState();
    final idEscena = widget.scene.idEscena;
    if (idEscena != null) {
      final session = context.read<AuthSession>();
      _cast = SceneService(session.api).cast(idEscena);
      _photos = GalleryService(session.api).byScene(idEscena);
    }
    final session = context.read<AuthSession>();
    CharacterService(session.api).all(session.projectId ?? '').then((list) {
      if (mounted) setState(() => _personajes = list);
    }).catchError((_) {
      // Si falla, el autocompletado simplemente queda sin sugerencias —
      // no es motivo para tumbar el resto de la pantalla.
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDependencies) return;
    _didInitDependencies = true;
    // En móvil/tablet (app nativa) la vista dividida no está disponible
    // (ver build()) — solo en PC/Web —, así que no tiene sentido
    // descargar el PDF del guion completo solo para nunca mostrarlo.
    if (widget.scene.idGuion != null && canUseSplitView(context)) {
      final session = context.read<AuthSession>();
      _pdfBytes = ScriptService(session.api).archivoBytes(widget.scene.idGuion!);
    }
  }

  void _reloadCast() {
    final idEscena = widget.scene.idEscena;
    if (idEscena == null) return;
    final session = context.read<AuthSession>();
    // Con llaves — mismo motivo que _reloadPhotos más abajo (evita
    // 'setState() callback argument returned a Future').
    setState(() {
      _cast = SceneService(session.api).cast(idEscena);
    });
  }

  Future<void> _addCharacterToCast(CharacterModel personaje) async {
    final idEscena = widget.scene.idEscena;
    final idPersonaje = personaje.idPersonaje;
    if (idEscena == null || idPersonaje == null) return;

    final session = context.read<AuthSession>();
    try {
      await SceneService(session.api).addToCast(idEscena, idPersonaje);
      _changed = true;
      setState(() => _addPersonajeTick++);
      _reloadCast();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _removeCharacterFromCast(String idPersonaje) async {
    final idEscena = widget.scene.idEscena;
    if (idEscena == null) return;

    final session = context.read<AuthSession>();
    try {
      await SceneService(session.api).removeFromCast(idEscena, idPersonaje);
      _changed = true;
      _reloadCast();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  void dispose() {
    _numero.dispose();
    _encabezado.dispose();
    _ciudad.dispose();
    _diaDramatico.dispose();
    _fecha.dispose();
    _comentarios.dispose();
    super.dispose();
  }

  void _reloadPhotos() {
    final idEscena = widget.scene.idEscena;
    if (idEscena == null) return;
    final session = context.read<AuthSession>();
    // Con llaves para que el callback de setState devuelva void y no el
    // Future de byScene() — si no, Flutter lanza 'setState() callback
    // argument returned a Future' ANTES de reconstruir el widget, así
    // que la grilla de fotos nunca se actualizaba tras subir una foto
    // (la foto SÍ se subía bien, pero no aparecía hasta salir y volver
    // a entrar a la escena — reporte explícito del usuario).
    setState(() {
      _photos = GalleryService(session.api).byScene(idEscena);
    });
  }

  // Para "deslizar hacia abajo para recargar" (ver MobileRefresh):
  // refresca fotos y reparto, pero NO los campos del formulario de
  // información — recargar esos pisaría cualquier edición sin guardar
  // que la persona tenga en pantalla.
  Future<void> _onPullRefresh() async {
    _reloadPhotos();
    _reloadCast();
    try {
      await Future.wait([
        if (_photos != null) _photos!,
        if (_cast != null) _cast!,
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canEditInfo = session.can('create_scenes');
    final canUpload = session.can('upload_photos');
    // Separado de canUpload a pedido explícito: Onset puede subir fotos
    // de continuidad, pero no eliminarlas.
    final canDeletePhotos = session.can('delete_photos');
    // La vista dividida (guion en PDF al lado de la info) no se ofrece
    // solo se ofrece en PC/Web — en móvil/tablet (app nativa) nunca debe
    // aparecer, sin importar el ancho de pantalla.
    final splitViewAllowed = canUseSplitView(context);
    final mostrarVistaDividida = _vistaDividida && splitViewAllowed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: AppScaffold(
        title: 'Continuidad Visual',
        showBack: true,
        onBack: () => Navigator.of(context).pop(_changed),
        actions: [
          if (widget.scene.idGuion != null && splitViewAllowed)
            IconButton(
              icon: Icon(_vistaDividida ? Icons.vertical_split : Icons.vertical_split_outlined),
              tooltip: _vistaDividida ? 'Cerrar vista dividida' : 'Vista dividida con el guion',
              color: _vistaDividida ? AppColors.azulProfundo : null,
              onPressed: () => setState(() => _vistaDividida = !_vistaDividida),
            ),
        ],
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            final infoPanel = _infoPanel(canEditInfo);
            final continuityPanel = _continuityPanel(canUpload, canDeletePhotos);

            final Widget contenido = wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: infoPanel),
                      const SizedBox(width: 20),
                      Expanded(child: continuityPanel),
                    ],
                  )
                : Column(
                    children: [
                      infoPanel,
                      const SizedBox(height: 20),
                      continuityPanel,
                    ],
                  );

            if (mostrarVistaDividida) {
              if (wide) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: _buildScriptPane()),
                      const SizedBox(width: 16),
                      const VerticalDivider(width: 1),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: SingleChildScrollView(child: contenido),
                      ),
                    ],
                  ),
                );
              }
              // Angosto: el PDF va arriba (altura fija razonable para
              // leer) y el resto se apila debajo, todo en un solo scroll.
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 420, child: _buildScriptPane()),
                    const SizedBox(height: 20),
                    contenido,
                  ],
                ),
              );
            }

            // Único caso que realmente se ejecuta en móvil/tablet
            // (mostrarVistaDividida es siempre false ahí): se envuelve en
            // MobileRefresh para el gesto de "deslizar hacia abajo".
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: contenido,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScriptPane() {
    if (_pdfBytes == null) {
      return const EmptyView(message: 'Esta escena no tiene un guion asociado.', icon: Icons.picture_as_pdf_outlined);
    }
    return FutureBuilder<List<int>>(
      future: _pdfBytes,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
        if (snap.hasError) {
          // El backend responde 404 cuando el guion todavía no tiene PDF
          // cargado — eso es un estado normal (informativo), no una
          // falla real, así que se muestra como EmptyView en vez de
          // ErrorView (que se ve como un error/bug).
          if (snap.error is ApiException && (snap.error as ApiException).statusCode == 404) {
            return const EmptyView(
              message: 'El guion de esta escena todavía no tiene un PDF cargado.\nSube el PDF desde el módulo Guión para poder verlo aquí.',
              icon: Icons.picture_as_pdf_outlined,
            );
          }
          final message = snap.error is ApiException ? (snap.error as ApiException).message : 'No se pudo cargar el guion.';
          return ErrorView(message: message, onRetry: () => setState(() {}));
        }
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return const EmptyView(message: 'Este guion todavía no tiene un PDF cargado.', icon: Icons.picture_as_pdf_outlined);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PdfViewer.data(
            Uint8List.fromList(bytes),
            sourceName: 'guion-editar-escena-${widget.scene.idGuion}',
            params: PdfViewerParams(backgroundColor: AppColors.bg),
          ),
        );
      },
    );
  }

  Widget _panelBox({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoPanel(bool canEdit) {
    return _panelBox(
      title: 'Información de la Escena',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El campo "Escena" (número) queda oculto a pedido del
          // usuario: el controller sigue vivo con el valor original y
          // se sigue guardando igual en _saveInfo(), solo no se
          // muestra en el formulario.
          AppTextField(label: 'Encabezado', controller: _encabezado, enabled: canEdit),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Día Dramático',
            controller: _diaDramatico,
            enabled: canEdit,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppTextField(label: 'Ciudad', controller: _ciudad, enabled: canEdit),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Fecha de Grabación',
            controller: _fecha,
            enabled: canEdit,
            hint: 'AAAA-MM-DD',
            onTap: canEdit ? _pickDate : null,
            readOnly: canEdit,
          ),
          const SizedBox(height: 14),
          if (canEdit)
            AppDropdown<String>(
              label: 'Estado',
              value: _estado,
              items: kEstadosEscena,
              labelBuilder: (e) => e,
              onChanged: (v) => setState(() => _estado = v ?? _estado),
            )
          else ...[
            const Text('Estado', style: TextStyle(color: AppColors.grisMedio, fontSize: 12)),
            const SizedBox(height: 6),
            StatusPill(label: _estado, color: colorForEstadoEscena(_estado)),
          ],
          const SizedBox(height: 14),
          const Text('Personajes', style: TextStyle(color: AppColors.grisMedio, fontSize: 12)),
          const SizedBox(height: 6),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _cast,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
              }
              final cast = snap.data ?? [];
              final idsEnCast = cast.map((c) => c['id_personaje']?.toString()).whereType<String>().toSet();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cast.isEmpty)
                    const Text('— Sin personajes asignados —', style: TextStyle(color: AppColors.grisMedio))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cast.map((c) {
                        final idPersonaje = c['id_personaje']?.toString();
                        final label = '${c['codigo_personaje'] ?? ''} - ${c['nombre'] ?? ''}';
                        return Chip(
                          label: Text(label),
                          onDeleted: canEdit && idPersonaje != null ? () => _removeCharacterFromCast(idPersonaje) : null,
                        );
                      }).toList(),
                    ),
                  // Permite añadir más personajes a la escena en caso de
                  // que se necesiten — no solo los que ya venían del
                  // guion segmentado.
                  if (canEdit) ...[
                    const SizedBox(height: 12),
                    CharacterAutocompleteField(
                      key: ValueKey(_addPersonajeTick),
                      label: 'Añadir personaje',
                      hint: 'Ej: Ma → María, Martha...',
                      personajes: _personajes
                          .where((p) => p.idPersonaje != null && !idsEnCast.contains(p.idPersonaje))
                          .toList(),
                      onSelected: _addCharacterToCast,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Comentarios',
            hint: 'Notas u observaciones sobre esta escena',
            controller: _comentarios,
            enabled: canEdit,
            maxLines: 3,
          ),
          if (canEdit) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingInfo ? null : _saveInfo,
                child: _savingInfo
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _continuityPanel(bool canUpload, bool canDeletePhotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canUpload) _UploadPhotoCard(scene: widget.scene, onUploaded: _reloadPhotos, personajes: _personajes),
        const SizedBox(height: 20),
        FutureBuilder<List<GalleryPhoto>>(
          future: _photos,
          builder: (context, snap) {
            final count = snap.data?.length;
            return Text(
              'Fotos de Continuidad${count != null ? ' ($count)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<GalleryPhoto>>(
          future: _photos,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
            if (snap.hasError) return ErrorView(message: 'No se pudieron cargar las fotos.', onRetry: _reloadPhotos);
            final photos = snap.data ?? [];
            if (photos.isEmpty) {
              return const EmptyView(message: 'Todavía no hay fotos de continuidad para esta escena.', icon: Icons.photo_library_outlined);
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              // Columnas calculadas por ancho disponible (móvil vs.
              // tablet/desktop) en vez de un `crossAxisCount` fijo.
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, i) => _PhotoThumb(
                photo: photos[i],
                allPhotos: photos,
                index: i,
                canEdit: canUpload,
                canDelete: canDeletePhotos,
                onDeleted: _reloadPhotos,
                onUpdated: _reloadPhotos,
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_fecha.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fecha.text = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _saveInfo() async {
    final idEscena = widget.scene.idEscena;
    if (idEscena == null) return;

    setState(() => _savingInfo = true);
    final session = context.read<AuthSession>();

    try {
      await SceneService(session.api).updatePartial(idEscena, {
        'numero_de_escena': _numero.text.trim(),
        'encabezado': _encabezado.text.trim(),
        'ciudad': _ciudad.text.trim(),
        'dia_dramatico': int.tryParse(_diaDramatico.text.trim()),
        'fecha_de_grabacion': _fecha.text.trim().isEmpty ? null : _fecha.text.trim(),
        'estado': _estado,
        'comentarios': _comentarios.text.trim(),
      });
      _changed = true;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escena actualizada')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }
}

enum _PhotoSource { camera, files }

class _UploadPhotoCard extends StatefulWidget {
  final Scene scene;
  final VoidCallback onUploaded;
  final List<CharacterModel> personajes;
  const _UploadPhotoCard({required this.scene, required this.onUploaded, this.personajes = const []});

  @override
  State<_UploadPhotoCard> createState() => _UploadPhotoCardState();
}

class _UploadPhotoCardState extends State<_UploadPhotoCard> {
  String _tipoFoto = kTiposFoto.first;
  String _modoSubida = kModosSubidaFoto.first;
  final _personaje = TextEditingController();
  final _descripcion = TextEditingController();
  final _notas = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _personaje.dispose();
    _descripcion.dispose();
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subir Nueva Foto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          AppDropdown<String>(
            label: 'Foto o Collage',
            value: _modoSubida,
            items: kModosSubidaFoto,
            labelBuilder: (e) => e,
            onChanged: (v) => setState(() => _modoSubida = v ?? _modoSubida),
          ),
          if (collageCountFor(_modoSubida) != null) ...[
            const SizedBox(height: 4),
            Text(
              'Elegirás ${collageCountFor(_modoSubida)} fotos (con la cámara, una por una, o de tu galería/carpeta) y se combinarán en una sola imagen.',
              style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          AppDropdown<String>(
            label: 'Tipo de Foto',
            value: _tipoFoto,
            items: kTiposFoto,
            labelBuilder: (e) => e,
            onChanged: (v) => setState(() => _tipoFoto = v ?? _tipoFoto),
          ),
          const SizedBox(height: 14),
          CharacterAutocompleteField(
            label: 'Personaje',
            hint: 'Ej: Ma → María, Martha...',
            personajes: widget.personajes,
            onSelected: (p) => setState(() => _personaje.text = p.codigoPersonaje),
          ),
          if (_personaje.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Código seleccionado: ${_personaje.text}', style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          AppTextField(label: 'Descripción', hint: 'Descripción de la foto', controller: _descripcion),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Notas de Continuidad',
            hint: 'Detalles relevantes para continuidad: vestuario, maquillaje, props, iluminación, etc.',
            controller: _notas,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _pickAndUpload,
              icon: _loading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.file_upload_outlined, size: 18),
              label: Text(_loading
                  ? 'Subiendo...'
                  : (collageCountFor(_modoSubida) != null ? 'Elegir fotos y crear collage' : 'Subir Foto(s)')),
            ),
          ),
        ],
      ),
    );
  }

  /// Punto de entrada del botón "Subir Foto(s)": en modo "Individual"
  /// pregunta el origen (cámara o galería/archivos) y delega a
  /// [_captureFromCamera] o [_pickFromFiles]; en modo "Collage N" también
  /// pregunta el origen (mismo diálogo), y delega a
  /// [_pickAndUploadCollage], que a su vez toma las N fotos con la
  /// cámara en secuencia o las elige todas juntas de la galería, según
  /// lo que haya contestado acá.
  Future<void> _pickAndUpload() async {
    final idEscena = widget.scene.idEscena;
    if (idEscena == null) return;

    final n = collageCountFor(_modoSubida);

    final source = await _askPhotoSource(
      title: n != null ? '¿De dónde quieres tomar las $n fotos del collage?' : '¿De dónde quieres subir la foto?',
    );
    if (source == null) return; // se canceló el diálogo

    if (n != null) {
      await _pickAndUploadCollage(idEscena, n, source);
      return;
    }

    if (source == _PhotoSource.camera) {
      await _captureFromCamera(idEscena);
    } else {
      await _pickFromFiles(idEscena);
    }
  }

  /// Junta las [n] imágenes del collage según [source]: con cámara
  /// ([_captureNFromCamera]) toma una foto a la vez, dejando confirmar
  /// cada una con el propio flujo nativo de la cámara antes de pasar a
  /// la siguiente — pedido explícito del usuario ("tomo la foto 1 y le
  /// doy chulo de bien y luego la segunda..."), en vez de forzar a
  /// elegir todas de la galería de una sola vez (que sigue disponible
  /// como alternativa). Las combina en una sola imagen con
  /// [_buildCollage] y sube ÚNICAMENTE el resultado combinado — las N
  /// fotos originales no quedan guardadas por separado.
  Future<void> _pickAndUploadCollage(String idEscena, int n, _PhotoSource source) async {
    List<Uint8List> imagenesBytes;

    if (source == _PhotoSource.camera) {
      final capturadas = await _captureNFromCamera(n);
      if (capturadas == null) return; // canceló alguna captura: se aborta el collage completo
      imagenesBytes = capturadas;
    } else {
      // file_picker 13.x: pickFiles() ya no envuelve el resultado en
      // FilePickerResult — devuelve la lista de PlatformFile directo
      // (vacía si se cancela). Los bytes se leen aparte, async, con
      // readAsBytes() por archivo (ver Future.wait abajo).
      final picked = await FilePicker.pickFiles(type: FileType.image);
      if (picked.isEmpty) return;

      if (picked.length != n) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Elige exactamente $n fotos para el collage (seleccionaste ${picked.length}).')),
          );
        }
        return;
      }
      imagenesBytes = await Future.wait(picked.map((f) => f.readAsBytes()));
    }

    setState(() => _loading = true);
    try {
      final collageBytes = await _buildCollage(imagenesBytes);
      await _uploadBytes(idEscena, [(bytes: collageBytes, name: 'collage_$n.png')]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el collage. Intenta con otras fotos.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Toma [n] fotos en secuencia con la cámara del dispositivo — cada
  /// captura usa el propio flujo nativo de la cámara del sistema (foto,
  /// confirmar/"chulo" o repetir) antes de pasar a la siguiente. Si la
  /// persona cancela CUALQUIER captura (botón atrás del visor nativo),
  /// se aborta el collage entero en vez de armarlo con menos fotos de
  /// las que pidió — pedido explícito del usuario: "si dijo dos, por lo
  /// menos las dos fotos deben estar correctas".
  Future<List<Uint8List>?> _captureNFromCamera(int n) async {
    final capturadas = <Uint8List>[];
    for (var i = 0; i < n; i++) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto ${i + 1} de $n — tómala y confírmala.'), duration: const Duration(seconds: 2)),
        );
      }
      final XFile? foto;
      try {
        // Mismos límites que la captura individual (_captureFromCamera):
        // 1920px de lado mayor evita fotos de varios MB sin redimensionar.
        foto = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo acceder a la cámara. Verifica los permisos del dispositivo.')),
          );
        }
        return null;
      }
      if (foto == null) return null; // canceló esta captura: se aborta todo el collage
      capturadas.add(await foto.readAsBytes());
    }
    return capturadas;
  }

  /// Decodifica cada imagen y las dibuja sobre un lienzo cuadrado fijo
  /// (1200x1200) según el layout de [_collageRects], recortando cada
  /// una en modo "cover" (llena su celda sin deformarse) y devuelve el
  /// PNG resultante — desde ahí se sube igual que cualquier otra foto.
  Future<Uint8List> _buildCollage(List<Uint8List> imagenesBytes) async {
    final imagenes = <ui.Image>[];
    for (final bytes in imagenesBytes) {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      imagenes.add(frame.image);
    }

    const lado = 1200.0;
    const espacio = 6.0;
    final celdas = _collageRects(imagenes.length, lado, espacio);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, lado, lado));
    canvas.drawRect(const Rect.fromLTWH(0, 0, lado, lado), Paint()..color = const Color(0xFFFFFFFF));

    for (var i = 0; i < imagenes.length; i++) {
      final img = imagenes[i];
      final celda = celdas[i];
      final srcAspect = img.width / img.height;
      final dstAspect = celda.width / celda.height;
      late Rect src;
      if (srcAspect > dstAspect) {
        final srcW = img.height * dstAspect;
        src = Rect.fromLTWH((img.width - srcW) / 2, 0, srcW, img.height.toDouble());
      } else {
        final srcH = img.width / dstAspect;
        src = Rect.fromLTWH(0, (img.height - srcH) / 2, img.width.toDouble(), srcH);
      }
      canvas.save();
      canvas.clipRect(celda);
      canvas.drawImageRect(img, src, celda, Paint());
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final resultado = await picture.toImage(lado.toInt(), lado.toInt());
    final byteData = await resultado.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Distribución de celdas del collage según cuántas fotos entran:
  /// 2 = lado a lado, 3 = una arriba (ancho completo) + dos abajo, 4 =
  /// grilla 2x2. Sin celdas vacías, todo el lienzo queda cubierto.
  List<Rect> _collageRects(int n, double lado, double espacio) {
    switch (n) {
      case 2:
        final w = (lado - espacio) / 2;
        return [
          Rect.fromLTWH(0, 0, w, lado),
          Rect.fromLTWH(w + espacio, 0, w, lado),
        ];
      case 3:
        final altoArriba = (lado - espacio) * 0.55;
        final altoAbajo = lado - espacio - altoArriba;
        final wAbajo = (lado - espacio) / 2;
        return [
          Rect.fromLTWH(0, 0, lado, altoArriba),
          Rect.fromLTWH(0, altoArriba + espacio, wAbajo, altoAbajo),
          Rect.fromLTWH(wAbajo + espacio, altoArriba + espacio, wAbajo, altoAbajo),
        ];
      case 4:
        final w = (lado - espacio) / 2;
        final h = (lado - espacio) / 2;
        return [
          Rect.fromLTWH(0, 0, w, h),
          Rect.fromLTWH(w + espacio, 0, w, h),
          Rect.fromLTWH(0, h + espacio, w, h),
          Rect.fromLTWH(w + espacio, h + espacio, w, h),
        ];
      default:
        final w = (lado - espacio * (n - 1)) / n;
        return List.generate(n, (i) => Rect.fromLTWH(i * (w + espacio), 0, w, lado));
    }
  }

  /// Diálogo CENTRADO en pantalla (no una hoja pegada al borde inferior)
  /// para elegir el origen de la foto. La opción "Tomar foto con la
  /// cámara" solo se ofrece en celular/tablet (`defaultTargetPlatform`
  /// detecta Android/iOS incluso corriendo en el navegador): en PC de
  /// escritorio el atributo que abre la cámara no funciona y solo
  /// termina reabriendo el mismo explorador de archivos, así que ahí
  /// directo se muestra únicamente la opción de galería/carpeta.
  Future<_PhotoSource?> _askPhotoSource({String title = '¿De dónde quieres subir la foto?'}) {
    final showCamera = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

    return showDialog<_PhotoSource>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (showCamera)
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Tomar foto con la cámara'),
                    onTap: () => Navigator.of(context).pop(_PhotoSource.camera),
                  ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('Elegir de la galería / carpeta'),
                  subtitle: const Text('Puedes seleccionar varias fotos a la vez', style: TextStyle(fontSize: 11)),
                  onTap: () => Navigator.of(context).pop(_PhotoSource.files),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureFromCamera(String idEscena) async {
    final XFile? foto;
    try {
      // maxWidth/maxHeight: la cámara de un celular moderno saca fotos
      // de varios MB (4000x3000px+) — sin este límite, esa foto se subía
      // sin redimensionar y la subida podía tardar mucho más de lo
      // razonable en red real (a diferencia de imageQuality, que solo
      // comprime JPEG pero no toca la resolución). 1920px de lado mayor
      // es de sobra para fotos de continuidad.
      foto = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      // P.ej. el navegador/SO negó el permiso de cámara, o el
      // dispositivo (desktop nativo) no tiene una cámara soportada.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo acceder a la cámara. Verifica los permisos del navegador/dispositivo.')),
        );
      }
      return;
    }
    if (foto == null) return; // se canceló

    final bytes = await foto.readAsBytes();
    await _uploadBytes(idEscena, [(bytes: bytes, name: foto.name)]);
  }

  Future<void> _pickFromFiles(String idEscena) async {
    // file_picker 13.x: pickFiles() devuelve la lista de PlatformFile
    // directo (vacía si se cancela); los bytes se leen aparte, async.
    final picked = await FilePicker.pickFiles(type: FileType.image);
    if (picked.isEmpty) return;

    final archivos = await Future.wait(picked.map((f) async => (bytes: await f.readAsBytes(), name: f.name)));
    await _uploadBytes(idEscena, archivos);
  }

  Future<void> _uploadBytes(String idEscena, List<({Uint8List bytes, String name})> archivos) async {
    if (archivos.isEmpty) return;

    setState(() => _loading = true);
    final session = context.read<AuthSession>();
    final service = GalleryService(session.api);

    try {
      for (final f in archivos) {
        await service.upload(
          idEscena,
          tipoFoto: _tipoFoto,
          personajeCodigo: _personaje.text.trim(),
          descripcion: _descripcion.text.trim(),
          notasContinuidad: _notas.text.trim(),
          bytes: f.bytes,
          filename: f.name,
          contentType: _contentTypeFor(f.name),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto(s) cargada(s) correctamente')));
      }
      widget.onUploaded();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      // Antes este catch no existía: cualquier error que NO fuera
      // ApiException (ej. la respuesta del servidor llegó vacía/no-JSON
      // y GalleryService.upload no pudo parsearla) se escapaba en
      // silencio — la UI dejaba de decir "Subiendo..." pero no mostraba
      // ningún error ni recargaba la lista, así que la foto simplemente
      // "desaparecía" sin explicación. Ahora siempre se avisa algo.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la foto. Verifica tu conexión e inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class _PhotoThumb extends StatelessWidget {
  final GalleryPhoto photo;
  final List<GalleryPhoto> allPhotos;
  final int index;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;

  const _PhotoThumb({
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
    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openViewer(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: AppColors.surfaceVariant,
                child: FutureBuilder<List<int>>(
                  future: GalleryService(context.read<AuthSession>().api).archivoBytes(photo.idFoto),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    if (snap.hasError || snap.data == null) {
                      return const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.grisMedio));
                    }
                    return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
                  },
                ),
              ),
            ),
          ),
        ),
        if (canDelete)
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                tooltip: 'Eliminar foto',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                onPressed: () => _delete(context),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _delete(BuildContext context) async {
    // Soft-delete: se mueve a la Papelera de Reciclaje, no se borra
    // para siempre (ver recycle_bin_screen.dart).
    final confirmed = await confirmDelete(
      context,
      message: '¿Mover esta foto a la papelera de reciclaje?',
    );
    if (!confirmed) return;

    final session = context.read<AuthSession>();
    try {
      await GalleryService(session.api).delete(photo.idFoto);
      onDeleted();
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openViewer(BuildContext context) {
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
