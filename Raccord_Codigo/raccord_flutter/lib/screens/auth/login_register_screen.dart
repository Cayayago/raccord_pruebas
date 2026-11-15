import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../models/document_type.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_text_field.dart';

/// Mockups 1 (Ingresar) y 4 (Registrar), como tabs de una misma tarjeta.
/// El ancho de la tarjeta se adapta al tab activo (angosta para Ingresar,
/// más ancha para Registrar) para que el formulario de registro use dos
/// columnas en vez de quedar muy alargado verticalmente — igual que en
/// el frontend React (LoginScreen.jsx: max-w-md / max-w-2xl).
class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _tab.index == 1;

    return Scaffold(
      // OJO: `SingleChildScrollView` siempre reserva el alto completo del
      // viewport para su viewport interno, así que envolverlo directamente
      // en `Center` no centra nada — la tarjeta queda pegada arriba y deja
      // un espacio vacío enorme debajo. La forma correcta es invertir el
      // orden (ScrollView por fuera, Center por dentro) y usar
      // `ConstrainedBox(minHeight: ...)` con `LayoutBuilder` para que el
      // contenido se centre cuando sí cabe en pantalla, y solo haga scroll
      // (sin espacio extra) cuando no cabe.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  constraints: BoxConstraints(maxWidth: isRegister ? 720 : 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIsotipo(size: 76),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TabBar(
                              controller: _tab,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: const BoxDecoration(color: AppColors.azulProfundo),
                              dividerColor: Colors.transparent,
                              labelColor: Colors.white,
                              unselectedLabelColor: AppColors.grisMedio,
                              tabs: const [Tab(text: 'Ingresar'), Tab(text: 'Registrar')],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              // OJO: `IndexedStack` siempre se dimensiona
                              // según el hijo MÁS GRANDE (Registrar), aunque
                              // esté oculto. Eso hacía que la tarjeta de
                              // "Ingresar" quedara con un espacio vacío
                              // enorme abajo, del mismo alto que el
                              // formulario de registro. `AnimatedSize` con
                              // el formulario activo únicamente resuelve
                              // esto: la tarjeta mide solo lo que el
                              // formulario visible realmente necesita.
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                alignment: Alignment.topCenter,
                                child: _tab.index == 0
                                    ? const _LoginForm(key: ValueKey('login'))
                                    : const _RegisterForm(key: ValueKey('register')),
                              ),
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
        },
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({super.key});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _mailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'E-mail',
            hint: 'Ingresa tu correo',
            controller: _mailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu correo' : null,
            // Fuerza minúscula de verdad (no solo evita el autocapitalizado
            // del teclado) — pedido explícito: en login/registro solo la
            // contraseña puede tener mayúsculas.
            inputFormatters: const [LowerCaseTextFormatter()],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Contraseña',
            hint: 'Ingresa tu contraseña',
            controller: _passCtrl,
            obscureText: _obscure,
            validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            textCapitalization: TextCapitalization.none,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Ingresar'),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text('¿Olvidaste tu contraseña o usuario?'),
              onPressed: () => Navigator.of(context).pushNamed('/olvide-password'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final session = context.read<AuthSession>();
    final auth = AuthService(session.api);
    final mail = _mailCtrl.text.trim();

    final contrasena = _passCtrl.text;

    try {
      final requires2fa = await auth.check2faRequired(mail, session.deviceId ?? '', contrasena);

      if (requires2fa) {
        await auth.send2faCode(mail, session.deviceId ?? '', contrasena);
        if (!mounted) return;
        Navigator.of(context).pushNamed('/2fa', arguments: {
          'mail': mail,
          'contrasena': contrasena,
        });
        return;
      }

      final result = await auth.login(mail, _passCtrl.text);
      await session.setSession(result.token, result.user);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/proyectos', (r) => false);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      // OJO: este catch-all agrupa dos causas muy distintas bajo el mismo
      // mensaje genérico: (a) el navegador bloqueó la petición por CORS o
      // el backend no está corriendo (ClientException/"Failed to fetch"),
      // o (b) la respuesta llegó pero el JSON no tenía la forma esperada
      // (TypeError al leer un campo). En debug mostramos también el detalle
      // técnico para poder diferenciarlas sin adivinar.
      _showError(
        'No fue posible conectar con el servidor. Verifica tu conexión.'
        '${_debugDetail(e)}',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _debugDetail(Object e) {
    var showDetail = false;
    assert(() {
      showDetail = true;
      return true;
    }());
    return showDetail ? '\n[debug] $e' : '';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({super.key});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  // Datos de empresa (RegisterSchema)
  final _razonSocial = TextEditingController();
  final _idDocumentNumero = TextEditingController();
  final _emailEmpresa = TextEditingController();
  final _address = TextEditingController();
  final _numberCellphone = TextEditingController();
  String _tipoDocumento = kTiposDocumento.first;

  // Datos de usuario (RegisterSchema)
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _mail = TextEditingController();
  final _msisdn = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _aceptaTerminos = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Refresca el checklist de requisitos de contraseña en vivo, y
    // reevalúa si el botón "Registrar" debe habilitarse o no —
    // pedido explícito: el botón no se habilita hasta que todos los
    // campos visibles requeridos y la aceptación de términos estén
    // completos.
    for (final c in _camposRequeridos) {
      c.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() => setState(() {});

  List<TextEditingController> get _camposRequeridos => [
        _razonSocial,
        _idDocumentNumero,
        _emailEmpresa,
        _nombres,
        _apellidos,
        _mail,
        _msisdn,
        _pass,
        _confirmPass,
      ];

  bool get _formularioCompleto {
    for (final c in _camposRequeridos) {
      if (c.text.trim().isEmpty) return false;
    }
    return _reglasFaltantes.isEmpty && _pass.text == _confirmPass.text && _aceptaTerminos;
  }

  @override
  void dispose() {
    for (final c in _camposRequeridos) {
      c.removeListener(_onFormChanged);
    }
    for (final c in [
      _razonSocial,
      _idDocumentNumero,
      _emailEmpresa,
      _address,
      _numberCellphone,
      _nombres,
      _apellidos,
      _mail,
      _msisdn,
      _pass,
      _confirmPass,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _reglasFaltantes {
    final p = _pass.text;
    final faltantes = <String>[];
    if (p.length < 8) faltantes.add('Mínimo 8 caracteres');
    if (!RegExp(r'[a-z]').hasMatch(p)) faltantes.add('Una letra minúscula');
    if (!RegExp(r'[A-Z]').hasMatch(p)) faltantes.add('Una letra mayúscula');
    if (!RegExp(r'[0-9]').hasMatch(p)) faltantes.add('Un número');
    if (!RegExp(r'''[!@#$%^&*()_+\-=\[\]{};:'"\\|,.<>/?]''').hasMatch(p)) faltantes.add('Un carácter especial');
    return faltantes;
  }

  static const _reglasTexto = [
    'Mínimo 8 caracteres',
    'Una letra minúscula',
    'Una letra mayúscula',
    'Un número',
    'Un carácter especial',
  ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Información de la Empresa',
              style: TextStyle(color: AppColors.azulProfundo, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 12),
          _FieldGrid(children: [
            AppTextField(
              label: 'Razón Social',
              hint: 'Nombre de la empresa',
              controller: _razonSocial,
              validator: _req,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
            AppDropdown<String>(
              label: 'Tipo de documento',
              value: _tipoDocumento,
              items: kTiposDocumento,
              labelBuilder: tipoDocumentoLabel,
              onChanged: (v) => setState(() => _tipoDocumento = v ?? _tipoDocumento),
            ),
            AppTextField(
              label: 'Nº Documento',
              hint: 'Número de documento',
              controller: _idDocumentNumero,
              validator: _req,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
            AppTextField(
              label: 'Email Empresa',
              hint: 'correo@empresa.com',
              controller: _emailEmpresa,
              keyboardType: TextInputType.emailAddress,
              validator: _req,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
            AppTextField(
              label: 'Dirección',
              hint: 'Dirección de la empresa (opcional)',
              controller: _address,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
            AppTextField(
              label: 'Celular Empresa',
              hint: 'Celular de la empresa (opcional)',
              controller: _numberCellphone,
              keyboardType: TextInputType.phone,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
          ]),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          const Text('Información de Usuario',
              style: TextStyle(color: AppColors.azulProfundo, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 12),
          _FieldGrid(children: [
            AppTextField(
              label: 'Nombres',
              hint: 'Ingresa tus nombres',
              controller: _nombres,
              validator: _req,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
            AppTextField(
              label: 'Apellidos',
              hint: 'Ingresa tus apellidos',
              controller: _apellidos,
              validator: _req,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
            AppTextField(
              label: 'Email Personal',
              hint: 'tu@correo.com',
              controller: _mail,
              keyboardType: TextInputType.emailAddress,
              validator: _req,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
            AppTextField(
              label: 'Celular',
              hint: 'Tu número de celular',
              controller: _msisdn,
              keyboardType: TextInputType.phone,
              validator: _req,
              inputFormatters: const [LowerCaseTextFormatter()],
            ),
            AppTextField(
              label: 'Contraseña',
              hint: 'Crea una contraseña',
              controller: _pass,
              obscureText: _obscurePass,
              validator: _req,
              textCapitalization: TextCapitalization.none,
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            AppTextField(
              label: 'Confirmar Contraseña',
              hint: 'Confirma tu contraseña',
              controller: _confirmPass,
              obscureText: _obscureConfirm,
              validator: (v) => v != _pass.text ? 'Las contraseñas no coinciden' : null,
              textCapitalization: TextCapitalization.none,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ]),
          if (_pass.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: _reglasTexto.map((regla) {
                  final falta = _reglasFaltantes.contains(regla);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(falta ? Icons.circle_outlined : Icons.check_circle, size: 14, color: falta ? AppColors.grisMedio : AppColors.success),
                      const SizedBox(width: 6),
                      Text(regla, style: TextStyle(fontSize: 11, color: falta ? AppColors.grisMedio : AppColors.success)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: _aceptaTerminos, onChanged: (v) => setState(() => _aceptaTerminos = v ?? false)),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Acepto los Términos y Condiciones y autorizo el tratamiento de mis datos personales conforme a la Política de Privacidad.',
                    style: TextStyle(color: AppColors.grisMedio, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_loading || !_formularioCompleto) ? null : _submit,
            child: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Registrar'),
          ),
          if (!_formularioCompleto && !_loading) ...[
            const SizedBox(height: 8),
            Text(
              _motivoIncompleto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grisMedio, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  /// Mensaje corto explicando qué falta para poder registrar — pedido
  /// explícito del usuario: si falta algo (o no se aceptaron los
  /// términos) debe mencionarse, no solo deshabilitar el botón en
  /// silencio. Solo evalúa los campos VISIBLES del formulario.
  String get _motivoIncompleto {
    if (_camposRequeridos.any((c) => c.text.trim().isEmpty)) {
      return 'Completa todos los campos requeridos para registrarte.';
    }
    if (_reglasFaltantes.isNotEmpty) {
      return 'La contraseña debe cumplir: ${_reglasFaltantes.join(", ")}.';
    }
    if (_pass.text != _confirmPass.text) {
      return 'Las contraseñas no coinciden.';
    }
    if (!_aceptaTerminos) {
      return 'Debes aceptar los Términos y Condiciones para registrarte.';
    }
    return '';
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_reglasFaltantes.isNotEmpty) {
      _showError('La contraseña debe tener: ${_reglasFaltantes.join(", ")}');
      return;
    }
    if (!_aceptaTerminos) {
      _showError('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _loading = true);
    final session = context.read<AuthSession>();
    final auth = AuthService(session.api);

    final mail = _mail.text.trim();
    final contrasena = _pass.text;

    try {
      await auth.register(
        razonSocial: _razonSocial.text.trim(),
        representanteLegal: '${_nombres.text.trim()} ${_apellidos.text.trim()}',
        emailEmpresa: _emailEmpresa.text.trim(),
        address: _address.text.trim(),
        numberCellphone: _numberCellphone.text.trim(),
        document: _tipoDocumento,
        idDocument: _idDocumentNumero.text.trim(),
        nombre: _nombres.text.trim(),
        apellido: _apellidos.text.trim(),
        mail: mail,
        msisdn: _msisdn.text.trim(),
        contrasena: contrasena,
      );

      // El backend no devuelve token en /register, así que iniciamos
      // sesión automáticamente con las mismas credenciales para poder
      // llevar a la persona directo a "Registra Proyecto" (paso
      // obligatorio) sin pedirle que vuelva a escribir su usuario y
      // contraseña.
      final result = await auth.login(mail, contrasena);
      if (!mounted) return;
      await session.setSession(result.token, result.user);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/registrar-proyecto', (r) => false);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      // Si el registro fue exitoso pero el auto-login falla por algún
      // motivo, no perdemos la cuenta creada: devolvemos a la persona al
      // tab de Ingresar para que inicie sesión manualmente.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Ahora puedes iniciar sesión.')),
      );
      final tabs = context.findAncestorStateOfType<_LoginRegisterScreenState>();
      tabs?.setState(() => tabs._tab.index = 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Grilla de 2 columnas en pantallas anchas (como el `md:grid-cols-2` del
/// frontend React) y 1 columna en pantallas angostas. Evita que el
/// formulario de registro quede excesivamente alargado verticalmente.
class _FieldGrid extends StatelessWidget {
  final List<Widget> children;
  const _FieldGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 16.0;
      final twoCols = constraints.maxWidth >= 480;
      final itemWidth = twoCols ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;

      return Wrap(
        spacing: spacing,
        runSpacing: 16,
        children: children.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
      );
    });
  }
}
