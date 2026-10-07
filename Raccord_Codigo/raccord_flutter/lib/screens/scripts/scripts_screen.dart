import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/date_utils.dart';
import '../../core/session.dart';
import '../../models/script.dart';
import '../../services/script_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/state_views.dart';

/// Mockup 8: Guiones (lista + filtro + edición inline + subir/crear
/// versión) y mockup 8.1 (lector de guión — PDF real, guardado en la
/// base de datos y visualizado embebido en la app).
class ScriptsScreen extends StatefulWidget {
  const ScriptsScreen({super.key});

  @override
  State<ScriptsScreen> createState() => _ScriptsScreenState();
}

class _ScriptsScreenState extends State<ScriptsScreen> {
  late Future<List<Script>> _future;
  // null = "Todos los estados".
  String? _filtroEstado;
  // Id del guión cuya tarjeta de edición está abierta (solo una a la vez).
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Script>> _load() {
    final session = context.read<AuthSession>();
    return ScriptService(session.api).byProject(session.projectId ?? '');
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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final canEdit = session.can('upload_scripts');

    return AppScaffold(
      title: 'Guiones',
      showBack: true,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Subir Guión'),
            )
          : null,
      body: FutureBuilder<List<Script>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: 'No se pudieron cargar los guiones.', onRetry: _reload);
          final scripts = snap.data ?? [];
          if (scripts.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [EmptyView(message: 'Este proyecto todavía no tiene guiones cargados.', icon: Icons.description_outlined)],
              ),
            );
          }

          final filtered = _filtroEstado == null ? scripts : scripts.where((s) => s.estado == _filtroEstado).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.grisMedio),
                    const SizedBox(width: 8),
                    DropdownButton<String?>(
                      value: _filtroEstado,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.surfaceVariant,
                      hint: const Text('Todos los estados'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Todos los estados')),
                        ...kEstadosGuion.map((e) => DropdownMenuItem<String?>(value: e, child: Text(e))),
                      ],
                      onChanged: (v) => setState(() => _filtroEstado = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyView(message: 'No hay guiones con ese estado.', icon: Icons.filter_alt_off_outlined)
                      : MobileRefresh(
                          onRefresh: _onPullRefresh,
                          child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final s = filtered[i];
                            final isEditing = canEdit && _editingId == s.idGuion;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ScriptTile(
                                  script: s,
                                  canEdit: canEdit,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ScriptDetailScreen(script: s)),
                                  ),
                                  onEditTap: () => setState(() => _editingId = isEditing ? null : s.idGuion),
                                  onDeleteTap: () => _delete(s),
                                ),
                                if (isEditing)
                                  _ScriptEditCard(
                                    script: s,
                                    onCancel: () => setState(() => _editingId = null),
                                    onSaved: () {
                                      setState(() => _editingId = null);
                                      _reload();
                                    },
                                  ),
                              ],
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

  Future<void> _openForm(BuildContext context) async {
    final created = await showCenteredFormSheet<bool>(
      context,
      const _ScriptFormSheet(),
    );
    if (created == true) _reload();
  }

  Future<void> _delete(Script s) async {
    final idGuion = s.idGuion;
    if (idGuion == null) return;

    final confirmed = await confirmDelete(
      context,
      message: '¿Eliminar el guión "${s.nombre}"? Esto borra también TODAS sus escenas, desglose y fotos de continuidad asociadas. Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;

    final session = context.read<AuthSession>();
    try {
      await ScriptService(session.api).delete(idGuion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guión eliminado')));
      }
      _reload();
    } on ApiException catch (e) {
      // Ej. "SCRIPT_IN_USE" si el guión todavía tiene escenas asociadas
      // — el mensaje ya viene listo para mostrar desde el backend.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

Color colorForEstadoGuion(String estado) {
  switch (estado) {
    case 'Aprobado':
      return AppColors.success;
    case 'Revisión':
      return AppColors.coral;
    case 'En Rodaje':
      return AppColors.azulProfundo;
    case 'Archivado':
      return AppColors.grisMedio;
    default:
      return AppColors.warning;
  }
}

/// Abre el selector de archivos limitado a PDF. Devuelve null si la
/// persona cancela. file_picker 13.x: pickFile() (singular) devuelve
/// el PlatformFile directo, sin wrapper. Los bytes se leen aparte con
/// PlatformFile.readAsBytes() (async, funciona igual en Web que en
/// nativo) — ver los 2 lugares donde se usa este resultado más abajo.
Future<PlatformFile?> pickPdfFile() async {
  return FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
}

String formatBytes(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _ScriptTile extends StatelessWidget {
  final Script script;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const _ScriptTile({
    required this.script,
    required this.canEdit,
    required this.onTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              script.tienePdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
              color: script.tienePdf ? AppColors.coral : AppColors.grisMedio,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(script.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusPill(label: script.estado, color: colorForEstadoGuion(script.estado)),
                      const SizedBox(width: 8),
                      Text(
                        'Versión: ${script.numeroDeVersion}',
                        style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
                      ),
                      if (script.tienePdf) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· ${formatBytes(script.archivoTamano)}',
                          style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Editar',
                onPressed: onEditTap,
              ),
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                tooltip: 'Eliminar',
                onPressed: onDeleteTap,
              ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de edición rápida (mockup: nombre / estado / versión, más el
/// PDF) que aparece justo debajo del guión seleccionado. Los campos de
/// texto usan PATCH /scripts/{id}; el PDF se sube aparte con
/// POST /scripts/{id}/archivo (multipart).
class _ScriptEditCard extends StatefulWidget {
  final Script script;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  const _ScriptEditCard({required this.script, required this.onCancel, required this.onSaved});

  @override
  State<_ScriptEditCard> createState() => _ScriptEditCardState();
}

class _ScriptEditCardState extends State<_ScriptEditCard> {
  late final _nombre = TextEditingController(text: widget.script.nombre);
  late final _version = TextEditingController(text: widget.script.numeroDeVersion);
  late String _estado = widget.script.estado;
  PlatformFile? _nuevoPdf;
  bool _loading = false;

  @override
  void dispose() {
    _nombre.dispose();
    _version.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(label: 'Nombre del Guión', controller: _nombre),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: 'Estado',
                  value: _estado,
                  items: kEstadosGuion,
                  labelBuilder: (e) => e,
                  onChanged: (v) => setState(() => _estado = v ?? _estado),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(label: 'Versión', controller: _version),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Archivo PDF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _pickPdf,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(
              _nuevoPdf?.name ??
                  (widget.script.tienePdf ? 'Reemplazar "${widget.script.archivoNombre}"' : 'Seleccionar PDF'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _loading ? null : widget.onCancel,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickPdf() async {
    final file = await pickPdfFile();
    if (file != null) setState(() => _nuevoPdf = file);
  }

  Future<void> _submit() async {
    final idGuion = widget.script.idGuion;
    if (idGuion == null) return;
    if (_nombre.text.trim().isEmpty || _version.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y versión son requeridos')),
      );
      return;
    }

    setState(() => _loading = true);
    final session = context.read<AuthSession>();
    final service = ScriptService(session.api);

    try {
      await service.update(idGuion, {
        'nombre': _nombre.text.trim(),
        'estado': _estado,
        'numero_de_version': _version.text.trim(),
      });

      final pdf = _nuevoPdf;
      if (pdf != null) {
        await service.uploadArchivo(idGuion, bytes: await pdf.readAsBytes(), filename: pdf.name);
      }

      widget.onSaved();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Vista completa de un guión (mockup 8.1): metadatos + el PDF real
/// embebido con pdfrx (motor pdfium, el mismo que usa Chrome). El PDF
/// vive en la base de datos (GET /scripts/{id}/archivo) — se descarga
/// una vez a memoria y se renderiza con PdfViewer.data, sin escribir
/// nada a disco.
class ScriptDetailScreen extends StatefulWidget {
  final Script script;
  const ScriptDetailScreen({super.key, required this.script});

  @override
  State<ScriptDetailScreen> createState() => _ScriptDetailScreenState();
}

class _ScriptDetailScreenState extends State<ScriptDetailScreen> {
  Future<List<int>>? _pdfBytes;
  bool _segmentando = false;

  @override
  void initState() {
    super.initState();
    // IMPORTANTE: no se puede llamar setState() aquí — initState()
    // corre durante la fase de construcción del widget y Flutter no
    // permite invalidar el árbol en ese momento (en modo release esto
    // no lanza un error visible, simplemente deja la pantalla en
    // blanco, sin spinner ni contenido). Por eso el future se asigna
    // directo al campo, no a través de _loadPdf().
    //
    // Se intenta cargar siempre contra el servidor (sin fiarse de
    // `widget.script.tienePdf`, que puede venir de una lista ya
    // desactualizada) — si en verdad no hay archivo, el backend
    // responde 404 y se muestra el estado vacío correspondiente.
    final idGuion = widget.script.idGuion;
    if (idGuion != null) {
      final session = context.read<AuthSession>();
      _pdfBytes = ScriptService(session.api).archivoBytes(idGuion);
    }
  }

  /// Reintento manual (botón "Reintentar" del ErrorView) — aquí sí es
  /// válido usar setState porque se llama después del primer build,
  /// disparado por una interacción del usuario.
  void _loadPdf() {
    final session = context.read<AuthSession>();
    final idGuion = widget.script.idGuion;
    if (idGuion == null) return;
    setState(() {
      _pdfBytes = ScriptService(session.api).archivoBytes(idGuion);
    });
  }

  /// Descarga el PDF al disco (o dispara la descarga del navegador en
  /// Web) reusando los bytes que ya trajo el visor — evita pedirlos de
  /// nuevo al backend. Solo visible para roles con `download_files`
  /// (ver matriz de permisos: Administrador, Director, Jefe de
  /// Departamento; Onset y Usuario no la tienen).
  Future<void> _download() async {
    final future = _pdfBytes;
    if (future == null) return;

    try {
      final bytes = await future;
      var nombre = widget.script.archivoNombre?.trim();
      if (nombre == null || nombre.isEmpty) nombre = '${widget.script.nombre}.pdf';
      if (nombre.toLowerCase().endsWith('.pdf')) {
        nombre = nombre.substring(0, nombre.length - 4);
      }

      // saveAs() (no saveFile()) para que en Android se abra el selector
      // nativo y la persona elija dónde guardar (típicamente Descargas)
      // — saveFile() guardaba en una carpeta privada de la app, invisible
      // sin explorador de archivos avanzado, sin notificación ni forma
      // fácil de encontrarlo después.
      final savedPath = await FileSaver.instance.saveAs(
        name: nombre,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      // savedPath == null: la persona cerró el selector sin elegir
      // carpeta — no es un error, no hace falta avisar nada.
      if (mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF guardado correctamente')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo descargar el archivo.')),
        );
      }
    }
  }

  /// Punto de entrada del botón "Segmentar en escenas": pide la vista
  /// previa (sin escribir nada todavía) y, si el backend detectó
  /// escenas, abre el diálogo para revisar y confirmar. Si el guion no
  /// cumple los requisitos (estado, sin PDF, no se detectó nada), el
  /// backend ya manda un mensaje completo lista para mostrar tal cual.
  Future<void> _startSegmentation() async {
    final idGuion = widget.script.idGuion;
    if (idGuion == null) return;

    setState(() => _segmentando = true);
    final session = context.read<AuthSession>();

    try {
      final preview = await ScriptService(session.api).segmentar(idGuion, confirmar: false);
      if (!mounted) return;

      final resultado = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _SegmentPreviewDialog(idGuion: idGuion, preview: preview),
      );

      if (resultado != null && mounted) {
        final escenasCreadas = (resultado['escenas_creadas'] as List? ?? []).length;
        final personajesCreados = (resultado['personajes_creados'] as List? ?? []).length;
        final partes = <String>['$escenasCreadas escena(s) creada(s)'];
        if (personajesCreados > 0) partes.add('$personajesCreados personaje(s) nuevo(s)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${partes.join(', ')}. Revísalas en Escenas y Personajes.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _segmentando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final script = widget.script;
    final session = context.watch<AuthSession>();
    final canDownload = session.can('download_files');
    final canSegment = session.can('create_scenes');

    return AppScaffold(
      title: script.nombre,
      showBack: true,
      actions: [
        if (canSegment)
          IconButton(
            icon: _segmentando
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Segmentar en escenas (automático)',
            onPressed: _segmentando ? null : _startSegmentation,
          ),
        if (canDownload)
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Descargar PDF',
            onPressed: _download,
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                StatusPill(label: script.estado, color: colorForEstadoGuion(script.estado)),
                const SizedBox(width: 10),
                Text('Versión ${script.numeroDeVersion}', style: const TextStyle(color: AppColors.grisMedio)),
                if (script.descripcion != null && script.descripcion!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      script.descripcion!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _buildPdfArea(context)),
        ],
      ),
    );
  }

  Widget _buildPdfArea(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _pdfBytes,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _PdfLoadingView();
        }
        if (snap.hasError) {
          // El backend responde 404 cuando el guión todavía no tiene
          // PDF cargado — eso no es un error real, es el estado vacío.
          if (snap.error is ApiException && (snap.error as ApiException).statusCode == 404) {
            return const EmptyView(
              message: 'Este guión todavía no tiene un PDF cargado.\nUsa el lápiz en la lista para adjuntarlo.',
              icon: Icons.picture_as_pdf_outlined,
            );
          }
          final message = snap.error is ApiException ? (snap.error as ApiException).message : 'No se pudo cargar el PDF.';
          return ErrorView(message: message, onRetry: _loadPdf);
        }
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return const EmptyView(
            message: 'Este guión todavía no tiene un PDF cargado.\nUsa el lápiz en la lista para adjuntarlo.',
            icon: Icons.picture_as_pdf_outlined,
          );
        }

        // Chequeo mínimo: todo PDF válido empieza con la firma "%PDF".
        // Si esto no se cumple, el archivo llegó corrupto (problema de
        // red/descarga) y no tiene sentido pasárselo al visor.
        final looksLikePdf = bytes.length > 4 &&
            bytes[0] == 0x25 && // %
            bytes[1] == 0x50 && // P
            bytes[2] == 0x44 && // D
            bytes[3] == 0x46; // F
        if (!looksLikePdf) {
          return ErrorView(
            message: 'El archivo descargado no es un PDF válido (llegó corrupto). Intenta de nuevo.',
            onRetry: _loadPdf,
          );
        }

        final idGuion = widget.script.idGuion ?? 'guion-desconocido';

        return PdfViewer.data(
          Uint8List.fromList(bytes),
          // sourceName solo se usa como llave interna de cache de pdfrx
          // (para no re-decodificar el mismo PDF dos veces); no se
          // muestra en pantalla.
          sourceName: 'guion-$idGuion',
          params: PdfViewerParams(
            backgroundColor: AppColors.bg,
            // A pedido explícito del usuario: no se puede seleccionar ni
            // copiar texto mientras se ve el guion embebido en Raccord
            // (protección de contenido, mismo espíritu que la marca de
            // agua). No aplica al PDF ya descargado — eso lo abre una
            // app externa que Raccord no controla. El parámetro correcto
            // en esta versión de pdfrx (2.4.7) es textSelectionParams,
            // no un booleano suelto "enableTextSelection".
            textSelectionParams: const PdfTextSelectionParams(enabled: false),
            loadingBannerBuilder: (context, bytesDownloaded, totalBytes) => const _PdfLoadingView(),
            // Acá es donde antes fallaba en silencio con Syncfusion: si
            // pdfium no puede parsear el archivo (corrupto, encriptado,
            // etc.), este builder muestra el motivo real en pantalla en
            // vez de una vista en blanco.
            errorBannerBuilder: (context, error, stackTrace, documentRef) {
              debugPrint('PdfViewer errorBannerBuilder: $error');
              return ErrorView(
                message: 'No se pudo abrir el PDF: $error',
                onRetry: _loadPdf,
              );
            },
          ),
        );
      },
    );
  }
}

/// Vista previa de la segmentación automática (POST /scripts/{id}/segmentar
/// con confirmar=false ya se llamó antes de abrir este diálogo). Muestra
/// las escenas y personajes detectados y, si la persona confirma, hace
/// la segunda llamada con confirmar=true para crearlas de verdad.
/// Devuelve `true` por Navigator.pop si se llegaron a crear escenas.
class _SegmentPreviewDialog extends StatefulWidget {
  final String idGuion;
  final Map<String, dynamic> preview;
  const _SegmentPreviewDialog({required this.idGuion, required this.preview});

  @override
  State<_SegmentPreviewDialog> createState() => _SegmentPreviewDialogState();
}

class _SegmentPreviewDialogState extends State<_SegmentPreviewDialog> {
  bool _confirmando = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final escenas = (widget.preview['escenas'] as List? ?? []).cast<Map<String, dynamic>>();
    final personajes = (widget.preview['personajes_detectados'] as List? ?? []).cast<String>();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Segmentar guion en escenas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                'Se detectaron ${escenas.length} escena(s). Revisa y confirma para crearlas en el módulo de Escenas.',
                style: const TextStyle(color: AppColors.grisMedio, fontSize: 13),
              ),
              if (personajes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Personajes detectados en todo el guion (${personajes.length}):', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: personajes.map((p) => Chip(label: Text(p, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: escenas.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = escenas[i];
                    final personajesEscena = (e['personajes_detectados'] as List? ?? []).cast<String>();
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(radius: 14, backgroundColor: AppColors.surfaceVariant, child: Text('${e['numero_de_escena']}', style: const TextStyle(fontSize: 11))),
                      title: Text(e['encabezado']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                      subtitle: personajesEscena.isEmpty ? null : Text(personajesEscena.join(', '), style: const TextStyle(fontSize: 11, color: AppColors.grisMedio)),
                    );
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _confirmando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _confirmando ? null : _confirmar,
                    child: _confirmando
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Confirmar y crear ${escenas.length} escena(s)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    setState(() {
      _confirmando = true;
      _error = null;
    });
    final session = context.read<AuthSession>();

    try {
      final resultado = await ScriptService(session.api).segmentar(widget.idGuion, confirmar: true);
      if (mounted) Navigator.of(context).pop(resultado);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }
}

/// Spinner + texto mientras se descarga el PDF del guión (puede tardar
/// unos segundos según el tamaño del archivo).
class _PdfLoadingView extends StatelessWidget {
  const _PdfLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.azulProfundo),
          SizedBox(height: 16),
          Text('Cargando guión…', style: TextStyle(color: AppColors.grisMedio)),
        ],
      ),
    );
  }
}

class _ScriptFormSheet extends StatefulWidget {
  const _ScriptFormSheet();

  @override
  State<_ScriptFormSheet> createState() => _ScriptFormSheetState();
}

class _ScriptFormSheetState extends State<_ScriptFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _version = TextEditingController();
  final _descripcion = TextEditingController();
  String _estado = kEstadosGuion.first;
  PlatformFile? _pdf;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Este formulario es el más largo de los "form sheet" (nombre +
      // estado/versión + selector de PDF + descripción): sin scroll
      // propio, con el teclado abierto en móvil desborda con facilidad
      // dentro del maxHeight fijo del diálogo — ver auditoría de
      // responsive.
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Subir Guión', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            AppTextField(label: 'Nombre del Guión', hint: 'Ej: El Último Amanecer - Versión Final', controller: _nombre, validator: _req),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Estado',
                    value: _estado,
                    items: kEstadosGuion,
                    labelBuilder: (e) => e,
                    onChanged: (v) => setState(() => _estado = v ?? _estado),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(label: 'Versión', hint: 'v1.0', controller: _version, validator: _req),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Archivo PDF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickPdf,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(_pdf?.name ?? 'Seleccionar PDF', overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Descripción', hint: 'Notas sobre esta versión', controller: _descripcion, maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _pickPdf() async {
    final file = await pickPdfFile();
    if (file != null) setState(() => _pdf = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final session = context.read<AuthSession>();
    final service = ScriptService(session.api);

    try {
      final created = await service.create(Script(
        numeroDeVersion: _version.text.trim(),
        fechaDeEmision: DateTime.now(),
        estado: _estado,
        archivo: '',
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        idProject: session.projectId,
      ));

      final pdf = _pdf;
      if (pdf != null && created.idGuion != null) {
        await service.uploadArchivo(created.idGuion!, bytes: await pdf.readAsBytes(), filename: pdf.name);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
