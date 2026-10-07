import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'profile_screen.dart';

import 'app_colors.dart' show AppColors, apiUrl;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 1 = pedir correo, 2 = codigo + nueva contrasena, 3 = exito
  int paso = 1;

  final emailController = TextEditingController();
  final codigoController = TextEditingController();
  final nuevaContrasenaController = TextEditingController();
  final confirmarContrasenaController = TextEditingController();

  bool verNueva = false;
  bool verConfirmar = false;
  bool isLoading = false;
  String error = "";

  @override
  void dispose() {
    emailController.dispose();
    codigoController.dispose();
    nuevaContrasenaController.dispose();
    confirmarContrasenaController.dispose();
    super.dispose();
  }

  // ---------- Validaciones ----------

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

  String _extraerMensajeError(dynamic errorData, String fallback) {
    final detail = errorData is Map ? errorData['detail'] : null;
    if (detail is String) return detail;
    if (detail is List) return detail.map((e) => e['msg'].toString()).join(", ");
    return (errorData is Map ? errorData['message'] : null) ?? fallback;
  }

  // ---------- Paso 1: enviar correo ----------

  Future<void> _handleEnviarCodigo() async {
    setState(() {
      error = "";
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/users/recover-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mail": emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        setState(() => paso = 2);
      } else {
        final errorData = jsonDecode(response.body);
        setState(() => error = _extraerMensajeError(
            errorData, "No se encontró una cuenta con ese correo"));
      }
    } catch (e) {
      setState(() => error = "No se pudo conectar con el servidor");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------- Paso 2: codigo + nueva contrasena ----------

  Future<void> _handleResetPassword() async {
    setState(() => error = "");

    if (nuevaContrasenaController.text != confirmarContrasenaController.text) {
      setState(() => error = "Las contraseñas no coinciden");
      return;
    }

    final reglasFaltantes = _validarContrasena(nuevaContrasenaController.text);
    if (reglasFaltantes.isNotEmpty) {
      setState(() =>
          error = "La contraseña debe tener: ${reglasFaltantes.join(", ")}");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/users/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mail": emailController.text.trim(),
          "codigo": codigoController.text.trim(),
          "nueva_contrasena": nuevaContrasenaController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => paso = 3);
      } else {
        final errorData = jsonDecode(response.body);
        setState(() => error =
            _extraerMensajeError(errorData, "Código inválido o expirado"));
      }
    } catch (e) {
      setState(() => error = "No se pudo conectar con el servidor");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------- Widgets auxiliares (mismo estilo que ProfileScreen) ----------

  InputDecoration _decoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.text),
      filled: true,
      fillColor: AppColors.bg,
      suffixIcon: suffixIcon,
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

  Widget _mensajeError(String texto) {
    final color = Colors.red.shade400;
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

  Widget _cardHeader({
    required IconData icon,
    required String kicker,
    required String titulo,
    required String subtitulo,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                kicker.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  List<(String, bool)> _reglasPassword(String password) {
    return [
      ("Mínimo 8 caracteres", password.length >= 8),
      ("Una letra minúscula", RegExp(r'[a-z]').hasMatch(password)),
      ("Una letra mayúscula", RegExp(r'[A-Z]').hasMatch(password)),
      ("Un número", RegExp(r'[0-9]').hasMatch(password)),
      (
        "Un carácter especial",
        RegExp(r'''[!@#$%^&*()_+\-=\[\]{};:'"\\|,.<>/?]''').hasMatch(password)
      ),
    ];
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/Logo_Negativo.png', height: 70),
                const SizedBox(height: 32),
                if (paso == 1) _buildPaso1(),
                if (paso == 2) _buildPaso2(),
                if (paso == 3) _buildPaso3(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaso1() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.shield_outlined,
            kicker: "Seguridad de cuenta",
            titulo: "Recuperación de Acceso",
            subtitulo:
                "Ingresa tu correo electrónico registrado y te enviaremos un código de verificación.",
            gradient: [AppColors.primary, AppColors.purple],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error.isNotEmpty) _mensajeError(error),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.text),
                  decoration: _decoration("Correo Electrónico",
                      suffixIcon: const Icon(Icons.mail_outline,
                          color: AppColors.muted)),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Debe coincidir con el correo asociado a tu cuenta en el sistema.",
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleEnviarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isLoading ? "Enviando..." : "Enviar Código"),
                  ),
                ),
                                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: const Text("[DEBUG] Ir a Perfil",
                        style: TextStyle(color: AppColors.purple, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso2() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.vpn_key_outlined,
            kicker: "Verificación",
            titulo: "Restablecer Contraseña",
            subtitulo:
                "Ingresa el código que enviamos a ${emailController.text} y tu nueva contraseña.",
            gradient: [AppColors.purple, AppColors.primary],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error.isNotEmpty) _mensajeError(error),
                TextField(
                  controller: codigoController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      letterSpacing: 6),
                  decoration: _decoration("Código de Verificación")
                      .copyWith(hintText: "000000"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nuevaContrasenaController,
                  obscureText: !verNueva,
                  style: const TextStyle(color: AppColors.text),
                  onChanged: (_) => setState(() {}),
                  decoration: _decoration("Nueva Contraseña").copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          verNueva ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.muted),
                      onPressed: () => setState(() => verNueva = !verNueva),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmarContrasenaController,
                  obscureText: !verConfirmar,
                  style: const TextStyle(color: AppColors.text),
                  decoration: _decoration("Confirmar Nueva Contraseña")
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          verConfirmar
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.muted),
                      onPressed: () =>
                          setState(() => verConfirmar = !verConfirmar),
                    ),
                  ),
                ),
                if (nuevaContrasenaController.text.isNotEmpty) ...[
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
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._reglasPassword(nuevaContrasenaController.text)
                            .map(
                          (r) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text(r.$2 ? "✓" : "○",
                                    style: TextStyle(
                                        color: r.$2
                                            ? Colors.green.shade400
                                            : AppColors.muted)),
                                const SizedBox(width: 6),
                                Text(r.$1,
                                    style: TextStyle(
                                        color: r.$2
                                            ? Colors.green.shade400
                                            : AppColors.muted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                        isLoading ? "Verificando..." : "Restablecer Contraseña"),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() {
                        paso = 1;
                        error = "";
                      }),
                      icon: const Icon(Icons.arrow_back,
                          size: 16, color: AppColors.muted),
                      label: const Text("Cambiar correo",
                          style: TextStyle(color: AppColors.muted)),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : _handleEnviarCodigo,
                      child: const Text("Reenviar código",
                          style: TextStyle(color: AppColors.purple)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso3() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _cardHeader(
            icon: Icons.check_circle_outline,
            kicker: "Proceso completado",
            titulo: "Contraseña Restablecida",
            subtitulo: "",
            gradient: const [Color(0xFF1A4A2E), AppColors.primary],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.15),
                    border: Border.all(color: Colors.green.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.green, size: 32),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Tu contraseña ha sido actualizada exitosamente.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Ya puedes iniciar sesión con tu nueva contraseña.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(
                        context, (route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Ir al Inicio de Sesión"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}