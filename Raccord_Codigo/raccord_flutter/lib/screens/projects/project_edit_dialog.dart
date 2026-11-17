import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';
import '../../widgets/app_text_field.dart';

/// Diálogo para editar un proyecto existente: datos básicos + estado
/// (Preliminar / En rodaje / Suspendido / Finalizado) y, si está
/// suspendido, su causal (Temporal / Indefinido / Incumplimiento).
///
/// Devuelve `true` si se guardaron cambios, para que quien lo abrió
/// recargue la lista.
Future<bool> showEditProjectDialog(BuildContext context, Project project) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Editar Proyecto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop(false)),
                  ],
                ),
                const SizedBox(height: 12),
                _EditProjectForm(project: project, onSaved: () => Navigator.of(ctx).pop(true)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return saved ?? false;
}

class _EditProjectForm extends StatefulWidget {
  final Project project;
  final VoidCallback onSaved;
  const _EditProjectForm({required this.project, required this.onSaved});

  @override
  State<_EditProjectForm> createState() => _EditProjectFormState();
}

class _EditProjectFormState extends State<_EditProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _sinopsis;
  late final TextEditingController _director;
  late String _formato;
  late String _genero;
  late String _estado;
  String? _causal;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nombre = TextEditingController(text: p.projectName);
    _sinopsis = TextEditingController(text: p.sinopsis ?? '');
    _director = TextEditingController(text: p.director ?? '');
    _formato = p.formatoDeProduccion;
    _genero = p.genero;
    _estado = kEstadosProyecto.containsKey(p.estado) ? p.estado : 'preliminar';
    _causal = p.causalSuspension;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _sinopsis.dispose();
    _director.dispose();
    super.dispose();
  }

  // Si el proyecto trae un valor que no está en el catálogo (datos viejos
  // en texto libre), se agrega a las opciones para que el dropdown no falle.
  List<String> _opciones(List<String> base, String actual) =>
      base.contains(actual) || actual.isEmpty ? base : [...base, actual];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'Nombre del Proyecto',
            controller: _nombre,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          AppDropdown<String>(
            label: 'Estado del proyecto',
            value: _estado,
            items: kEstadosProyecto.keys.toList(),
            labelBuilder: (e) => kEstadosProyecto[e] ?? e,
            onChanged: (v) => setState(() {
              _estado = v ?? 'preliminar';
              // La causal solo existe cuando el proyecto está suspendido.
              if (_estado != 'suspendido') _causal = null;
            }),
          ),
          if (_estado == 'suspendido') ...[
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Causal de suspensión',
              value: _causal,
              hint: 'Selecciona una causal',
              items: kCausalesSuspension.keys.toList(),
              labelBuilder: (e) => kCausalesSuspension[e] ?? e,
              onChanged: (v) => setState(() => _causal = v),
            ),
          ],
          const SizedBox(height: 16),
          AppDropdown<String>(
            label: 'Formato',
            value: _formato.isEmpty ? null : _formato,
            hint: 'Selecciona un formato',
            items: _opciones(kFormatosProduccion, _formato),
            labelBuilder: (e) => e,
            onChanged: (v) => setState(() => _formato = v ?? ''),
          ),
          const SizedBox(height: 16),
          AppDropdown<String>(
            label: 'Género',
            value: _genero.isEmpty ? null : _genero,
            hint: 'Selecciona un género',
            items: _opciones(kGenerosProduccion, _genero),
            labelBuilder: (e) => e,
            onChanged: (v) => setState(() => _genero = v ?? ''),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Sinopsis', controller: _sinopsis, maxLines: 4),
          const SizedBox(height: 16),
          AppTextField(label: 'Director', hint: 'Director o directores del producto audiovisual', controller: _director),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_formato.isEmpty || _genero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona formato y género')));
      return;
    }
    if (_estado == 'suspendido' && _causal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un proyecto suspendido requiere una causal')),
      );
      return;
    }

    setState(() => _loading = true);
    final session = context.read<AuthSession>();
    try {
      await ProjectService(session.api).update(
        widget.project.idProject,
        projectName: _nombre.text.trim(),
        formatoDeProduccion: _formato,
        genero: _genero,
        sinopsis: _sinopsis.text.trim().isEmpty ? null : _sinopsis.text.trim(),
        director: _director.text.trim().isEmpty ? null : _director.text.trim(),
        estado: _estado,
        causalSuspension: _causal,
      );
      widget.onSaved();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
