import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/bulk_import.dart';
import '../../core/session.dart';
import '../../models/character.dart';
import '../../services/character_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/bulk_upload_button.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import 'actor_form_screen.dart';

/// Catálogo de Actores. Reutiliza `ActorFormScreen` (ficha técnica
/// completa, ya existente) para crear Y editar — tocar una fila abre
/// la ficha ya cargada (antes esta pantalla solo permitía crear,
/// nunca volver a abrir un actor guardado). Acá solo se listan los
/// campos más importantes del actor: nombre, género, nacionalidad y
/// si es doble de riesgo.
class ActorsScreen extends StatefulWidget {
  const ActorsScreen({super.key});

  @override
  State<ActorsScreen> createState() => _ActorsScreenState();
}

class _ActorsScreenState extends State<ActorsScreen> {
  late Future<List<ActorModel>> _future;
  // Búsqueda por nombre/apellido + paginación — pedido explícito del
  // usuario (2026-09-04), mismo patrón/widget que Personajes y Crew
  // List (ver PaginationBar).
  String _query = '';
  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ActorModel>> _load() {
    final session = context.read<AuthSession>();
    return ActorService(session.api).all(session.projectId ?? '');
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
    final canManage = session.can('create_characters');

    return AppScaffold(
      title: 'Actores',
      showBack: true,
      actions: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: BulkUploadButton(onRows: _bulkCreate, onDone: _reload),
          ),
      ],
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).pushNamed('/actor-form');
                _reload();
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Actor'),
            )
          : null,
      body: FutureBuilder<List<ActorModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: 'No se pudieron cargar los actores.', onRetry: _reload);
          final all = snap.data ?? [];
          if (all.isEmpty) {
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [EmptyView(message: 'Todavía no hay actores creados.', icon: Icons.theater_comedy_outlined)],
              ),
            );
          }

          final filtered = _query.isEmpty
              ? all
              : all.where((a) => '${a.nombre} ${a.apellido}'.toLowerCase().contains(_query.toLowerCase())).toList();
          final totalPages = filtered.isEmpty ? 1 : ((filtered.length - 1) ~/ _pageSize) + 1;
          final page = _page.clamp(0, totalPages - 1);
          final start = page * _pageSize;
          final pageItems = filtered.skip(start).take(_pageSize).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar por nombre o apellido del actor...',
                  ),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _page = 0;
                  }),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyView(
                          message: all.isEmpty ? 'Todavía no hay actores creados.' : 'Sin resultados.',
                          icon: all.isEmpty ? Icons.theater_comedy_outlined : Icons.search_off,
                        )
                      : MobileRefresh(
                          onRefresh: _onPullRefresh,
                          child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final a = pageItems[i];
                            final edad = _edad(a.fechaDeNacimiento);
                            // Cualquiera de estos 3 puede faltar ahora que solo
                            // nombre/apellido son obligatorios (ver ActorModel) — se
                            // arma el subtítulo solo con lo que sí hay, en vez de
                            // interpolar "null" cuando falta un dato.
                            final subtitulo = [
                              a.genero,
                              if (edad != null) '$edad años',
                              if (a.nacionalidad != null && a.nacionalidad!.isNotEmpty) a.nacionalidad!,
                            ].join(' · ');
                            return Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openEdit(a),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      // Foto "normal" del actor (no la
                                      // caracterizada en personaje) al mismo
                                      // tamaño usado en Personajes — pedido
                                      // explícito del usuario (2026-09-04).
                                      _ActorPhotoAvatar(actor: a),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${a.nombre} ${a.apellido}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 2),
                                            Text(
                                              subtitulo,
                                              style: const TextStyle(color: AppColors.grisMedio, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (a.dobleRiesgo)
                                        const Tooltip(
                                          message: 'Doble de riesgo',
                                          child: Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                                        ),
                                      if (canManage && a.idActor != null)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                          tooltip: 'Eliminar',
                                          onPressed: () => _delete(a),
                                        ),
                                    ],
                                  ),
                                ),
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
                    itemLabel: 'actor(es)',
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

  Future<void> _openEdit(ActorModel a) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActorFormScreen(existing: a)),
    );
    _reload();
  }

  // Nullable: la fecha de nacimiento ya no es obligatoria (ver
  // ActorModel) — un actor puede quedar guardado sin ella mientras se
  // completa el resto de la ficha técnica.
  int? _edad(DateTime? nacimiento) {
    if (nacimiento == null) return null;
    final now = DateTime.now();
    int edad = now.year - nacimiento.year;
    if (now.month < nacimiento.month || (now.month == nacimiento.month && now.day < nacimiento.day)) {
      edad--;
    }
    return edad;
  }

  Future<void> _delete(ActorModel a) async {
    final idActor = a.idActor;
    if (idActor == null) return;

    final confirmed = await confirmDelete(
      context,
      message: '¿Eliminar al actor "${a.nombreCompleto}"? Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;

    final session = context.read<AuthSession>();
    try {
      await ActorService(session.api).delete(idActor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Actor eliminado')));
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ==========================================
  // CARGA MASIVA
  // ==========================================
  // Columnas esperadas (obligatorias): nombre, apellido, genero,
  // fecha_de_nacimiento (yyyy-mm-dd), talla_zapatos, ancho_espalda,
  // pecho, cintura, cadera, largo_manga, largo_pierna, color_cabello,
  // textura_cabello, tipo_piel, color_ojos, nacionalidad, doble_riesgo
  // (si/no, true/false, 1/0). Opcionales: talla_anillo, contorno_cabeza,
  // contorno_cuello, alergias, habilidades_especiales, restricciones,
  // comentarios_adicionales, id_personaje, cedula, direccion, telefono,
  // correo, status_confirmacion, llamados, fechas_tentativas,
  // guion_enviado (si/no), ensayos, categoria_cast.
  Future<List<BulkRowResult>> _bulkCreate(List<Map<String, String>> rows) async {
    final session = context.read<AuthSession>();
    final service = ActorService(session.api);
    final results = <BulkRowResult>[];

    var fila = 1;
    for (final row in rows) {
      fila++;

      final nombre = _pick(row, ['nombre']);
      final apellido = _pick(row, ['apellido']);
      final generoTexto = _pick(row, ['genero', 'género']);
      final fechaTexto = _pick(row, ['fecha_de_nacimiento', 'fecha_nacimiento', 'fecha de nacimiento']);
      final tallaZapatos = _pick(row, ['talla_zapatos', 'talla de zapatos']);
      final anchoEspalda = _pick(row, ['ancho_espalda']);
      final pecho = _pick(row, ['pecho']);
      final cintura = _pick(row, ['cintura']);
      final cadera = _pick(row, ['cadera']);
      final largoManga = _pick(row, ['largo_manga']);
      final largoPierna = _pick(row, ['largo_pierna']);
      final colorCabello = _pick(row, ['color_cabello']);
      final texturaCabello = _pick(row, ['textura_cabello']);
      final tipoPiel = _pick(row, ['tipo_piel']);
      final colorOjos = _pick(row, ['color_ojos']);
      final nacionalidad = _pick(row, ['nacionalidad']);
      final dobleRiesgoTexto = _pick(row, ['doble_riesgo']);

      final faltantes = <String>[];
      if (nombre == null) faltantes.add('nombre');
      if (apellido == null) faltantes.add('apellido');
      if (generoTexto == null) faltantes.add('genero');
      if (fechaTexto == null) faltantes.add('fecha_de_nacimiento');
      if (tallaZapatos == null) faltantes.add('talla_zapatos');
      if (anchoEspalda == null) faltantes.add('ancho_espalda');
      if (pecho == null) faltantes.add('pecho');
      if (cintura == null) faltantes.add('cintura');
      if (cadera == null) faltantes.add('cadera');
      if (largoManga == null) faltantes.add('largo_manga');
      if (largoPierna == null) faltantes.add('largo_pierna');
      if (colorCabello == null) faltantes.add('color_cabello');
      if (texturaCabello == null) faltantes.add('textura_cabello');
      if (tipoPiel == null) faltantes.add('tipo_piel');
      if (colorOjos == null) faltantes.add('color_ojos');
      if (nacionalidad == null) faltantes.add('nacionalidad');

      if (faltantes.isNotEmpty) {
        results.add(BulkRowResult(fila: fila, ok: false, detalle: 'Faltan columnas: ${faltantes.join(', ')}'));
        continue;
      }

      final genero = _normalizarGenero(generoTexto!);
      if (genero == null) {
        results.add(BulkRowResult(
          fila: fila,
          ok: false,
          detalle: 'Género inválido "$generoTexto" (use: ${kGenerosActor.join(', ')})',
        ));
        continue;
      }

      final fechaNacimiento = DateTime.tryParse(fechaTexto!);
      if (fechaNacimiento == null) {
        results.add(BulkRowResult(fila: fila, ok: false, detalle: 'fecha_de_nacimiento inválida "$fechaTexto" (use yyyy-mm-dd)'));
        continue;
      }

      final dobleRiesgo = _parseBool(dobleRiesgoTexto);

      try {
        await service.create(ActorModel(
          nombre: nombre!,
          apellido: apellido!,
          genero: genero,
          fechaDeNacimiento: fechaNacimiento,
          tallaZapatos: tallaZapatos!,
          anchoEspalda: anchoEspalda!,
          pecho: pecho!,
          cintura: cintura!,
          cadera: cadera!,
          largoManga: largoManga!,
          largoPierna: largoPierna!,
          tallaAnillo: _pick(row, ['talla_anillo']),
          contornoCabeza: _pick(row, ['contorno_cabeza']),
          contornoCuello: _pick(row, ['contorno_cuello']),
          colorCabello: colorCabello!,
          texturaCabello: texturaCabello!,
          tipoPiel: tipoPiel!,
          colorOjos: colorOjos!,
          alergias: _pick(row, ['alergias']),
          habilidadesEspeciales: _pick(row, ['habilidades_especiales']),
          restricciones: _pick(row, ['restricciones']),
          comentariosAdicionales: _pick(row, ['comentarios_adicionales']),
          nacionalidad: nacionalidad!,
          dobleRiesgo: dobleRiesgo,
          idPersonaje: _pick(row, ['id_personaje']),
          idProject: session.projectId,
          cedula: _pick(row, ['cedula', 'cédula']),
          direccion: _pick(row, ['direccion', 'dirección']),
          telefono: _pick(row, ['telefono', 'teléfono']),
          correo: _pick(row, ['correo', 'email', 'mail']),
          statusConfirmacion: _pick(row, ['status_confirmacion']),
          llamados: _pick(row, ['llamados']),
          fechasTentativas: _pick(row, ['fechas_tentativas']),
          guionEnviado: _pick(row, ['guion_enviado']) != null ? _parseBool(_pick(row, ['guion_enviado'])) : null,
          ensayos: _pick(row, ['ensayos']),
          categoriaCast: _pick(row, ['categoria_cast']),
        ));
        results.add(BulkRowResult(fila: fila, ok: true, detalle: 'Creado correctamente'));
      } on ApiException catch (e) {
        results.add(BulkRowResult(fila: fila, ok: false, detalle: e.message));
      } catch (e) {
        results.add(BulkRowResult(fila: fila, ok: false, detalle: e.toString()));
      }
    }

    return results;
  }

  String? _pick(Map<String, String> row, List<String> posiblesLlaves) {
    for (final key in posiblesLlaves) {
      final value = row[key];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  String? _normalizarGenero(String texto) {
    final t = texto.trim().toLowerCase();
    for (final g in kGenerosActor) {
      if (g == t) return g;
    }
    // Tolerar el error ortográfico esperado por el backend ("fenemino")
    // y variantes comunes de escritura del usuario.
    if (t == 'femenino' || t == 'fenemino') return 'fenemino';
    if (t == 'masculino') return 'masculino';
    if (t == 'otro') return 'otro';
    return null;
  }

  bool _parseBool(String? texto) {
    if (texto == null) return false;
    final t = texto.trim().toLowerCase();
    return t == 'si' || t == 'sí' || t == 'true' || t == '1' || t == 'yes';
  }
}

/// Foto "normal" del actor (no la caracterizada en personaje) al mismo
/// tamaño (44px) usado en la lista de Personajes — pedido explícito del
/// usuario (2026-09-04). Si el actor todavía no tiene esa foto, cae a
/// sus iniciales en vez de dejar el círculo en blanco.
class _ActorPhotoAvatar extends StatelessWidget {
  final ActorModel actor;
  final double size;
  const _ActorPhotoAvatar({required this.actor, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final idActor = actor.idActor;
    final session = context.read<AuthSession>();

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
      ),
      child: idActor == null
          ? _placeholder()
          : FutureBuilder<List<int>>(
              future: ActorService(session.api).fotoNormalBytes(idActor),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                  );
                }
                if (!snap.hasData || snap.data == null) return _placeholder();
                return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: size, height: size);
              },
            ),
    );
  }

  Widget _placeholder() => Center(
        child: Text(
          actor.nombre.isNotEmpty ? actor.nombre[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
}
