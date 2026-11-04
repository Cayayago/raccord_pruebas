import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_text_field.dart';

/// Formulario "Registra/Crear Proyecto" (mockups 5 y 6.1). Se usa tanto
/// en pantalla completa como dentro de un diálogo modal.
class ProjectFormContent extends StatefulWidget {
  final ValueChanged<Project> onCreated;
  // Texto del botón de envío: "Crear Proyecto" en el diálogo rápido
  // (mockup 6.1), "Finalizar" en el paso obligatorio tras el registro
  // (mockup 5 / RegisterProjectScreen).
  final String submitLabel;
  const ProjectFormContent({super.key, required this.onCreated, this.submitLabel = 'Crear Proyecto'});

  @override
  State<ProjectFormContent> createState() => _ProjectFormContentState();
}

class _ProjectFormContentState extends State<ProjectFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _sinopsis = TextEditingController();
  final _director = TextEditingController();
  String? _formato;
  String? _genero;
  bool _loading = false;

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
            hint: 'Nombre de la serie, película u otro proyecto audiovisual',
            controller: _nombre,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),
          AppDropdown<String>(
            label: 'Formato',
            value: _formato,
            hint: 'Selecciona un formato',
            items: kFormatosProduccion,
            labelBuilder: (e) => e,
            onChanged: (v) => setState(() => _formato = v),
          ),
          const SizedBox(height: 16),
          AppDropdown<String>(
            label: 'Género',
            value: _genero,
            hint: 'Selecciona un género',
            items: kGenerosProduccion,
            labelBuilder: (e) => e,
            onChanged: (v) => setState(() => _genero = v),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Sinopsis', hint: 'Detalle de lo que trata el producto audiovisual', controller: _sinopsis, maxLines: 4),
          const SizedBox(height: 16),
          AppTextField(label: 'Director', hint: 'Director o directores del producto audiovisual', controller: _director),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_formato == null || _genero == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona formato y género')),
      );
      return;
    }

    setState(() => _loading = true);
    final session = context.read<AuthSession>();
    final service = ProjectService(session.api);

    try {
      final project = await service.createAndLink(
        projectName: _nombre.text.trim(),
        formatoDeProduccion: _formato!,
        genero: _genero!,
        sinopsis: _sinopsis.text.trim(),
        director: _director.text.trim(),
        idClient: session.user?.idClient ?? '',
        idUser: session.user?.idUser ?? '',
      );
      widget.onCreated(project);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/// Diálogo modal (mockup 6.1 "Nuevo Registro / Crear Proyecto").
Future<Project?> showCreateProjectDialog(BuildContext context) {
  return showDialog<Project>(
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
                      child: Text('Crear Proyecto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 12),
                ProjectFormContent(onCreated: (p) => Navigator.of(ctx).pop(p)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Paso OBLIGATORIO justo después de registrar la cuenta (mockup 5): la
/// persona no puede saltarse esta pantalla (no hay botón "volver" ni
/// "cerrar") porque toda cuenta nueva necesita al menos un proyecto para
/// llegar al dashboard. Usa Logo_Negativo centrado arriba de la tarjeta
/// (no Logo_CC_Negativo, que es el que va en la barra superior del resto
/// de pantallas) y el botón dice "Finalizar" en vez de "Crear Proyecto".
class RegisterProjectScreen extends StatelessWidget {
  const RegisterProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  const AppWordmark(fontSize: 34, darkAsset: AppLogos.logoNegativo, lightAsset: AppLogos.logoNegro),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Registra Proyecto',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                        ),
                        const SizedBox(height: 20),
                        ProjectFormContent(
                          submitLabel: 'Finalizar',
                          onCreated: (project) async {
                            final session = context.read<AuthSession>();
                            await session.setProject(project);
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (r) => false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
