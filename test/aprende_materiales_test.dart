import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hersite_core/screens/aprende_screen.dart';
import 'package:hersite_core/widgets/material_aprende_dialog.dart';

void main() {
  testWidgets('Las cuatro infografías abren su imagen en un popup', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AprendeScreen()));
    for (final archivo in [
      'alimentacion',
      'posturas_dormir',
      'movimientos_bebe',
      'reducir_riesgo_preeclampsia',
    ]) {
      final ruta = 'assets/aprende/infografias/$archivo.jpeg';
      final tarjeta = find.byKey(ValueKey(ruta));
      await tester.scrollUntilVisible(tarjeta, 200);
      expect(
        find.descendant(of: tarjeta, matching: find.text('Infografía')),
        findsOneWidget,
      );
      final mirar = find.descendant(of: tarjeta, matching: find.text('Mirar'));
      await tester.ensureVisible(mirar);
      await tester.tap(mirar);
      await tester.pumpAndSettle();
      expect(find.byType(MaterialAprendeDialog), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      final imagen = tester.widget<Image>(
        find.descendant(
          of: find.byType(MaterialAprendeDialog),
          matching: find.byType(Image),
        ),
      );
      expect((imagen.image as AssetImage).assetName, ruta);
      expect(find.text('Leer'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Cómo reducir el riesgo de preeclampsia'), findsOneWidget);
    expect(find.text('Cómo prevenir la preeclampsia'), findsNothing);
  });

  testWidgets('Los dos audios conservan el botón Escuchar y su MP3', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AprendeScreen()));
    for (final archivo in ['senales_alarma', 'control_prenatal']) {
      final tarjeta = find.byKey(
        ValueKey('assets/aprende/audios/$archivo.mp3'),
      );
      await tester.scrollUntilVisible(tarjeta, 150);
      expect(
        find.descendant(of: tarjeta, matching: find.text('Audio')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tarjeta, matching: find.text('Escuchar')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tarjeta, matching: find.text('Completado')),
        findsNothing,
      );
    }
  });
}
