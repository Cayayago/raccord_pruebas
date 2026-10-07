import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> identificacionTypes = ["CC", "NIT", "TI", "PA", "CE"];

  bool isLoading = true;
  bool isSaving = false;
  bool isSavingPassword = false;

  String error = "";
  String success = "";
  String passwordError = "";
  String passwordSuccess = "";

  Uint8List? profilePhotoBytes;

  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final mailController = TextEditingController();
  final msisdnController = TextEditingController();
  final idIdentificacionController = TextEditingController();
  final direccionController = TextEditingController();
  final departamentoController = TextEditingController();
  String identificacion = "";
  DateTime? fechaNacimiento;
  DateTime? fechaCreacion;

  final nuevaPasswordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();
  bool verNueva = false;
  bool verConfirmar = false;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    mailController.dispose();
    msisdnController.dispose();
    idIdentificacionController.dispose();
    direccionController.dispose();
    departamentoController.dispose();
    nuevaPasswordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }

  List<String> _validarContrasena(String password) {
    final reglas = <String>[];
    if (password.length < 8) reglas.add("Mínimo 8 caracteres");
    if (!RegExp(r'[a-z]').hasMatch(password)) reglas.add("Una letra minúscula");
    if (!RegExp(r'[A-Z]').hasMatch(password)) reglas.add("Una letra mayúscula");
    if (!RegExp(r'[0-9]').hasMatch(password)) reglas.add("Un número");
    if (!RegExp(r'''[!@#$%^&*()_+\-=\[\]{};:'"\\|,.<>/?]''').hasMatch(password)) {
      reglas.add("Un carácter especial");
    }
    return reglas;
  }

  Future<void> _fetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getString('id_user');

    try {
      final response = await http.get(Uri.parse('$apiUrl/users/$idUser'));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final data = result is List ? result[0] : (result['data'] ?? result);

        setState(() {
          nombreController.text = data['nombre'] ?? '';
          apellidoController.text = data['apellido'] ?? '';
          mailController.text = data['mail'] ?? '';
          msisdnController.text = data['msisdn'] ?? '';
          identificacion = data['identificacion'] ?? '';
          idIdentificacionController.text = (data['id_identificacion'] ?? '').toString();
          direccionController.text = data['direccion'] ?? '';
          fechaNacimiento = _parseFecha(data['fecha_de_nacimiento']);
          fechaCreacion = _parseFecha(data['fecha_de_creacion']);
          departamentoController.text = (data['id_departamento'] ?? '').toString();
        });
      }
    } catch (e) {
      setState(() => error = "No se pudo cargar los datos del perfil");
    } finally {
      setState(() => isLoading = false);
    }
  }

  DateTime? _parseFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return null;
    try {
      return DateTime.parse(fecha.split("T")[0]);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => profilePhotoBytes = bytes);
    }
  }

  Future<void> _pickFecha(bool esNacimiento) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (esNacimiento ? fechaNacimiento : fechaCreacion) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (esNacimiento) {
          fechaNacimiento = picked;
        } else {
          fechaCreacion = picked;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      error = "";
      success = "";
      isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getString('id_user');

    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/users/$idUser'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombreController.text,
          "apellido": apellidoController.text,
          "msisdn": msisdnController.text,
          "identificacion": identificacion,
          "id_identificacion": idIdentificacionController.text,
          "direccion": direccionController.text.isEmpty ? null : direccionController.text,
          "fecha_de_nacimiento": fechaNacimiento == null
              ? null
              : "${fechaNacimiento!.year.toString().padLeft(4, '0')}-${fechaNacimiento!.month.toString().padLeft(2, '0')}-${fechaNacimiento!.day.toString().padLeft(2, '0')}",
          "id_departamento": departamentoController.text.isEmpty ? null : departamentoController.text,
        }),
      );

      if (response.statusCode == 200) {
        await prefs.setString('nombre', nombreController.text);
        await prefs.setString('apellido', apellidoController.text);
        setState(() => success = "Perfil actualizado exitosamente");
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        setState(() => error = _extraerMensajeError(errorData, "Error al guardar los cambios"));
      }
    } catch (e) {
      setState(() => error = "No se pudo conectar con el servidor");
    } finally {
      setState(() => isSaving = false);
    }
  }

  String _extraerMensajeError(dynamic errorData, String fallback) {
    final detail = errorData is Map ? errorData['detail'] : null;
    if (detail is String) return detail;
    if (detail is List) return detail.map((e) => e['msg'].toString()).join(", ");
    return (errorData is Map ? errorData['message'] : null) ?? fallback;
  }

  Future<void> _handleChangePassword() async {
    setState(() {
      passwordError = "";
      passwordSuccess = "";
    });

    final reglasFaltantes = _validarContrasena(nuevaPasswordController.text);
    if (reglasFaltantes.isNotEmpty) {
      setState(() => passwordError = "La contraseña debe tener: ${reglasFaltantes.join(", ")}");
      return;
    }

    if (nuevaPasswordController.text != confirmarPasswordController.text) {
      setState(() => passwordError = "Las contraseñas no coinciden");
      return;
    }

    setState(() => isSavingPassword = true);

    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getString('id_user');

    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/users/$idUser'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"contrasena": nuevaPasswordController.text}),
      );

      if (response.statusCode == 200) {
        setState(() {
          passwordSuccess = "Contraseña actualizada exitosamente";
          nuevaPasswordController.clear();
          confirmarPasswordController.clear();
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        setState(() => passwordError = _extraerMensajeError(errorData, "Error al cambiar la contraseña"));
      }
    } catch (e) {
      setState(() => passwordError = "No se pudo conectar con el servidor");
    } finally {
      setState(() => isSavingPassword = false);
    }
  }

  InputDecoration _decoration(String label, {bool disabled = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.text),
      filled: true,
      fillColor: disabled ? AppColors.border : AppColors.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _mensaje(String texto, {required bool esError}) {
    final color = esError ? Colors.red.shade400 : Colors.green.shade400;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(texto, style: TextStyle(color: color, fontSize: 13)),
    );
  }

  Widget _campoFecha(String label, DateTime? fecha, VoidCallback onTap, {bool disabled = false}) {
    final texto = fecha == null
        ? ''
        : "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(text: texto),
          enabled: !disabled,
          style: TextStyle(color: disabled ? AppColors.muted : AppColors.text),
          decoration: _decoration(label, disabled: disabled),
        ),
      ),
    );
  }

  Widget _grid(List<Widget> campos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;
        final itemWidth = wide ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 24,
          runSpacing: 20,
          children: campos.map((w) => SizedBox(width: itemWidth, child: w)).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/Logo_Negativo.png', height: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Perfil de Usuario",
                    style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  if (error.isNotEmpty) _mensaje(error, esError: true),
                  if (success.isNotEmpty) _mensaje(success, esError: false),

                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.border,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: profilePhotoBytes != null
                              ? Image.memory(profilePhotoBytes!, fit: BoxFit.cover)
                              : const Icon(Icons.upload, size: 48, color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickPhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text("Subir Foto"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _grid([
                    TextField(
                      controller: nombreController,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _decoration("Nombres"),
                    ),
                    TextField(
                      controller: apellidoController,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _decoration("Apellidos"),
                    ),
                    TextField(
                      controller: mailController,
                      enabled: false,
                      style: const TextStyle(color: AppColors.muted),
                      decoration: _decoration("Email", disabled: true),
                    ),
                    TextField(
                      controller: msisdnController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _decoration("Celular"),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: identificacion.isEmpty ? null : identificacion,
                      dropdownColor: AppColors.card,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _decoration("Tipo de Identificación"),
                      items: identificacionTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => identificacion = v ?? ""),
                    ),
                    TextField(
                      controller: idIdentificacionController,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _decoration("Número de Documento"),
                    ),
                    TextField(
                      controller: direccionController,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _decoration("Dirección de Residencia"),
                    ),
                    _campoFecha("Fecha de Nacimiento", fechaNacimiento, () => _pickFecha(true)),
                    _campoFecha("Fecha de Creación del Perfil", fechaCreacion, () {}, disabled: true),
                    TextField(
                      controller: departamentoController,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _decoration("Nombre del Departamento"),
                    ),
                  ]),

                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isSaving ? "Guardando..." : "Guardar Cambios"),
                    ),
                  ),

                  const Divider(color: AppColors.border, height: 64),

                  const Text(
                    "Cambiar Contraseña",
                    style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  if (passwordError.isNotEmpty) _mensaje(passwordError, esError: true),
                  if (passwordSuccess.isNotEmpty) _mensaje(passwordSuccess, esError: false),

                  _grid([
                    TextField(
                      controller: nuevaPasswordController,
                      obscureText: !verNueva,
                      style: const TextStyle(color: AppColors.text),
                      onChanged: (_) => setState(() {}),
                      decoration: _decoration("Nueva Contraseña").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(verNueva ? Icons.visibility_off : Icons.visibility, color: AppColors.muted),
                          onPressed: () => setState(() => verNueva = !verNueva),
                        ),
                      ),
                    ),
                    TextField(
                      controller: confirmarPasswordController,
                      obscureText: !verConfirmar,
                      style: const TextStyle(color: AppColors.text),
                      decoration: _decoration("Confirmar Contraseña").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(verConfirmar ? Icons.visibility_off : Icons.visibility, color: AppColors.muted),
                          onPressed: () => setState(() => verConfirmar = !verConfirmar),
                        ),
                      ),
                    ),
                  ]),

                  if (nuevaPasswordController.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "La contraseña debe tener:",
                            style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._reglasPassword(nuevaPasswordController.text).map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text(r.$2 ? "✓" : "○", style: TextStyle(color: r.$2 ? Colors.green.shade400 : AppColors.muted)),
                                  const SizedBox(width: 6),
                                  Text(r.$1, style: TextStyle(color: r.$2 ? Colors.green.shade400 : AppColors.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: isSavingPassword ? null : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isSavingPassword ? "Cambiando..." : "Cambiar Contraseña"),
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

  List<(String, bool)> _reglasPassword(String password) {
    return [
      ("Mínimo 8 caracteres", password.length >= 8),
      ("Una letra minúscula", RegExp(r'[a-z]').hasMatch(password)),
      ("Una letra mayúscula", RegExp(r'[A-Z]').hasMatch(password)),
      ("Un número", RegExp(r'[0-9]').hasMatch(password)),
      ("Un carácter especial", RegExp(r'''[!@#$%^&*()_+\-=\[\]{};:'"\\|,.<>/?]''').hasMatch(password)),
    ];
  }
}