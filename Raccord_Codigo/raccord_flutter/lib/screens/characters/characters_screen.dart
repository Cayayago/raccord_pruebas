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
import '../../widgets/app_text_field.dart';
import '../../widgets/bulk_upload_button.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import 'actor_form_screen.dart';

/// Mockup 14: Crear Personaje. Actor (ficha técnica completa) se
/// gestiona aparte por lo extenso del formulario (ActorSchema).
class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  late Future<_CharactersData> _future;
  // Búsqueda por nombre del personaje + paginación — pedido explícito
  // del usuario (2026-09-02), mismo patrón/widget que Escenas y Plan de
  // Rodaje (ver PaginationBar).
  String _query = '';
  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  // Trae personajes + actores del proyecto en paralelo (una sola vez, no
  // por fila) y agrupa los actores por id_personaje — así cada fila
  // puede mostrar la(s) foto(s) del actor asociado sin una llamada N+1
  // por personaje. Pedido explícito del usuario (2026-09-03): ver la
  // foto del actor (o una por actor, si hay varios relacionados) junto
  // a cada personaje en la lista.
  Future<_CharactersData> _load() async {
    final session = context.read<AuthSession>();
    final idProject = session.projectId ?? '';
    final results = await Future.wait([
      CharacterService(session.api).all(idProject),
      ActorService(session.api).all(idProject),
    ]);
    final personajes = results[0] as List<CharacterModel>;
    final actores = results[1] as List<ActorModel>;

    final porPersonaje = <String, List<ActorModel>>{};
    for (final actor in actores) {
      final id = actor.idPersonaje;
      if (id != null && id.isNotEmpty) {
        porPersonaje.putIfAbsent(id, () => []).add(actor);
      }
    }
    return _CharactersData(personajes, porPersonaje);
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
      title: 'Personajes',
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
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear Personaje'),
            )
          : null,
      body: FutureBuilder<_CharactersData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snap.hasError) return ErrorView(message: 'No se pudieron cargar los personajes.', onRetry: _reload);
          final all = snap.data?.personajes ?? [];
          final actoresPorPersonaje = snap.data?.actoresPorPersonaje ?? const {};
          if (all.isEmpty) {
            // Envuelto en un ListView (con AlwaysScrollableScrollPhysics)
            // solo para que el gesto de "deslizar para recargar" funcione
            // incluso cuando todavía no hay ningún personaje creado.
            return MobileRefresh(
              onRefresh: _onPullRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [EmptyView(message: 'Todavía no hay personajes creados.', icon: Icons.theater_comedy_outlined)],
              ),
            );
          }

          final filtered = _query.isEmpty
              ? all
              : all.where((c) => c.nombre.toLowerCase().contains(_query.toLowerCase())).toList();
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
                    hintText: 'Buscar por nombre del personaje...',
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
                          message: all.isEmpty ? 'Todavía no hay personajes creados.' : 'Sin resultados.',
                          icon: all.isEmpty ? Icons.theater_comedy_outlined : Icons.search_off,
                        )
                      : MobileRefresh(
                          onRefresh: _onPullRefresh,
                          child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final c = pageItems[i];
                            final actoresDelPersonaje = c.idPersonaje != null
                                ? (actoresPorPersonaje[c.idPersonaje] ?? const <ActorModel>[])
                                : const <ActorModel>[];
                            return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: canManage ? () => _openForm(context, existing: c) : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: Text(c.codigoPersonaje)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${c.edad} años', style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
                            ],
                          ),
                        ),
                        // Foto(s) del/los actor(es) relacionados con este
                        // personaje — 1 avatar por actor si hay varios
                        // (doble, suplente, etapas de edad...), a la
                        // derecha de la fila y con click a la ficha
                        // técnica del actor. Pedido explícito del usuario
                        // (2026-09-03/04).
                        if (actoresDelPersonaje.isNotEmpty) ...[
                          _ActorAvatarStack(actores: actoresDelPersonaje),
                          const SizedBox(width: 8),
                        ],
                        if (c.idPersonaje != null)
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_outlined),
                            tooltip: 'Ficha técnica del actor',
                            onPressed: () => Navigator.of(context).pushNamed('/actor-form', arguments: c.idPersonaje),
                          ),
                        if (canManage && c.idPersonaje != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            tooltip: 'Eliminar',
                            onPressed: () => _delete(c),
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
                    itemLabel: 'personaje(s)',
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

  Future<void> _openForm(BuildContext context, {CharacterModel? existing}) async {
    final saved = await showCenteredFormSheet<bool>(
      context,
      _CharacterFormSheet(existing: existing),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(CharacterModel c) async {
    final idPersonaje = c.idPersonaje;
    if (idPersonaje == null) return;

    final confirmed = await confirmDelete(
      context,
      message: '¿Eliminar el personaje "${c.nombre}"? Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;

    final session = context.read<AuthSession>();
    try {
      await CharacterService(session.api).delete(idPersonaje);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personaje eliminado')));
      }
      _reload();
    } on ApiException catch (e) {
      // Ej. "CHARACTER_HAS_ACTORS" si todavía tiene actores asignados.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ==========================================
  // CARGA MASIVA
  // ==========================================
  // Columnas esperadas: codigo (o codigo_personaje), nombre, edad.
  // Las 3 son obligatorias (ver CharacterModel.toCreateJson).
  Future<List<BulkRowResult>> _bulkCreate(List<Map<String, String>> rows) async {
    final session = context.read<AuthSession>();
    final service = CharacterService(session.api);
    final results = <BulkRowResult>[];

    var fila = 1;
    for (final row in rows) {
      fila++;
      final codigo = _pick(row, ['codigo_personaje', 'codigo', 'código']);
      final nombre = _pick(row, ['nombre']);
      final edadTexto = _pick(row, ['edad']);
      final edad = edadTexto != null ? int.tryParse(edadTexto) : null;

      if (codigo == null || nombre == null || edad == null) {
        results.add(BulkRowResult(fila: fila, ok: false, detalle: 'Faltan columnas requeridas (codigo, nombre, edad)'));
        continue;
      }

      try {
        await service.create(CharacterModel(
          nombre: nombre,
          edad: edad,
          codigoPersonaje: codigo,
          idProject: session.projectId,
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
}

class _CharacterFormSheet extends StatefulWidget {
  final CharacterModel? existing;
  const _CharacterFormSheet({this.existing});

  @override
  State<_CharacterFormSheet> createState() => _CharacterFormSheetState();
}

class _CharacterFormSheetState extends State<_CharacterFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _codigo = TextEditingController(text: widget.existing?.codigoPersonaje ?? '');
  late final _nombre = TextEditingController(text: widget.existing?.nombre ?? '');
  late final _edad = TextEditingController(text: widget.existing != null ? '${widget.existing!.edad}' : '');
  bool _loading = false;

  bool get _isEditing => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Evita overflow con el teclado abierto en móvil (el diálogo tiene
      // maxHeight fijo) — ver auditoría de responsive.
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? 'Editar Personaje' : 'Crear Personaje', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            AppTextField(label: 'Código del Personaje', hint: 'Ej: P001, P002', controller: _codigo, validator: _req),
            const SizedBox(height: 16),
            AppTextField(label: 'Nombre del Personaje', hint: 'Nombre del personaje', controller: _nombre, validator: _req),
            const SizedBox(height: 16),
            AppTextField(label: 'Edad', hint: 'Edad del personaje', controller: _edad, keyboardType: TextInputType.number, validator: _req),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Guardar cambios' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final session = context.read<AuthSession>();

    try {
      final existing = widget.existing;
      if (existing != null && existing.idPersonaje != null) {
        await CharacterService(session.api).update(existing.idPersonaje!, {
          'nombre': _nombre.text.trim(),
          'edad': int.tryParse(_edad.text.trim()) ?? 0,
          'codigo_personaje': _codigo.text.trim(),
        });
      } else {
        await CharacterService(session.api).create(CharacterModel(
          nombre: _nombre.text.trim(),
          edad: int.tryParse(_edad.text.trim()) ?? 0,
          codigoPersonaje: _codigo.text.trim(),
          idProject: session.projectId,
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ==========================================
// FOTOS DE ACTOR EN LA LISTA DE PERSONAJES
// ==========================================
// Agrupa personajes + actores cargados en _load() — ver comentario ahí.
class _CharactersData {
  final List<CharacterModel> personajes;
  final Map<String, List<ActorModel>> actoresPorPersonaje;
  _CharactersData(this.personajes, this.actoresPorPersonaje);
}

/// Fotos pequeñas (una por actor) apiladas con ligero solape, tipo
/// "avatar stack" — pedido explícito del usuario (2026-09-03): si un
/// personaje tiene varios actores relacionados (doble, suplente, etapas
/// de edad distintas...), mostrar 1 foto de cada uno, no solo la
/// primera. Si son más de 3, el resto se resume en un "+N".
class _ActorAvatarStack extends StatelessWidget {
  final List<ActorModel> actores;
  const _ActorAvatarStack({required this.actores});

  // Un poco más grande — pedido explícito del usuario (2026-09-04).
  static const double _size = 44;
  static const double _overlap = 20;

  @override
  Widget build(BuildContext context) {
    final visibles = actores.take(3).toList();
    final restantes = actores.length - visibles.length;
    final slots = visibles.length + (restantes > 0 ? 1 : 0);
    final width = _size + (slots - 1) * _overlap;

    return SizedBox(
      width: width,
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < visibles.length; i++)
            Positioned(
              left: i * _overlap,
              child: _SingleActorAvatar(actor: visibles[i], size: _size),
            ),
          if (restantes > 0)
            Positioned(
              left: visibles.length * _overlap,
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Text('+$restantes', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Una foto de actor: prueba primero la foto "en personaje"
/// (caracterizado) y si el actor no tiene esa, cae a la foto "normal" —
/// mismo criterio que el resto de la ficha; si tampoco tiene ninguna de
/// las dos, un ícono de persona en vez de dejarlo en blanco.
class _SingleActorAvatar extends StatelessWidget {
  final ActorModel actor;
  final double size;
  const _SingleActorAvatar({required this.actor, required this.size});

  Future<List<int>?> _loadBytes(ActorService service, String idActor) async {
    try {
      return await service.fotoPersonajeBytes(idActor);
    } catch (_) {
      try {
        return await service.fotoNormalBytes(idActor);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final idActor = actor.idActor;
    final session = context.read<AuthSession>();

    return Tooltip(
      message: '${actor.nombre} ${actor.apellido}'.trim(),
      child: InkWell(
        // Click en la foto -> ficha técnica de ESE actor (no la de
        // edición del personaje, que ya maneja la fila completa) —
        // pedido explícito del usuario (2026-09-04).
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActorFormScreen(existing: actor)),
        ),
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceVariant,
            border: Border.all(color: AppColors.surface, width: 2),
          ),
          child: idActor == null
              ? _placeholder()
              : FutureBuilder<List<int>?>(
                  future: _loadBytes(ActorService(session.api), idActor),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 1.5)),
                      );
                    }
                    final bytes = snap.data;
                    if (bytes == null) return _placeholder();
                    return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover, width: size, height: size);
                  },
                ),
        ),
      ),
    );
  }

  Widget _placeholder() => Center(child: Icon(Icons.person, size: size * 0.55, color: AppColors.grisMedio));
}
