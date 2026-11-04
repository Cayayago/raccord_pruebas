import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra de paginación reutilizable: flechas anterior/siguiente, texto
/// "Página X de Y · N registro(s)" y selector de cuántos registros ver
/// por página (10/20/30 por defecto) — mismo componente en todas las
/// pantallas que paginan listas (Escenas, Plan de Rodaje, y las que
/// vengan después), para no repetir esta lógica en cada pantalla.
///
/// [page] es 0-based. El padre es dueño del estado (page/pageSize) y
/// reacciona a [onPageChanged]/[onPageSizeChanged] — este widget no
/// guarda nada por su cuenta.
class PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizeOptions;
  final String itemLabel;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.pageSizeOptions = const [10, 20, 30],
    this.itemLabel = 'registro(s)',
  });

  @override
  Widget build(BuildContext context) {
    // `SizedBox(width: infinity)` fuerza a ocupar todo el ancho
    // disponible (aunque el padre sea un Column sin `stretch`), y recién
    // ahí `Center` puede centrar el Wrap de verdad — si no, Center se
    // encoge a su contenido y la barra queda pegada a la izquierda.
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
            ),
            Text(
              'Página ${page + 1} de $totalPages · $totalItems $itemLabel',
              style: const TextStyle(fontSize: 11, color: AppColors.grisMedio, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: page < totalPages - 1 ? () => onPageChanged(page + 1) : null,
            ),
            const SizedBox(width: 12),
            _PageSizeDropdown(value: pageSize, options: pageSizeOptions, onChanged: onPageSizeChanged),
          ],
        ),
      ),
    );
  }
}

class _PageSizeDropdown extends StatelessWidget {
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;
  const _PageSizeDropdown({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Si el pageSize actual no está en las opciones (ej. quedó guardado
    // un valor viejo), se agrega para que DropdownButton no truene por
    // un value fuera de items.
    final items = options.contains(value) ? options : ([...options, value]..sort());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: AppColors.grisMedio, fontWeight: FontWeight.w600),
          items: items.map((n) => DropdownMenuItem(value: n, child: Text('$n / pág.'))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
