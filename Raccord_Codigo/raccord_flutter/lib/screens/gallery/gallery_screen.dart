import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../core/watermark.dart';
import '../../models/gallery_photo.dart';
import '../../services/gallery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/photo_viewer_dialog.dart';
import '../../widgets/state_views.dart';

/// Cuántas fotos se pueden elegir a la vez para descargar (barra
/// "Seleccionar" de la Galería) — pedido explícito del usuario
/// (2026-09-09): cada foto se descarga por separado (sin .zip, se veía
/// mal en el navegador del celular), así que hay que ponerle un techo
/// razonable para no disparar 40 descargas de una.
const kMaxDescargaSeleccion = 10;

/// Galería global del proyecto (mockups 9, 9.1, 9.2, 9.3, 12, 15):
/// todas las fotos de continuidad de todas las escenas. Reutiliza
/// GET /fotos (ver GalleryService.all()) y el visor compartido
/// (widgets/photo_viewer_dialog.dart).
///
/// Agrupado en dos niveles — Día dramático > Escena (pedido explícito
/// del usuario 2026-09-08) — con un panel lateral a la derecha, estilo
/// Google Photos, que salta entre los días dramáticos que tengan fotos.
/// También soporta selección múltiple + descarga (una descarga del
/// navegador por foto, hasta [kMaxDescargaSeleccion] a la vez).
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<List<GalleryPhoto>> _future;
  final _busqueda = TextEditingController();
  final _scrollController = ScrollController();

  // Selección múltiple + descarga (barra "Seleccionar").
  bool _seleccionando = false;
  final Set<String> _seleccionadas = {};
  bool _descargando = false;

  // Panel lateral de día dramático: qué sección está actualmente visible
  // (se resalta en el panel) y las llaves para saltar con
  // Scrollable.ensureVisible. Las llaves se recrean solo si hace falta
  // (putIfAbsent en build), así sobreviven entre reconstrucciones.
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _activeKey;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _busqueda.addListener(() => setState(() {}));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<GalleryPhoto>> _load() {
    final session = context.read<AuthSession>();
    return GalleryService(session.api).all(session.projectId ?? '');
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

  /// Extrae el número inicial de "numeroDeEscena" (ej. "3", "3A") para
  /// ordenar los grupos numéricamente en vez de alfabéticamente (donde
  /// "10" quedaría antes que "2").
  int _numeroOrden(String? numero) {
    final match = RegExp(r'\d+').firstMatch(numero ?? '');
    return match != null ? int.parse(match.group(0)!) : 1 << 30;
  }

  // 'sin_dia' para las escenas sin día dramático asignado — van al
  // final, después de todos los días numerados.
  String _dayKey(int? dia) => dia == null ? 'sin_dia' : 'dia_$dia';
  String _dayLabel(int? dia) => dia == null ? 'Sin día asignado' : 'Día $dia';

  // Recalcula, tras cada scroll, cuál sección ocupa la parte de arriba
  // de la pantalla — esa es la que se resalta en el panel lateral.
  void _onScroll() {
    String? activo;
    double mejorTop = double.negativeInfinity;
    for (final entry in _sectionKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      // Nos quedamos con la sección visible más "arriba" cuyo borde
      // superior ya pasó (o está cerca de) el techo de la pantalla.
      if (top <= 140 && top > mejorTop) {
        mejorTop = top;
        activo = entry.key;
      }
    }
    if (activo != null && activo != _activeKey) {
      setState(() => _activeKey = activo);
    }
  }

  void _saltarA(String key) {
    final ctx = _sectionKeys[key]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0);
  }

  void _toggleSeleccion(String idFoto) {
    if (_seleccionadas.contains(idFoto)) {
      setState(() => _seleccionadas.remove(idFoto));
      return;
    }
    if (_seleccionadas.length >= kMaxDescargaSeleccion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podés seleccionar hasta $kMaxDescargaSeleccion fotos por descarga.')),
      );
      return;
    }
    setState(() => _seleccionadas.add(idFoto));
  }

  /// Separa "foto.jpg" en ("foto", "jpg") para pasarle nombre y
  /// extensión por separado a FileSaver — si no trae extensión (raro,
  /// pero por si acaso) usamos "jpg" como default razonable.
  (String, String) _splitNombreArchivo(String archivoNombre) {
    final idx = archivoNombre.lastIndexOf('.');
    if (idx <= 0 || idx == archivoNombre.length - 1) return (archivoNombre, 'jpg');
    return (archivoNombre.substring(0, idx), archivoNombre.substring(idx + 1));
  }

  /// Quita caracteres inválidos para nombre de archivo en Windows
  /// (< > : " / \ | ? *) y cambia espacios por guion bajo.
  String _sanitizarNombreArchivo(String texto) {
    return texto.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').replaceAll(RegExp(r'\s+'), '_').trim();
  }

  /// Nombre legible para el archivo descargado: "ESC{n}_{encabezado}_
  /// {tipo}_{consecutivo}" en vez del id interno (llave primaria) que
  /// trae `archivoNombre` — pedido explícito del usuario. `encabezado`
  /// solo viene poblado en la Galería global (GET /fotos); si por algo
  /// faltara, se cae al nombre original tal cual.
  String _nombreParaDescarga(GalleryPhoto foto, int indiceEnLote) {
    final encabezado = foto.encabezadoEscenaOrigen;
    if (encabezado == null || encabezado.isEmpty) {
      return _splitNombreArchivo(foto.archivoNombre).$1;
    }
    final numeroEscena = foto.numeroDeEscenaOrigen;
    final partes = <String>[
      if (numeroEscena != null && numeroEscena.isNotEmpty) 'ESC$numeroEscena',
      _sanitizarNombreArchivo(encabezado),
      foto.tipoFoto,
      '${indiceEnLote + 1}',
    ];
    var nombre = partes.join('_');
    // Margen de sobra respecto al límite práctico de ruta en Windows.
    if (nombre.length > 120) nombre = nombre.substring(0, 120);
    return nombre;
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

  // true en Android/iOS (nunca en Web/Windows, donde no existe una
  // "Galería del sistema" a la que guardar): ahí las fotos se guardan
  // con el paquete "gal" directo en la Galería, en vez del selector
  // "Guardar como" genérico de file_saver (ver _descargarSeleccionadas).
  bool get _guardarEnGaleriaNativa => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Descarga CADA foto seleccionada por separado (una descarga del
  // navegador por foto) — a pedido explícito del usuario, nada de
  // .zip: en el navegador del celular quedaba feo/confuso.
  Future<void> _descargarSeleccionadas(List<GalleryPhoto> todas) async {
    final elegidas = todas.where((p) => _seleccionadas.contains(p.idFoto)).toList();
    if (elegidas.isEmpty) return;

    setState(() => _descargando = true);
    final session = context.read<AuthSession>();
    final service = GalleryService(session.api);
    final marcaAguaTexto = watermarkTextFor(session);
    // En Android/iOS (_guardarEnGaleriaNativa) se guarda directo en la
    // Galería con "gal" — antes se usaba FileSaver.saveAs() ahí también,
    // que abre el selector "Guardar como" genérico: la persona terminaba
    // guardando en "Documentos" (o donde sea que tocara) y la foto nunca
    // aparecía reflejada en la Galería como cualquier otra foto
    // descargada (reporte explícito del usuario). En Web/Windows, donde
    // no existe una "Galería del sistema", se sigue usando saveAs().
    var guardadas = 0;
    try {
      for (var i = 0; i < elegidas.length; i++) {
        final foto = elegidas[i];
        final bytesOriginales = await service.archivoBytes(foto.idFoto);
        final (_, extensionOriginal) = _splitNombreArchivo(foto.archivoNombre);
        final nombre = _nombreParaDescarga(foto, i);

        // Si por lo que sea la marca de agua falla (ej. un archivo que
        // no es una imagen válida), se descarga igual la foto original
        // sin marca, en vez de bloquear la descarga completa.
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
          // Gal.putImageBytes guarda directo en la Galería/Fotos del
          // sistema (álbum "Raccord") — sin selector, sin pasos extra,
          // igual que cualquier otra foto descargada en el celular.
          try {
            await Gal.putImageBytes(bytesFinal, name: nombre, album: 'Raccord');
            guardadas++;
          } on GalException catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.type.message)));
          }
        } else {
          final savedPath = await FileSaver.instance.saveAs(
            name: nombre,
            bytes: bytesFinal,
            fileExtension: extension,
            mimeType: _mimeFor(extension),
          );
          if (savedPath != null) guardadas++;
        }
        // Pequeña pausa entre descargas: si se disparan todas de
        // corrido, algunos navegadores bloquean o preguntan por
        // "este sitio quiere descargar varios archivos".
        await Future.delayed(const Duration(milliseconds: 350));
      }

      if (!mounted) return;
      setState(() {
        _descargando = false;
        _seleccionando = false;
        _seleccionadas.clear();
      });
      if (guardadas > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(guardadas == 1 ? 'Foto guardada correctamente' : '$guardadas fotos guardadas correctamente')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _descargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudieron descargar las fotos: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    // Separado de upload_photos a pedido explícito: Onset puede subir
    // fotos de continuidad, pero no eliminarlas.
    final canDelete = session.can('delete_photos');
    // Editar detalles en el visor reutiliza el mismo permiso que subir.
    final canEdit = session.can('upload_photos');

    return AppScaffold(
      title: 'Galería',
      showBack: true,
      body: FutureBuilder<List<GalleryPhoto>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: 'No se pudieron cargar las fotos.', onRetry: _reload);

          final todas = snap.data ?? [];
          if (todas.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  EmptyView(
                    message: 'Todavía no hay fotos de continuidad en ninguna escena.',
                    icon: Icons.photo_library_outlined,
                  ),
                ],
              ),
            );
          }

          final filtro = _busqueda.text.trim().toLowerCase();
          final fotos = filtro.isEmpty
              ? todas
              : todas.where((p) {
                  final campos = [
                    p.numeroDeEscenaOrigen ?? '',
                    p.encabezadoEscenaOrigen ?? '',
                    p.tipoFoto,
                    p.personajeCodigo ?? '',
                    p.descripcion ?? '',
                  ].join(' ').toLowerCase();
                  return campos.contains(filtro);
                }).toList();

          // Nivel 1: agrupar por día dramático (null = sin asignar, va
          // al final). Nivel 2, dentro de cada día: agrupar por escena.
          final porDia = <int?, List<GalleryPhoto>>{};
          for (final foto in fotos) {
            porDia.putIfAbsent(foto.diaDramaticoOrigen, () => []).add(foto);
          }
          final dias = porDia.keys.toList()
            ..sort((a, b) {
              if (a == null && b == null) return 0;
              if (a == null) return 1;
              if (b == null) return -1;
              return a.compareTo(b);
            });

          // Arma, por cada día, el sub-agrupado por escena YA ordenado,
          // y de paso una lista plana en ese mismo orden visual + un
          // índice por foto — es lo que habilita las flechas
          // anterior/siguiente del visor a recorrer TODA la galería
          // filtrada, no solo el grupo de la escena tocada.
          final gruposPorDia = <int?, Map<String, List<GalleryPhoto>>>{};
          final ordenVisual = <GalleryPhoto>[];
          for (final dia in dias) {
            final porEscena = <String, List<GalleryPhoto>>{};
            for (final foto in porDia[dia]!) {
              porEscena.putIfAbsent(foto.idEscena, () => []).add(foto);
            }
            final escenas = porEscena.keys.toList()
              ..sort((a, b) => _numeroOrden(porEscena[a]!.first.numeroDeEscenaOrigen)
                  .compareTo(_numeroOrden(porEscena[b]!.first.numeroDeEscenaOrigen)));
            final ordenado = <String, List<GalleryPhoto>>{};
            for (final esc in escenas) {
              ordenado[esc] = porEscena[esc]!;
              ordenVisual.addAll(porEscena[esc]!);
            }
            gruposPorDia[dia] = ordenado;
            _sectionKeys.putIfAbsent(_dayKey(dia), () => GlobalKey());
          }
          final indiceEnOrden = <GalleryPhoto, int>{
            for (var i = 0; i < ordenVisual.length; i++) ordenVisual[i]: i,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Buscar',
                      hint: 'Por escena, encabezado, tipo de foto o personaje...',
                      controller: _busqueda,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${fotos.length} foto(s)', style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                  const SizedBox(width: 12),
                  if (!_seleccionando)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _seleccionando = true),
                      icon: const Icon(Icons.checklist, size: 18),
                      label: const Text('Seleccionar'),
                    )
                  else ...[
                    Text('${_seleccionadas.length}/$kMaxDescargaSeleccion seleccionada(s)',
                        style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _descargando
                          ? null
                          : () => setState(() {
                                _seleccionando = false;
                                _seleccionadas.clear();
                              }),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.azulProfundo),
                      onPressed: (_descargando || _seleccionadas.isEmpty) ? null : () => _descargarSeleccionadas(fotos),
                      icon: _descargando
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download, size: 18),
                      label: Text(_descargando ? 'Descargando...' : 'Descargar'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: fotos.isEmpty
                    ? MobileRefresh(
                        onRefresh: _onPullRefresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            EmptyView(message: 'Ninguna foto coincide con la búsqueda.', icon: Icons.search_off),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: MobileRefresh(
                              onRefresh: _onPullRefresh,
                              child: SingleChildScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final dia in dias)
                                    Padding(
                                      key: _sectionKeys[_dayKey(dia)],
                                      padding: const EdgeInsets.only(bottom: 28),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _dayLabel(dia),
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                          ),
                                          const Divider(height: 20),
                                          for (final entry in gruposPorDia[dia]!.entries)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          // Solo el encabezado, sin "ESC N ·" — pedido
                                                          // explícito del usuario, mismo criterio ya
                                                          // aplicado en Escenas y Continuidad Visual.
                                                          entry.value.first.encabezadoEscenaOrigen ?? 'Escena',
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                        ),
                                                      ),
                                                      Text('(${entry.value.length})',
                                                          style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  GridView.builder(
                                                    shrinkWrap: true,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    itemCount: entry.value.length,
                                                    // `MaxCrossAxisExtent` en vez de un
                                                    // `crossAxisCount` fijo: calcula cuántas
                                                    // miniaturas caben según el ancho real
                                                    // (menos columnas en móvil angosto, más
                                                    // en tablet/desktop), en vez de siempre 4.
                                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                                      maxCrossAxisExtent: 130,
                                                      crossAxisSpacing: 8,
                                                      mainAxisSpacing: 8,
                                                    ),
                                                    itemBuilder: (context, j) {
                                                      final foto = entry.value[j];
                                                      return _GalleryPhotoThumb(
                                                        photo: foto,
                                                        allPhotos: ordenVisual,
                                                        index: indiceEnOrden[foto] ?? 0,
                                                        canEdit: canEdit,
                                                        canDelete: canDelete,
                                                        onDeleted: _reload,
                                                        onUpdated: _reload,
                                                        seleccionando: _seleccionando,
                                                        seleccionada: _seleccionadas.contains(foto.idFoto),
                                                        onToggleSeleccion: () => _toggleSeleccion(foto.idFoto),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ),
                          ),
                          if (dias.length > 1) ...[
                            const SizedBox(width: 4),
                            _DiaDramaticoSidebar(
                              dias: dias,
                              dayKeyOf: _dayKey,
                              dayLabelOf: _dayLabel,
                              activeKey: _activeKey,
                              onTap: _saltarA,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Panel lateral estilo Google Photos (años/meses), pero con días
/// dramáticos: lista fija a la derecha con un ítem por día dramático
/// presente en la galería filtrada; tocar uno hace scroll hasta esa
/// sección. El día que ocupa la parte de arriba de la pantalla en este
/// momento se resalta.
class _DiaDramaticoSidebar extends StatelessWidget {
  final List<int?> dias;
  final String Function(int?) dayKeyOf;
  final String Function(int?) dayLabelOf;
  final String? activeKey;
  final void Function(String key) onTap;

  const _DiaDramaticoSidebar({
    required this.dias,
    required this.dayKeyOf,
    required this.dayLabelOf,
    required this.activeKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [for (final dia in dias) _item(context, dia)],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int? dia) {
    final key = dayKeyOf(dia);
    final activo = key == activeKey;
    return InkWell(
      onTap: () => onTap(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: activo ? AppColors.azulProfundo : Colors.transparent, width: 2)),
        ),
        child: Text(
          dayLabelOf(dia),
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
            color: activo ? AppColors.azulProfundo : AppColors.grisMedio,
          ),
        ),
      ),
    );
  }
}

/// Miniatura + visor. A diferencia de los otros dos lugares donde
/// aparecen fotos de continuidad (Fotos de Escena, Continuidad Visual),
/// acá la foto puede ser de cualquier escena del proyecto, y además
/// soporta el modo selección múltiple (checkbox en vez de abrir el
/// visor al tocar).
class _GalleryPhotoThumb extends StatelessWidget {
  final GalleryPhoto photo;
  final List<GalleryPhoto> allPhotos;
  final int index;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onDeleted;
  final VoidCallback onUpdated;
  final bool seleccionando;
  final bool seleccionada;
  final VoidCallback onToggleSeleccion;

  const _GalleryPhotoThumb({
    required this.photo,
    required this.allPhotos,
    required this.index,
    required this.canEdit,
    required this.canDelete,
    required this.onDeleted,
    required this.onUpdated,
    required this.seleccionando,
    required this.seleccionada,
    required this.onToggleSeleccion,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: seleccionando ? onToggleSeleccion : () => _openViewer(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: AppColors.surfaceVariant,
                foregroundDecoration: seleccionada
                    ? BoxDecoration(color: AppColors.azulProfundo.withOpacity(0.35), borderRadius: BorderRadius.circular(8))
                    : null,
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
        if (seleccionando)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: seleccionada ? AppColors.azulProfundo : Colors.black45,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: seleccionada ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ),
        if (canDelete && !seleccionando)
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
    // Desde 2026-09-23 esto es un soft-delete: la foto se mueve a la
    // Papelera de Reciclaje (recycle_bin_screen.dart), no se borra para
    // siempre — solo Jefe de Departamento o Director pueden restaurarla
    // o eliminarla definitivamente ahí.
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
      etiquetaEscena: photo.encabezadoEscenaOrigen,
    );
  }
}
