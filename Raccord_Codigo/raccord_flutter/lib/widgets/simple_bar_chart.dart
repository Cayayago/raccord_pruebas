import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widgets de gráficos MUY simples, sin ninguna librería externa
/// (evita el riesgo de choques de dependencias que ya se vio con
/// "excel" vs "pdfrx" — ver pubspec.yaml). Pensados para el resumen del
/// Dashboard del proyecto: barras horizontales animadas + tarjetas de
/// una sola cifra, en colores suaves (pedido explícito del usuario:
/// "colores no tan fuertes").

/// Una fila del gráfico de barras: etiqueta, valor y color.
class BarChartEntry {
  final String label;
  final int value;
  final Color color;
  const BarChartEntry({required this.label, required this.value, required this.color});
}

/// Tarjeta con título + gráfico de barras horizontales, cada una con
/// su etiqueta y cifra a la derecha. Si todos los valores son 0 (o no
/// hay datos), muestra un mensaje vacío en vez de barras planas.
class BarChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<BarChartEntry> entries;
  final String emptyMessage;

  const BarChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.entries,
    this.emptyMessage = 'Todavía no hay datos suficientes.',
  });

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    final maxValue = entries.isEmpty ? 0 : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.grisMedio),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(emptyMessage, style: const TextStyle(color: AppColors.grisMedio, fontSize: 12)),
            )
          else
            ...entries.map((e) => _BarRow(entry: e, maxValue: maxValue)),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final BarChartEntry entry;
  final int maxValue;
  const _BarRow({required this.entry, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final factor = maxValue == 0 ? 0.0 : (entry.value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            child: Text(entry.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(7)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: factor),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(color: entry.color, borderRadius: BorderRadius.circular(7)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text('${entry.value}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una sola cifra (ej. "Días Dramáticos: 12") con ícono y
/// color suave de fondo — para métricas que no necesitan un gráfico de
/// barras completo.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                Text(label, style: const TextStyle(color: AppColors.grisMedio, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
