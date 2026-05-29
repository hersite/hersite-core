import 'package:flutter/material.dart';
import 'screens/app_entry_gate.dart';

void main() {
  runApp(const MiAppTesis());
}

class MiAppTesis extends StatelessWidget {
  const MiAppTesis({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Gestantes',
      home: AppEntryGate(),
    );
  }
}