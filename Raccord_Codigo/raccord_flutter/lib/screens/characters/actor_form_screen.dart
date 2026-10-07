import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../models/character.dart';
import '../../services/character_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';

/// Ficha técnica completa del actor (medidas, continuidad física, y
/// las 2 fotos del actor). No hay mockup específico para esta
/// pantalla; los campos siguen exactamente ActorSchema del backend
/// para que la creación/edición funcione contra la API real.
///
/// Sirve tanto para CREAR (sin [existing]) como para EDITAR (con
/// [existing]) — antes solo se podía crear, nunca volver a abrir un
/// actor ya guardado (ver actors_screen.dart, que ahora sí navega acá
/// con el actor existente al tocar una fila).

/// Valor inicial de un dropdown de catálogo: conserva el valor ya
/// guardado (aunque sea texto libre de antes de este catálogo) o cae
/// al primer valor del catálogo si la ficha es nueva o no tenía nada.
String _catalogDefault(String? existing, List<String> catalog) {
  if (existing != null && existing.isNotEmpty) return existing;
  return catalog.first;
}

// Mismo patrón de selección de origen de foto que scene_edit_screen.dart
// (cámara solo en celular/tablet, archivo/galería siempre disponible).
enum _PhotoSource { camera, files }

class ActorFormScreen extends StatefulWidget {
  final String? idPersonaje;
  final ActorModel? existing;
  const ActorFormScreen({super.key, this.idPersonaje, this.existing});

  @override
  State<ActorFormScreen> createState() => _ActorFormScreenState();
}

class _ActorFormScreenState extends State<ActorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.existing?.nombre ?? '');
  late final _apellido = TextEditingController(text: widget.existing?.apellido ?? '');
  late final _fechaNacimiento = TextEditingController(
    text: widget.existing?.fechaDeNacimiento != null
        ? widget.existing!.fechaDeNacimiento!.toIso8601String().split('T').first
        : '',
  );
  late final _tallaZapatos = TextEditingController(text: widget.existing?.tallaZapatos ?? '');
  late final _anchoEspalda = TextEditingController(text: widget.existing?.anchoEspalda ?? '');
  late final _pecho = TextEditingController(text: widget.existing?.pecho ?? '');
  late final _cintura = TextEditingController(text: widget.existing?.cintura ?? '');
  late final _cadera = TextEditingController(text: widget.existing?.cadera ?? '');
  late final _largoManga = TextEditingController(text: widget.existing?.largoManga ?? '');
  late final _largoPierna = TextEditingController(text: widget.existing?.largoPierna ?? '');
  late final _colorCabello = TextEditingController(text: widget.existing?.colorCabello ?? '');
  // Dropdown de países (ver kPaises en models/character.dart), no texto
  // libre — pedido explícito del usuario (2026-09-04). Nullable porque
  // nacionalidad ya no es obligatoria (ver ActorModel).
  late String? _nacionalidad = widget.existing?.nacionalidad;

  // Maquillaje y caracterización — catálogos en vez de texto libre
  // (pedido explícito del usuario, 2026-09-03). Si la ficha ya tenía un
  // valor guardado que no está en el catálogo actual (texto libre de
  // antes de este cambio), se conserva y se agrega a la lista del
  // dropdown en tiempo de build (ver _catalogWith) en vez de perderse.
  late String _texturaCabello = _catalogDefault(widget.existing?.texturaCabello, kTexturasCabello);
  late String _tipoPiel = _catalogDefault(widget.existing?.tipoPiel, kTiposPiel);
  late String _colorOjos = _catalogDefault(widget.existing?.colorOjos, kColoresOjos);
  late String? _tonoPiel = widget.existing?.tonoPiel;
  late final _alergias = TextEditingController(text: widget.existing?.alergias ?? '');
  late String _genero = widget.existing?.genero ?? kGenerosActor.first;
  late bool _dobleRiesgo = widget.existing?.dobleRiesgo ?? false;
  bool _loading = false;

  // Contacto de producción + seguimiento de casting — pedido explícito
  // del usuario (2026-09-02) al comparar la ficha técnica contra un
  // Cast List real; todos opcionales.
  late final _cedula = TextEditingController(text: widget.existing?.cedula ?? '');
  late final _direccion = TextEditingController(text: widget.existing?.direccion ?? '');
  late final _telefono = TextEditingController(text: widget.existing?.telefono ?? '');
  late final _correo = TextEditingController(text: widget.existing?.correo ?? '');
  late final _llamados = TextEditingController(text: widget.existing?.llamados ?? '');
  late final _fechasTentativas = TextEditingController(text: widget.existing?.fechasTentativas ?? '');
  late final _ensayos = TextEditingController(text: widget.existing?.ensayos ?? '');
  late String? _statusConfirmacion = widget.existing?.statusConfirmacion;
  late String? _categoriaCast = widget.existing?.categoriaCast;
  late bool _guionEnviado = widget.existing?.guionEnviado ?? false;

  // Actor actualmente guardado en el backend — null mientras se está
  // creando uno nuevo. Al guardar por primera vez se reemplaza con lo
  // que devuelve el backend (con su id_actor real), así la pantalla
  // pasa sola a "modo edición" sin cerrarse, y las 2 fotos quedan
  // disponibles para subir de inmediato después de crear.
  ActorModel? _currentActor;

  bool get _isEditing => _currentActor != null;
  String? get _idActor => _currentActor?.idActor;

  // Fotos del actor — pedido explícito del usuario (2026-09-02):
  // "actor en personaje" (caracterizado) y "actor normal". Solo se
  // pueden subir una vez que el actor ya existe (el endpoint necesita
  // un id_actor real), por eso quedan deshabilitadas mientras se está
  // creando uno nuevo.
  Future<List<int>>? _fotoPersonaje;
  Future<List<int>>? _fotoNormal;
  bool _subiendoFotoPersonaje = false;
  bool _subiendoFotoNormal = false;

  @override
  void initState() {
    super.initState();
    _currentActor = widget.existing;
    final idActor = _idActor;
    if (idActor != null) {
      final session = context.read<AuthSession>();
      _fotoPersonaje = ActorService(session.api).fotoPersonajeBytes(idActor);
      _fotoNormal = ActorService(session.api).fotoNormalBytes(idActor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Editar ficha técnica' : 'Ficha técnica del actor',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rediseño pedido explícito del usuario (2026-09-04): "se
              // ve mucha información y se asustan" — solo lo esencial
              // (fotos + nombre/apellido + un par de datos básicos)
              // queda siempre visible en una tarjeta; el resto son
              // secciones plegables cerradas por defecto (con badge
              // "Opcional", coherente con que esos campos ya no son
              // obligatorios — ver ActorModel). Al EDITAR un actor
              // existente sí se abren solas, para no esconder datos que
              // la persona ya cargó.
              _card(
                icon: Icons.photo_camera_outlined,
                title: 'Fotos del actor',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _photoBox(
                      label: 'Actor en personaje',
                      bytesFuture: _fotoPersonaje,
                      uploading: _subiendoFotoPersonaje,
                      onPick: _idActor == null ? null : _pickAndUploadFotoPersonaje,
                    ),
                    const SizedBox(width: 12),
                    _photoBox(
                      label: 'Actor normal',
                      bytesFuture: _fotoNormal,
                      uploading: _subiendoFotoNormal,
                      onPick: _idActor == null ? null : _pickAndUploadFotoNormal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                icon: Icons.badge_outlined,
                title: 'Datos personales',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(child: AppTextField(label: 'Nombre', controller: _nombre, validator: _req)),
                      const SizedBox(width: 12),
                      Expanded(child: AppTextField(label: 'Apellido', controller: _apellido, validator: _req)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: AppDropdown<String>(
                          label: 'Género',
                          value: _genero,
                          items: kGenerosActor,
                          labelBuilder: (e) => e,
                          onChanged: (v) => setState(() => _genero = v ?? _genero),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Fecha de nacimiento',
                          hint: 'Selecciona una fecha (opcional)',
                          controller: _fechaNacimiento,
                          readOnly: true,
                          onTap: _pickFechaNacimiento,
                          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    AppDropdown<String>(
                      label: 'Nacionalidad',
                      value: _nacionalidad,
                      hint: 'Selecciona país',
                      items: _catalogWith(kPaises, _nacionalidad ?? ''),
                      labelBuilder: (e) => e,
                      onChanged: (v) => setState(() => _nacionalidad = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CollapsibleSection(
                icon: Icons.contact_phone_outlined,
                title: 'Contacto de producción',
                subtitle: 'Opcional — cédula, dirección, teléfono, correo',
                initiallyExpanded: _isEditing,
                children: [
                  AppTextField(label: 'Cédula', controller: _cedula),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Dirección', controller: _direccion),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: AppTextField(label: 'Teléfono', controller: _telefono, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 12),
                    Expanded(child: AppTextField(label: 'Correo', controller: _correo, keyboardType: TextInputType.emailAddress)),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              _CollapsibleSection(
                icon: Icons.straighten_outlined,
                title: 'Medidas de vestuario',
                subtitle: 'Opcional — puedes completarlo más adelante',
                initiallyExpanded: _isEditing,
                children: [
                  _measureRow(_tallaZapatos, 'Talla de zapatos', _anchoEspalda, 'Ancho de espalda'),
                  const SizedBox(height: 12),
                  _measureRow(_pecho, 'Pecho', _cintura, 'Cintura'),
                  const SizedBox(height: 12),
                  _measureRow(_cadera, 'Cadera', _largoManga, 'Largo de manga'),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Largo de pierna', controller: _largoPierna),
                ],
              ),
              const SizedBox(height: 12),
              _CollapsibleSection(
                icon: Icons.face_retouching_natural_outlined,
                title: 'Maquillaje y caracterización',
                subtitle: 'Opcional',
                initiallyExpanded: _isEditing,
                children: [
                  Row(children: [
                    Expanded(child: AppTextField(label: 'Color de cabello', controller: _colorCabello)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Textura de cabello',
                        value: _texturaCabello,
                        items: _catalogWith(kTexturasCabello, _texturaCabello),
                        labelBuilder: (e) => e,
                        onChanged: (v) => setState(() => _texturaCabello = v ?? _texturaCabello),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Tipo de piel',
                        value: _tipoPiel,
                        items: _catalogWith(kTiposPiel, _tipoPiel),
                        labelBuilder: (e) => e,
                        onChanged: (v) => setState(() => _tipoPiel = v ?? _tipoPiel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Tono de piel',
                        value: _tonoPiel,
                        hint: 'Selecciona tono',
                        items: _catalogWith(kTonosPiel, _tonoPiel ?? ''),
                        labelBuilder: (e) => e,
                        onChanged: (v) => setState(() => _tonoPiel = v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  AppDropdown<String>(
                    label: 'Color de ojos',
                    value: _colorOjos,
                    items: _catalogWith(kColoresOjos, _colorOjos),
                    labelBuilder: (e) => e,
                    onChanged: (v) => setState(() => _colorOjos = v ?? _colorOjos),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CollapsibleSection(
                icon: Icons.info_outline,
                title: 'Otros',
                subtitle: 'Opcional — alergias, doble de riesgo',
                initiallyExpanded: _isEditing,
                children: [
                  AppTextField(label: 'Alergias', controller: _alergias, maxLines: 2),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Doble de riesgo'),
                    value: _dobleRiesgo,
                    onChanged: (v) => setState(() => _dobleRiesgo = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CollapsibleSection(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Seguimiento de casting',
                subtitle: 'Opcional — status, llamados, ensayos',
                initiallyExpanded: _isEditing,
                children: [
                  Row(children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Status de confirmación',
                        value: _statusConfirmacion,
                        hint: 'Selecciona status',
                        items: kStatusConfirmacionActor,
                        labelBuilder: (e) => e,
                        onChanged: (v) => setState(() => _statusConfirmacion = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Categoría de cast',
                        value: _categoriaCast,
                        hint: 'Selecciona categoría',
                        items: kCategoriasCast,
                        labelBuilder: (e) => e,
                        onChanged: (v) => setState(() => _categoriaCast = v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: AppTextField(label: 'Llamados', hint: 'Cantidad de días llamados', controller: _llamados)),
                    const SizedBox(width: 12),
                    Expanded(child: AppTextField(label: 'Fechas tentativas', controller: _fechasTentativas)),
                  ]),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Ensayos', hint: 'Notas de ensayos, pruebas de vestuario, etc.', controller: _ensayos, maxLines: 2),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Guion enviado'),
                    value: _guionEnviado,
                    onChanged: (v) => setState(() => _guionEnviado = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Guardar cambios' : 'Guardar ficha técnica'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta simple y siempre visible (sin plegar) para las 2 secciones
  /// esenciales del formulario: fotos y datos personales. Mismo look
  /// (icono + título + borde suave) que _CollapsibleSection, para que
  /// el formulario se sienta como un solo sistema visual.
  Widget _card({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: AppColors.moradoTech),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Arma la lista de opciones de un dropdown de catálogo agregando el
  /// valor actual al final si no está ya en [catalog] — evita perder
  /// datos de fichas guardadas antes de este catálogo (texto libre) y
  /// evita que el dropdown quede sin selección visible.
  List<String> _catalogWith(List<String> catalog, String current) {
    if (current.isEmpty || catalog.contains(current)) return catalog;
    return [...catalog, current];
  }

  Widget _measureRow(TextEditingController a, String labelA, TextEditingController b, String labelB) {
    return Row(children: [
      Expanded(child: AppTextField(label: labelA, controller: a)),
      const SizedBox(width: 12),
      Expanded(child: AppTextField(label: labelB, controller: b)),
    ]);
  }

  /// Una de las 2 casillas de foto (personaje/normal): thumbnail chico
  /// (mismo estilo que la foto de perfil, ver profile_screen.dart:
  /// CircleAvatar + insignia de cámara superpuesta). Si todavía no hay
  /// foto, tocar el círculo completo también sube una (no solo la
  /// insignia) — pedido explícito del usuario, que hacía click sobre el
  /// ícono de la foto esperando que eso le dejara subir. Si ya hay
  /// foto, tocar el círculo la muestra ampliada (mismo diálogo que
  /// gallery_screen.dart) y la insignia de cámara la reemplaza.
  /// [onPick] viene null mientras el actor todavía no existe en el
  /// backend (no hay id_actor al que asociar la foto) — ahí se
  /// deshabilita todo y se muestra un aviso.
  Widget _photoBox({
    required String label,
    required Future<List<int>>? bytesFuture,
    required bool uploading,
    required VoidCallback? onPick,
  }) {
    final hasPhoto = bytesFuture != null;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(44),
                onTap: uploading
                    ? null
                    : hasPhoto
                        ? () => _showFotoAmpliada(label, bytesFuture)
                        : onPick,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surfaceVariant,
                  child: ClipOval(
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: uploading
                          ? const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                          : !hasPhoto
                              ? const Center(child: Icon(Icons.person_outline, size: 32, color: AppColors.grisMedio))
                              : FutureBuilder<List<int>>(
                                  future: bytesFuture,
                                  builder: (context, snap) {
                                    if (snap.connectionState == ConnectionState.waiting) {
                                      return const Center(child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)));
                                    }
                                    if (snap.hasError || snap.data == null) {
                                      return const Center(child: Icon(Icons.person_outline, size: 32, color: AppColors.grisMedio));
                                    }
                                    return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: 88, height: 88);
                                  },
                                ),
                    ),
                  ),
                ),
              ),
              if (onPick != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: AppColors.moradoTech,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: uploading ? null : onPick,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (onPick == null)
            const Text(
              'Guarda la ficha técnica para poder subir esta foto',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisMedio, fontSize: 11),
            )
          else
            Text(
              hasPhoto ? 'Toca la foto para verla o cambiarla' : 'Toca el ícono para subir la foto',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grisMedio, fontSize: 11),
            ),
        ],
      ),
    );
  }

  void _showFotoAmpliada(String label, Future<List<int>> bytesFuture) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FutureBuilder<List<int>>(
                future: bytesFuture,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  return Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.contain);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(label, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _reloadFotoPersonaje() {
    final idActor = _idActor;
    if (idActor == null) return;
    final session = context.read<AuthSession>();
    // Con llaves — evita 'setState() callback argument returned a
    // Future' (ver detalle en crew_list_screen.dart).
    setState(() {
      _fotoPersonaje = ActorService(session.api).fotoPersonajeBytes(idActor);
    });
  }

  void _reloadFotoNormal() {
    final idActor = _idActor;
    if (idActor == null) return;
    final session = context.read<AuthSession>();
    setState(() {
      _fotoNormal = ActorService(session.api).fotoNormalBytes(idActor);
    });
  }

  Future<void> _pickAndUploadFotoPersonaje() => _pickAndUploadFoto(
        isPersonaje: true,
        setUploading: (v) => setState(() => _subiendoFotoPersonaje = v),
        onDone: _reloadFotoPersonaje,
      );

  Future<void> _pickAndUploadFotoNormal() => _pickAndUploadFoto(
        isPersonaje: false,
        setUploading: (v) => setState(() => _subiendoFotoNormal = v),
        onDone: _reloadFotoNormal,
      );

  Future<void> _pickAndUploadFoto({
    required bool isPersonaje,
    required void Function(bool) setUploading,
    required VoidCallback onDone,
  }) async {
    final idActor = _idActor;
    if (idActor == null) return;

    final source = await _askPhotoSource();
    if (source == null) return; // se canceló el diálogo

    Uint8List? bytes;
    String? filename;

    if (source == _PhotoSource.camera) {
      XFile? foto;
      try {
        // maxWidth/maxHeight: limita la resolución de la foto tomada
        // (una cámara moderna saca varios MB sin esto) para que la
        // subida no tarde de más en red real — mismo criterio que en
        // Continuidad Visual (scene_edit_screen.dart).
        foto = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } catch (e) {
        // P.ej. el navegador/SO negó el permiso de cámara, o el
        // dispositivo no tiene una cámara soportada.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo acceder a la cámara. Verifica los permisos del navegador/dispositivo.')),
          );
        }
        return;
      }
      if (foto == null) return; // se canceló
      bytes = await foto.readAsBytes();
      filename = foto.name;
    } else {
      // file_picker 13.x: pickFile() (singular) devuelve el
      // PlatformFile directo; los bytes se leen aparte, async, con
      // readAsBytes().
      final picked = await FilePicker.pickFile(type: FileType.image);
      if (picked == null) return;
      bytes = await picked.readAsBytes();
      filename = picked.name;
    }
    if (bytes == null || filename == null) return;

    setUploading(true);
    final session = context.read<AuthSession>();

    try {
      final service = ActorService(session.api);
      if (isPersonaje) {
        await service.uploadFotoPersonaje(idActor, bytes: bytes, filename: filename, contentType: _contentTypeFor(filename));
      } else {
        await service.uploadFotoNormal(idActor, bytes: bytes, filename: filename, contentType: _contentTypeFor(filename));
      }
      onDone();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto ${isPersonaje ? 'en personaje' : 'normal'} actualizada')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      setUploading(false);
    }
  }

  /// Diálogo centrado para elegir el origen de la foto — mismo patrón
  /// que scene_edit_screen.dart: "Tomar foto" solo en celular/tablet
  /// (en PC de escritorio ese atributo solo reabre el explorador de
  /// archivos), "Elegir de galería/carpeta" siempre disponible.
  Future<_PhotoSource?> _askPhotoSource() {
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text('¿De dónde quieres subir la foto?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  /// Mismo patrón de calendario que profile_screen.dart/scene_edit_screen.dart
  /// — pedido explícito del usuario (2026-09-04): que salga el calendario
  /// para seleccionar la fecha en vez de escribirla a mano. El texto del
  /// controller queda en formato AAAA-MM-DD (ISO), que es justo lo que
  /// _submit() ya espera poder parsear con DateTime.tryParse.
  Future<void> _pickFechaNacimiento() async {
    final initial = DateTime.tryParse(_fechaNacimiento.text.trim()) ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaNacimiento.text = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Solo nombre/apellido son obligatorios (ver ActorModel) — pedido
    // explícito del usuario (2026-09-03) para poder guardar rápido y
    // desbloquear la subida de fotos sin diligenciar toda la ficha. La
    // fecha se valida solo SI el usuario escribió algo; si el campo
    // quedó vacío, se guarda sin fecha.
    DateTime? fecha;
    final fechaTexto = _fechaNacimiento.text.trim();
    if (fechaTexto.isNotEmpty) {
      fecha = DateTime.tryParse(fechaTexto);
      if (fecha == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fecha de nacimiento inválida, usa el formato AAAA-MM-DD')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    final session = context.read<AuthSession>();

    final datos = ActorModel(
      idActor: _idActor,
      nombre: _nombre.text.trim(),
      apellido: _apellido.text.trim(),
      genero: _genero,
      fechaDeNacimiento: fecha,
      tallaZapatos: _tallaZapatos.text.trim(),
      anchoEspalda: _anchoEspalda.text.trim(),
      pecho: _pecho.text.trim(),
      cintura: _cintura.text.trim(),
      cadera: _cadera.text.trim(),
      largoManga: _largoManga.text.trim(),
      largoPierna: _largoPierna.text.trim(),
      colorCabello: _colorCabello.text.trim(),
      texturaCabello: _texturaCabello,
      tipoPiel: _tipoPiel,
      colorOjos: _colorOjos,
      tonoPiel: _tonoPiel,
      alergias: _alergias.text.trim(),
      nacionalidad: _nacionalidad,
      dobleRiesgo: _dobleRiesgo,
      idPersonaje: _currentActor?.idPersonaje ?? widget.idPersonaje,
      idProject: session.projectId,
      cedula: _cedula.text.trim(),
      direccion: _direccion.text.trim(),
      telefono: _telefono.text.trim(),
      correo: _correo.text.trim(),
      statusConfirmacion: _statusConfirmacion,
      llamados: _llamados.text.trim(),
      fechasTentativas: _fechasTentativas.text.trim(),
      guionEnviado: _guionEnviado,
      ensayos: _ensayos.text.trim(),
      categoriaCast: _categoriaCast,
    );

    try {
      if (_isEditing) {
        await ActorService(session.api).update(_idActor!, datos.toCreateJson());
        if (!mounted) return;
        setState(() => _currentActor = datos);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ficha técnica actualizada')));
      } else {
        final creado = await ActorService(session.api).create(datos);
        if (!mounted) return;
        setState(() => _currentActor = creado);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ficha técnica guardada. Ya puedes subir las fotos del actor.')),
        );
      }
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Sección plegable con el mismo look de tarjeta que `_card` (icono +
/// título + borde suave), pero con un toggle para expandir/contraer —
/// pedido explícito del usuario (2026-09-04) para que la ficha técnica
/// no se sienta abrumadora: solo se ve el encabezado de cada grupo
/// opcional hasta que la persona decide abrirlo.
class _CollapsibleSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.icon,
    required this.title,
    this.subtitle,
    this.initiallyExpanded = false,
    required this.children,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: AppColors.moradoTech),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        if (widget.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.subtitle!,
                              style: const TextStyle(fontSize: 11, color: AppColors.grisMedio),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grisMedio),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
