import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

/// Mockup 2: Verificación de Doble Factor.
class TwoFactorScreen extends StatefulWidget {
  final String mail;
  // Necesaria para que el backend revalide la contraseña en
  // /2fa/verify (y /2fa/send al reenviar) — el código de correo ya no
  // es la única verificación real de la identidad.
  final String contrasena;
  const TwoFactorScreen({super.key, required this.mail, required this.contrasena});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const AppIsotipo(size: 88),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text('Verificación de Doble Factor',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 10),
                      const Text(
                        'Hemos enviado un código de verificación a tu correo electrónico',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grisMedio),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Código de Verificación', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 22, letterSpacing: 8),
                        decoration: const InputDecoration(counterText: '', hintText: '000000'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _verify,
                          child: _loading
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Verificar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _resending ? null : _resend,
                        child: Text(_resending ? 'Enviando...' : 'Reenviar código'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    final session = context.read<AuthSession>();
    final auth = AuthService(session.api);

    try {
      final result = await auth.verify2faCode(
        widget.mail,
        _codeCtrl.text.trim(),
        session.deviceId ?? '',
        widget.contrasena,
      );
      await session.setSession(result.token, result.user);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/proyectos', (r) => false);
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final session = context.read<AuthSession>();
    final auth = AuthService(session.api);

    try {
      await auth.send2faCode(widget.mail, session.deviceId ?? '', widget.contrasena);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código reenviado')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }
}
