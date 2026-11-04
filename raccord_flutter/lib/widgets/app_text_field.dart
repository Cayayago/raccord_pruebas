import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/dropdown_format.dart';

/// Fuerza todo el texto tipeado a minúscula, sin importar Bloq Mayús,
/// Shift o si el teclado del sistema tiene activada la mayúscula
/// automática — a diferencia de `textCapitalization` (que solo evita
/// que el teclado proponga mayúscula), esto reescribe el valor real.
/// Uso: login/registro, en todos los campos excepto contraseña y
/// confirmar contraseña (pedido explícito del usuario).
class LowerCaseTextFormatter extends TextInputFormatter {
  const LowerCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase(), selection: newValue.selection);
  }
}

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  // Por defecto NUNCA se pone en mayúscula la primera letra sola (el
  // comportamiento típico del teclado en "sentences"/"words") — pedido
  // explícito del usuario: al empezar a escribir en cualquier campo (no
  // solo contraseñas) el texto debe quedar tal cual se escribe, en
  // minúscula, sin que el teclado la convierta a mayúscula por su
  // cuenta. Las contraseñas ya funcionan así por defecto (necesitan
  // poder tener mayúsculas Y minúsculas exactamente como se tipeen).
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
        ),
      ],
    );
  }
}

/// Lista desplegable con buscador: al escribir ("co") solo quedan las
/// opciones que EMPIEZAN con esas letras (Colombia, Comoras, Congo...).
/// Mismo aspecto que [AppDropdown] (etiqueta arriba, ancho completo).
class AppSearchDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;

  const AppSearchDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownMenu<String>(
          // La key con el valor reinicia el texto si cambia desde afuera.
          key: ValueKey('$label-$value'),
          initialSelection: value,
          expandedInsets: EdgeInsets.zero, // ancho completo
          hintText: hint,
          enableFilter: true, // filtra por "empieza con"
          enableSearch: false,
          requestFocusOnTap: true,
          menuHeight: 280,
          // Solo vista: orden alfabético y primera letra en mayúscula.
          dropdownMenuEntries: [
            for (final e in sortedAlpha<String>(items, (s) => s))
              DropdownMenuEntry<String>(value: e, label: capitalizeFirst(e)),
          ],
          onSelected: onChanged,
        ),
      ],
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final String? hint;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          hint: hint != null ? Text(hint!) : null,
          // Solo vista: orden alfabético y primera letra en mayúscula.
          items: sortedAlpha<T>(items, labelBuilder)
              .map((e) => DropdownMenuItem<T>(value: e, child: Text(capitalizeFirst(labelBuilder(e)))))
              .toList(),
          onChanged: onChanged,
          dropdownColor: Theme.of(context).colorScheme.surface,
        ),
      ],
    );
  }
}
