import 'package:flutter/material.dart';

import 'data/repositories/alert_repository.dart';
import 'ui/alerts/view_models/alerts_view_model.dart';
import 'ui/alerts/widgets/alerts_screen.dart';

void main() {
  runApp(const NourShelfApp());
}

class NourShelfApp extends StatefulWidget {
  const NourShelfApp({super.key, this.repository});

  final AlertRepository? repository;

  @override
  State<NourShelfApp> createState() => _NourShelfAppState();
}

class _NourShelfAppState extends State<NourShelfApp> {
  late final AlertsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AlertsViewModel(
      repository: widget.repository ?? InMemoryAlertRepository(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nour's Pharmacy",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: AlertsScreen(viewModel: _viewModel),
    );
  }
}
