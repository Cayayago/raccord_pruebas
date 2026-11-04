import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/session.dart';
import '../models/module_access.dart';
import '../services/module_access_service.dart';
import '../theme/app_theme.dart';
import 'state_views.dart';

/// Sentinel para "sin excepción" en el Dropdown — no puede ser null
/// porque DropdownButton usa null para "sin selección".
const _kDefault = '__default__';

/// Diálogo "Personalizar accesos" (Roles del Equipo): permite a
/// Administrador/Director bajarle el nivel de acceso a UNA persona en
/// UNO o varios de los 9 módulos, sin crear un rol nuevo ni afectar a
/// nadie más — ver contexto completo en app/utils/module_access.py.
/// Solo puede RESTRINGIR: el Dropdown de cada módulo nunca ofrece un
/// nivel por encima del que ya tiene por su rol.
class ModuleAccessDialog extends StatefulWidget {
  final String projectId;
  final String idUser;
  final String nombreCompleto;

  const ModuleAccessDialog({
    super.key,
    required this.projectId,
    required this.idUser,
    required this.nombreCompleto,
  });

  @override
  State<ModuleAccessDialog> createState() => _ModuleAccessDialogState();
}

class _ModuleAccessDialogState extends State<ModuleAccessDialog> {
  late Future<List<ModuleAccessModel>> _future;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ModuleAccessModel>> _load() {
    final session = context.read<AuthSession>();
    return ModuleAccessService(session.api).list(widget.projectId, widget.idUser);
  }

  // Con llaves para que el callback de setState devuelva void y no el
  // Future de _load() — de lo contrario Flutter lanza 'setState()
  // callback argument returned a Future' y el widget nunca se
  // reconstruye (ver mismo fix en crew_list_screen.dart).
  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _applyChange(String modulo, String? nivelSeleccionado, bool teniaExcepcion) async {
    final session = context.read<AuthSession>();
    setState(() => _saving.add(modulo));
    try {
      if (nivelSeleccionado == null) {
        if (teniaExcepcion) {
          await ModuleAccessService(session.api).remove(widget.projectId, widget.idUser, modulo);
        }
      } else {
        await ModuleAccessService(session.api).set(widget.projectId, widget.idUser, modulo, nivelSeleccionado);
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving.remove(modulo));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.moradoTech, AppColors.azulProfundo]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PERSONALIZAR ACCESOS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                        const SizedBox(height: 4),
                        Text(widget.nombreCompleto, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(
                'Solo puedes RESTRINGIR el acceso por debajo de lo que su rol ya permite en cada módulo, '
                'nunca darle más de lo que su rol otorgaría. Útil para casos puntuales (ej. ocultar un '
                'módulo sensible para una persona concreta).',
                style: TextStyle(color: AppColors.grisMedio, fontSize: 12.5),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ModuleAccessModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
                  if (snap.hasError) {
                    return ErrorView(message: 'No se pudieron cargar los accesos de esta persona.', onRetry: _reload);
                  }
                  final modulos = snap.data ?? [];
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: modulos.length,
                    separatorBuilder: (_, __) => const Divider(height: 20),
                    itemBuilder: (context, i) => _ModuleRow(
                      acceso: modulos[i],
                      saving: _saving.contains(modulos[i].modulo),
                      onChanged: (nivel) => _applyChange(modulos[i].modulo, nivel, modulos[i].esExcepcion),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  final ModuleAccessModel acceso;
  final bool saving;
  final ValueChanged<String?> onChanged;

  const _ModuleRow({required this.acceso, required this.saving, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final rangoRol = ModuloAccesos.nivelRango[acceso.nivelRol] ?? 0;
    // Solo se ofrecen niveles <= el nivel del rol (nunca más de lo que
    // el rol ya otorgaría) — ver docstring de get_effective_module_level.
    final opciones = ModuloAccesos.niveles.keys.where((n) => (ModuloAccesos.nivelRango[n] ?? 0) <= rangoRol).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(acceso.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                'Por rol: ${acceso.nivelRolLabel}',
                style: const TextStyle(color: AppColors.grisMedio, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 190,
          child: saving
              ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: acceso.esExcepcion ? acceso.nivelExcepcion : _kDefault,
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: [
                    DropdownMenuItem(value: _kDefault, child: Text('Predeterminado (${acceso.nivelRolLabel})', overflow: TextOverflow.ellipsis)),
                    ...opciones.map((n) => DropdownMenuItem(value: n, child: Text(ModuloAccesos.labelNivel(n)))),
                  ],
                  onChanged: (value) => onChanged(value == _kDefault ? null : value),
                ),
        ),
      ],
    );
  }
}
