import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/session.dart';
import '../../services/audit_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/mobile_refresh.dart';
import '../../widgets/state_views.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  late Future<Map<String, dynamic>> _future;
  final _actionController = TextEditingController();
  final _moduleController = TextEditingController();
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    final session = context.read<AuthSession>();
    return AuditService(session.api).listar(
      page: _page,
      limit: 20,
      action: _actionController.text.trim(),
      module: _moduleController.text.trim(),
    );
  }

  void _reload() {
    setState(() {
      _page = 1;
      _future = _load();
    });
  }

  void _changePage(int page) {
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {}
  }

  String _dateLabel(dynamic value) {
    if (value == null) return 'Fecha no disponible';
    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return value.toString();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  @override
  void dispose() {
    _actionController.dispose();
    _moduleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();

    if (!session.can('view_audit_logs')) {
      return const AppScaffold(
        title: 'Auditoría',
        showBack: true,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
                'No tienes permiso para consultar los registros de auditoría.'),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Auditoría y trazabilidad',
      showBack: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _actionController,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por acción',
                    hintText: 'Ej. login_failed',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _reload(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _moduleController,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por módulo',
                    hintText: 'Ej. auth',
                    prefixIcon: Icon(Icons.folder_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _reload(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Aplicar filtros'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }

                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final message = error is ApiException
                      ? error.message
                      : 'No se pudieron cargar los registros de auditoría.';
                  return ErrorView(message: message, onRetry: _reload);
                }

                final data = snapshot.data ?? {};
                final items = (data['items'] as List? ?? [])
                    .whereType<Map<String, dynamic>>()
                    .toList();
                final pagination =
                    data['pagination'] as Map<String, dynamic>? ?? {};
                final total = int.tryParse('${pagination['total'] ?? 0}') ?? 0;
                final pages = int.tryParse('${pagination['pages'] ?? 0}') ?? 0;

                if (items.isEmpty) {
                  return MobileRefresh(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        EmptyView(
                          message:
                              'No hay registros de auditoría para mostrar.',
                          icon: Icons.fact_check_outlined,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Registros encontrados: $total'),
                      ),
                    ),
                    Expanded(
                      child: MobileRefresh(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final success = item['success'] == true;
                            final details = item['details'];
                            return Card(
                              child: ExpansionTile(
                                leading: Icon(
                                  success
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline,
                                  color: success ? Colors.green : Colors.red,
                                ),
                                title: Text(
                                  '${item['action'] ?? 'Evento'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${item['user'] ?? 'Usuario no disponible'}'
                                  ' · ${item['module'] ?? 'Sin módulo'}\n'
                                  '${_dateLabel(item['created_at'])}',
                                ),
                                childrenPadding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                children: [
                                  _detail('Proyecto', item['project']),
                                  _detail('Entidad', item['entity_type']),
                                  _detail('ID de entidad', item['entity_id']),
                                  _detail('Dirección IP', item['ip_address']),
                                  _detail(
                                    'Resultado',
                                    success ? 'Correcto' : 'Fallido',
                                  ),
                                  if (details != null)
                                    _detail(
                                      'Detalles',
                                      details is Map || details is List
                                          ? details.toString()
                                          : details.toString(),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (pages > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Página anterior',
                              onPressed: _page > 1
                                  ? () => _changePage(_page - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('Página $_page de $pages'),
                            IconButton(
                              tooltip: 'Página siguiente',
                              onPressed: _page < pages
                                  ? () => _changePage(_page + 1)
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SelectableText('$label: $value'),
      ),
    );
  }
}
