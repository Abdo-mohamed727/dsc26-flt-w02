import 'package:flutter/material.dart';

import '../../../domain/models/stock_alert.dart';
import '../view_models/alerts_view_model.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.viewModel});

  final AlertsViewModel viewModel;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Stock alerts'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${vm.unacknowledgedCriticalCount}',
                    key: const Key('unacknowledgedCriticalCount'),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  key: const Key('searchField'),
                  decoration: const InputDecoration(
                    hintText: 'Search medicines or branch',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: vm.setQuery,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final severity in Severity.values)
                      FilterChip(
                        key: Key('filter_${severity.name}'),
                        label: Text(_labelFor(severity)),
                        selected: vm.activeFilters.contains(severity),
                        onSelected: (_) => vm.toggleFilter(severity),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _body(vm)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(AlertsViewModel vm) {
    if (vm.loading && vm.visibleAlerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null && vm.visibleAlerts.isEmpty) {
      return Center(child: Text('Could not load alerts.\n${vm.error}'));
    }
    if (vm.visibleAlerts.isEmpty) {
      return const Center(child: Text('No alerts'));
    }
    return ListView.builder(
      itemCount: vm.visibleAlerts.length,
      itemBuilder: (context, index) {
        final alert = vm.visibleAlerts[index];
        return ListTile(
          key: Key('alert_${alert.id}'),
          title: Text(alert.medicineNameEn),
          subtitle: Text(
            '${alert.medicineNameAr} · ${alert.branchCode} · '
            '${alert.daysOfCover} days · ${_labelFor(alert.severity)}',
          ),
          trailing: alert.acknowledged
              ? const Text('Looked at')
              : TextButton(
                  key: Key('acknowledge_${alert.id}'),
                  onPressed: () => vm.acknowledge(alert.id),
                  child: const Text('Acknowledge'),
                ),
        );
      },
    );
  }

  static String _labelFor(Severity severity) {
    final name = severity.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}
