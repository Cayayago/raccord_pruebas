import 'package:flutter/material.dart';

import '../models/character.dart';
import '../theme/app_theme.dart';

/// Campo de texto con autocompletado de personajes ya creados en el
/// proyecto: al escribir (ej. "Ma") sugiere personajes cuyo nombre o
/// código de personaje contengan ese texto (ej. "María", "Martha", o
/// "PERS-003"), sin importar mayúsculas/minúsculas.
///
/// Se usa en dos lugares de Continuidad Visual: para añadir personajes
/// al cast de la escena, y para el campo "Personaje" al subir una foto.
/// En ambos casos el llamador decide qué hacer con el [CharacterModel]
/// elegido a través de [onSelected] — este widget solo se encarga de
/// sugerir y no asume nada sobre a dónde va el resultado.
class CharacterAutocompleteField extends StatelessWidget {
  final String label;
  final String? hint;
  final List<CharacterModel> personajes;
  final void Function(CharacterModel personaje) onSelected;
  // Texto inicial del campo (ej. al editar algo que ya tenía un
  // personaje asignado) — sin esto el campo siempre arranca vacío,
  // que es lo que se quiere al SUBIR una foto nueva pero no al editar
  // una ya existente (ver photo_viewer_dialog.dart).
  final String? initialValue;

  const CharacterAutocompleteField({
    super.key,
    required this.label,
    required this.personajes,
    required this.onSelected,
    this.hint,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Autocomplete<CharacterModel>(
          displayStringForOption: (p) => p.nombre,
          initialValue: TextEditingValue(text: initialValue ?? ''),
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            if (q.isEmpty) return const Iterable<CharacterModel>.empty();
            return personajes.where(
              (p) => p.nombre.toLowerCase().contains(q) || p.codigoPersonaje.toLowerCase().contains(q),
            );
          },
          onSelected: onSelected,
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(hintText: hint ?? 'Nombre o código del personaje...'),
            );
          },
          optionsViewBuilder: (context, onSelectedOption, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceVariant,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: 340),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final p = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        title: Text(p.nombre),
                        subtitle: Text(p.codigoPersonaje),
                        onTap: () => onSelectedOption(p),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
