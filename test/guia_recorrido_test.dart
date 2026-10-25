import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hersite_core/widgets/guia_app_dialog.dart';

class _PantallaPrueba extends StatelessWidget {
  const _PantallaPrueba({
    required this.objetivos,
    required this.alTocarFuncion,
    required this.alCerrar,
  });

  final List<GlobalKey> objetivos;
  final VoidCallback alTocarFuncion;
  final ValueChanged<bool> alCerrar;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            key: objetivos[0],
            height: 100,
            color: const Color(0xFF5A845C),
            child: const Center(child: Text('Tu embarazo')),
          ),
          TextButton(
            onPressed: () async {
              final resultado = await GuiaAppRecorrido.mostrar(
                context,
                pasos: List.generate(
                  objetivos.length,
                  (i) => PasoGuia(
                    objetivo: objetivos[i],
                    titulo: 'Función ${i + 1}',
                    texto:
                        'Aquí puedes ver y usar esta función de la app. Toca la parte iluminada para continuar.',
                  ),
                ),
              );
              alCerrar(resultado);
            },
            child: const Text('Ver guía'),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 240),
                  for (var i = 1; i < 6; i++)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        key: objetivos[i],
                        width: double.infinity,
                        height: 96,
                        child: ElevatedButton(
                          onPressed: alTocarFuncion,
                          child: Text('Botón $i'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, key: objetivos[6]),
          label: 'Perfil',
        ),
      ],
    ),
  );
}

Future<List<GlobalKey>> _abrir(
  WidgetTester tester, {
  double escala = 1,
  VoidCallback? alTocarFuncion,
  ValueChanged<bool>? alCerrar,
}) async {
  final objetivos = List.generate(7, (_) => GlobalKey());
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: _PantallaPrueba(
        objetivos: objetivos,
        alTocarFuncion: alTocarFuncion ?? () {},
        alCerrar: alCerrar ?? (_) {},
      ),
    ),
  );
  await tester.tap(find.text('Ver guía'));
  await tester.pumpAndSettle();
  return objetivos;
}

GuiaSpotlightPainter _pintura(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<GuiaSpotlightPainter>()
    .single;

void _comprobarPosicion(WidgetTester tester, GlobalKey objetivo, int paso) {
  final iluminado = _pintura(tester).objetivo!;
  final control = tester.getRect(find.byKey(objetivo));
  final pantalla =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(iluminado.contains(control.center), true);
  expect(iluminado, control.inflate(5).intersect(pantalla));
  final globo = tester.getRect(find.byKey(ValueKey('guia_globo_$paso')));
  expect(globo.overlaps(iluminado), false);
  expect(globo.left, greaterThanOrEqualTo(pantalla.left));
  expect(globo.right, lessThanOrEqualTo(pantalla.right));
  expect(globo.top, greaterThanOrEqualTo(pantalla.top));
  expect(globo.bottom, lessThanOrEqualTo(pantalla.bottom));
}

void main() {
  testWidgets('Señala controles reales, permite volver y termina siete pasos', (
    tester,
  ) async {
    bool? completada;
    var acciones = 0;
    final objetivos = await _abrir(
      tester,
      alTocarFuncion: () => acciones++,
      alCerrar: (valor) => completada = valor,
    );
    expect(find.byType(AlertDialog), findsNothing);
    _comprobarPosicion(tester, objetivos[0], 0);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    _comprobarPosicion(tester, objetivos[1], 1);
    await tester.tap(find.text('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Función 1'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      _comprobarPosicion(tester, objetivos[i], i);
      await tester.tap(find.byKey(const ValueKey('guia_objetivo')));
      await tester.pumpAndSettle();
    }
    _comprobarPosicion(tester, objetivos[6], 6);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.byType(GuiaAppRecorrido), findsNothing);
    expect(completada, true);
    expect(acciones, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El fondo no responde a toques y se puede omitir', (
    tester,
  ) async {
    bool? completada;
    await _abrir(tester, alCerrar: (valor) => completada = valor);
    await tester.tapAt(const Offset(10, 400));
    await tester.pumpAndSettle();
    expect(find.text('Función 1'), findsOneWidget);
    await tester.tap(find.text('Omitir guía'));
    await tester.pumpAndSettle();
    expect(completada, true);
    expect(find.byType(GuiaAppRecorrido), findsNothing);
  });

  for (final tamano in [const Size(360, 640), const Size(640, 360)]) {
    testWidgets('Letra grande y globos dentro de pantalla $tamano', (
      tester,
    ) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final objetivos = await _abrir(tester, escala: 1.6);
      for (var i = 0; i < 7; i++) {
        _comprobarPosicion(tester, objetivos[i], i);
        await tester.tap(find.byKey(const ValueKey('guia_objetivo')));
        await tester.pumpAndSettle();
      }
      expect(find.byType(GuiaAppRecorrido), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Reubica el globo cuando cambia el tamaño de pantalla', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final objetivos = await _abrir(tester);
    await tester.tap(find.byKey(const ValueKey('guia_objetivo')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(640, 360);
    await tester.pumpAndSettle();
    _comprobarPosicion(tester, objetivos[1], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Un objetivo ausente no se da por explicado', (tester) async {
    bool? completada;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              completada = await GuiaAppRecorrido.mostrar(
                context,
                pasos: [
                  PasoGuia(
                    objetivo: GlobalKey(),
                    titulo: 'No existe',
                    texto: 'No debe marcarse como visto.',
                  ),
                ],
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(completada, false);
    expect(find.byType(GuiaAppRecorrido), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
