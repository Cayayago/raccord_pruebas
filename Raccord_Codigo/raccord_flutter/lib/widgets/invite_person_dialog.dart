import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/session.dart';
import '../models/catalog.dart';
import '../services/role_service.dart';
import '../theme/app_theme.dart';
import 'app_text_field.dart';

/// Diálogo "Invitar persona" (nombre + correo + área/departamento +
/// rol), compartido entre Roles del Equipo y Crew List (2026-09-01) —
/// invitar a alguien SIEMPRE crea una cuenta real con rol, sin importar
/// desde qué pantalla se dispare, así que el formulario es uno solo en
/// vez de duplicarlo. Devuelve `true` por Navigator.pop si la
/// invitación se envió correctamente, `false`/`null` si se canceló.
class InvitePersonDialog extends StatefulWidget {
  final String projectId;
  final String idClient;
  final List<Department> departamentos;
  final List<RoleModel> roles;

  const InvitePersonDialog({
    super.key,
    required this.projectId,
    required this.idClient,
    required this.departamentos,
    required this.roles,
  });

  @override
  State<InvitePersonDialog> createState() => _InvitePersonDialogState();
}

class _InvitePersonDialogState extends State<InvitePersonDialog> {
  final _nombreCompleto = TextEditingController();
  final _correo = TextEditingController();
  String? _idDepartamento;
  int? _idRol;
  bool _loading = false;

  @override
  void dispose() {
    _nombreCompleto.dispose();
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // Alineado con el inset que ya usa `showCenteredFormSheet` en el
      // resto de la app (el default de Flutter deja aún menos ancho
      // disponible en móvil angosto).
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        // Sin este scroll, el contenido (header + 2 filas de campos +
        // botones) se desborda en pantallas de poca altura o con el
        // teclado abierto en móvil — un Dialog no da scroll automático.
        child: SingleChildScrollView(
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NUEVA INVITACIÓN', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                          SizedBox(height: 4),
                          Text('Invitar al equipo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // En pantallas angostas (móvil) los pares de campos en
                    // Row+Expanded quedaban demasiado comprimidos. Por
                    // debajo de 420px de ancho disponible se apilan.
                    final wide = constraints.maxWidth > 420;
                    final camposContacto = wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: AppTextField(label: 'Nombre completo', hint: 'Nombre y apellidos', controller: _nombreCompleto)),
                              const SizedBox(width: 16),
                              Expanded(child: AppTextField(label: 'Correo electrónico', hint: 'correo@dominio.com', controller: _correo, keyboardType: TextInputType.emailAddress)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(label: 'Nombre completo', hint: 'Nombre y apellidos', controller: _nombreCompleto),
                              const SizedBox(height: 16),
                              AppTextField(label: 'Correo electrónico', hint: 'correo@dominio.com', controller: _correo, keyboardType: TextInputType.emailAddress),
                            ],
                          );
                    final camposRol = wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AppDropdown<String>(
                                  label: 'Área / Departamento',
                                  value: _idDepartamento,
                                  hint: 'Selecciona área',
                                  items: widget.departamentos.map((d) => d.idDepartamento).toList(),
                                  labelBuilder: (id) => widget.departamentos.firstWhere((d) => d.idDepartamento == id).nombre,
                                  onChanged: (v) => setState(() => _idDepartamento = v),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppDropdown<int>(
                                  label: 'Rol',
                                  value: _idRol,
                                  hint: 'Selecciona rol',
                                  items: widget.roles.map((r) => r.idRol).toList(),
                                  labelBuilder: (id) => widget.roles.firstWhere((r) => r.idRol == id).nombre,
                                  onChanged: (v) => setState(() => _idRol = v),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppDropdown<String>(
                                label: 'Área / Departamento',
                                value: _idDepartamento,
                                hint: 'Selecciona área',
                                items: widget.departamentos.map((d) => d.idDepartamento).toList(),
                                labelBuilder: (id) => widget.departamentos.firstWhere((d) => d.idDepartamento == id).nombre,
                                onChanged: (v) => setState(() => _idDepartamento = v),
                              ),
                              const SizedBox(height: 16),
                              AppDropdown<int>(
                                label: 'Rol',
                                value: _idRol,
                                hint: 'Selecciona rol',
                                items: widget.roles.map((r) => r.idRol).toList(),
                                labelBuilder: (id) => widget.roles.firstWhere((r) => r.idRol == id).nombre,
                                onChanged: (v) => setState(() => _idRol = v),
                              ),
                            ],
                          );
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        camposContacto,
                        const SizedBox(height: 16),
                        camposRol,
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _submit,
                              icon: _loading
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_outlined, size: 16),
                              label: const Text('Enviar invitación'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.moradoTech),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final nombreCompleto = _nombreCompleto.text.trim();
    final correo = _correo.text.trim();

    if (nombreCompleto.isEmpty || correo.isEmpty || _idDepartamento == null || _idRol == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa nombre, correo, área y rol')));
      return;
    }

    setState(() => _loading = true);
    final session = context.read<AuthSession>();

    try {
      await RoleService(session.api).invite(
        invitados: [InviteItem(nombreCompleto: nombreCompleto, mail: correo, idDepartamento: _idDepartamento!, idRol: _idRol!)],
        idProject: widget.projectId,
        idClient: widget.idClient,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
