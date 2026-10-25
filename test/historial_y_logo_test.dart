import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hersite_core/screens/historial_screen.dart';
import 'package:hersite_core/widgets/app_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('Historial muestra la flecha y vuelve a la pantalla anterior', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialScreen()),
              ),
              child: const Text('Abrir historial'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir historial'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Volver'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir historial'), findsOneWidget);
    expect(find.byType(HistorialScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('La flecha también es visible cuando Historial es la raíz', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HistorialScreen()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Logo conserva el círculo completo y el tamaño solicitado', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppLogo(size: 120))),
      ),
    );
    await tester.pumpAndSettle();
    final logo = tester.widget<Image>(find.byType(Image));
    expect(logo.fit, BoxFit.contain);
    expect(tester.getSize(find.byType(Image)), const Size(120, 120));
    expect(find.byType(ClipOval), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'Icono adaptativo conserva todo el emblema dentro de la zona segura',
    () async {
      final codec = await ui.instantiateImageCodec(
        await File(
          'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png',
        ).readAsBytes(),
      );
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 432);
      expect(image.height, 432);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var maxRadius = 0.0;
      var visible = 0;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          if (data.getUint8((y * image.width + x) * 4 + 3) > 32) {
            visible++;
            maxRadius = math.max(
              maxRadius,
              math.sqrt(math.pow(x - 215.5, 2) + math.pow(y - 215.5, 2)),
            );
          }
        }
      }
      expect(visible, greaterThan(10000));
      expect(maxRadius, lessThanOrEqualTo(432 * 33 / 108));
      expect(data.getUint8(3), 0);
      image.dispose();
      codec.dispose();
    },
  );

  test('El icono Android es opaco', () async {
    final encoded = await File(
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    ).readAsBytes();
    final codec = await ui.instantiateImageCodec(encoded);
    final image = (await codec.getNextFrame()).image;
    expect(image.width, 192);
    expect(image.height, 192);
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    expect(data.getUint8(3), 255);
    image.dispose();
    codec.dispose();
  });
}
