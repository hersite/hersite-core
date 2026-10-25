import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hersite_core/main.dart';
import 'package:hersite_core/screens/inicio_screen.dart';

void main() {
  testWidgets('Nuvia abre la bienvenida cuando no hay una cuenta activa', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const MiAppTesis());
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'Nuvia');
    expect(find.byType(InicioPrimer), findsOneWidget);
    expect(find.text('INGRESAR'), findsOneWidget);
    expect(find.text('REGISTRARSE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
