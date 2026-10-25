import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuiaApp {
  static Future<void> preparar(int perfilId) async {
    await (await SharedPreferences.getInstance()).setBool(
      'guia_pendiente_$perfilId',
      true,
    );
  }

  static Future<bool> pendiente(int perfilId) async =>
      (await SharedPreferences.getInstance()).getBool(
        'guia_pendiente_$perfilId',
      ) ==
      true;

  static Future<void> completar(int perfilId) async {
    await (await SharedPreferences.getInstance()).setBool(
      'guia_pendiente_$perfilId',
      false,
    );
  }
}

/// Cada paso apunta al control real, no a una copia dentro de un diálogo.
class PasoGuia {
  const PasoGuia({
    required this.objetivo,
    required this.titulo,
    required this.texto,
    this.margen = const EdgeInsets.all(5),
  });

  final GlobalKey objetivo;
  final String titulo;
  final String texto;
  final EdgeInsets margen;
}

class GuiaAppRecorrido extends StatefulWidget {
  const GuiaAppRecorrido({super.key, required this.pasos})
    : assert(pasos.length > 0);

  final List<PasoGuia> pasos;

  /// True solo cuando la usuaria termina u omite expresamente la guía.
  static Future<bool> mostrar(
    BuildContext context, {
    required List<PasoGuia> pasos,
  }) async {
    if (pasos.isEmpty) return false;
    return await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 150),
          pageBuilder: (_, _, _) => GuiaAppRecorrido(pasos: pasos),
        ) ??
        false;
  }

  @override
  State<GuiaAppRecorrido> createState() => _GuiaAppRecorridoState();
}

class _GuiaAppRecorridoState extends State<GuiaAppRecorrido>
    with WidgetsBindingObserver {
  static const _verde = Color(0xFF306339);
  static const _fondo = Color(0xFFFBFFFB);
  final _superficie = GlobalKey();
  int _paso = 0;
  int _revision = 0;
  Rect? _objetivo;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ubicarObjetivo();
  }

  @override
  void dispose() {
    _revision++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _reubicar();

  @override
  void didChangeTextScaleFactor() => _reubicar();

  void _reubicar() {
    if (!mounted || _cerrando) return;
    setState(() => _objetivo = null);
    _ubicarObjetivo();
  }

  Future<void> _ubicarObjetivo() async {
    final revision = ++_revision;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || revision != _revision) return;
    final paso = widget.pasos[_paso];
    final destino = paso.objetivo.currentContext;
    if (destino == null || !destino.mounted) {
      // No marcar como vista una guía que no pudo mostrar sus controles.
      _terminar(completada: false);
      return;
    }
    await Scrollable.ensureVisible(destino, alignment: 0.5);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || revision != _revision) return;
    final caja = paso.objetivo.currentContext?.findRenderObject();
    final superficie = _superficie.currentContext?.findRenderObject();
    if (caja is! RenderBox ||
        !caja.attached ||
        !caja.hasSize ||
        superficie is! RenderBox ||
        !superficie.hasSize) {
      _terminar(completada: false);
      return;
    }
    final posicion = superficie.globalToLocal(caja.localToGlobal(Offset.zero));
    final rect = paso.margen
        .inflateRect(posicion & caja.size)
        .intersect(Offset.zero & superficie.size);
    if (rect.isEmpty) {
      _terminar(completada: false);
      return;
    }
    setState(() => _objetivo = rect);
  }

  void _cambiarPaso(int siguiente) {
    if (_objetivo == null || _cerrando) return;
    if (siguiente == widget.pasos.length) {
      _terminar();
      return;
    }
    setState(() {
      _paso = siguiente;
      _objetivo = null;
    });
    _ubicarObjetivo();
  }

  void _terminar({bool completada = true}) {
    if (_cerrando) return;
    _cerrando = true;
    Navigator.of(context).pop(completada);
  }

  Widget _globo(PasoGuia paso) => LayoutBuilder(
    builder: (context, limites) {
      final texto = Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Conoce tu app · ${_paso + 1} de ${widget.pasos.length}',
              style: const TextStyle(color: _verde, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              header: true,
              child: Text(
                paso.titulo,
                style: const TextStyle(
                  color: _verde,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              paso.texto,
              style: const TextStyle(
                fontSize: 17,
                height: 1.35,
                color: Color(0xFF253D2A),
              ),
            ),
          ],
        ),
      );
      final acciones = Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            if (_paso > 0) ...[
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _verde,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _cambiarPaso(_paso - 1),
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _verde,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => _cambiarPaso(_paso + 1),
                child: Text(
                  _paso == widget.pasos.length - 1 ? 'Entendido' : 'Siguiente',
                ),
              ),
            ),
          ],
        ),
      );
      // Con muy poco alto (por ejemplo, en horizontal), todo el globo
      // se puede desplazar. El objetivo y «Omitir guía» siguen accesibles.
      if (limites.maxHeight < 180) {
        return SingleChildScrollView(
          key: ValueKey('guia_texto_$_paso'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [texto, acciones],
          ),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              key: ValueKey('guia_texto_$_paso'),
              child: texto,
            ),
          ),
          acciones,
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final paso = widget.pasos[_paso];
    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(
          key: _superficie,
          child: LayoutBuilder(
            builder: (context, limites) {
              final rect = _objetivo;
              final padding = MediaQuery.paddingOf(context);
              final ancho = math.min(360.0, limites.maxWidth - 32);
              final omitirArriba = rect == null || rect.top >= padding.top + 72;
              final arriba = rect == null
                  ? 0.0
                  : math.max(
                      0.0,
                      rect.top - padding.top - 24 - (omitirArriba ? 64 : 0),
                    );
              final abajo = rect == null
                  ? 0.0
                  : math.max(
                      0.0,
                      limites.maxHeight -
                          padding.bottom -
                          rect.bottom -
                          24 -
                          (omitirArriba ? 0 : 64),
                    );
              final globoArriba = arriba > abajo;
              final izquierda = rect == null
                  ? 16.0
                  : (rect.center.dx - ancho / 2).clamp(
                      16.0,
                      limites.maxWidth - ancho - 16,
                    );
              return Stack(
                children: [
                  // No deja abrir pantallas ni llamar al señalar Emergencia.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: CustomPaint(
                        painter: GuiaSpotlightPainter(objetivo: rect),
                      ),
                    ),
                  ),
                  if (rect != null) ...[
                    Positioned.fromRect(
                      rect: rect,
                      child: Semantics(
                        button: true,
                        label: '${paso.titulo}. Toca para continuar.',
                        child: GestureDetector(
                          key: const ValueKey('guia_objetivo'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _cambiarPaso(_paso + 1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: izquierda,
                      width: ancho,
                      top: globoArriba ? null : rect.bottom + 12,
                      bottom: globoArriba
                          ? limites.maxHeight - rect.top + 12
                          : null,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: globoArriba ? arriba : abajo,
                        ),
                        child: Material(
                          key: ValueKey('guia_globo_$_paso'),
                          color: _fondo,
                          elevation: 8,
                          shadowColor: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: _globo(paso),
                        ),
                      ),
                    ),
                    Positioned(
                      left:
                          rect.center.dx.clamp(
                            izquierda + 20,
                            izquierda + ancho - 20,
                          ) -
                          10,
                      top: globoArriba ? rect.top - 12 : rect.bottom + 2,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(20, 10),
                          painter: _PuntaGlobo(arriba: !globoArriba),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    top: omitirArriba ? padding.top + 8 : null,
                    bottom: omitirArriba ? null : padding.bottom + 8,
                    right: 12,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: _fondo,
                        foregroundColor: _verde,
                      ),
                      onPressed: _terminar,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Omitir guía'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Pinta solo lo que rodea al objetivo; el hueco conserva sus colores reales.
class GuiaSpotlightPainter extends CustomPainter {
  const GuiaSpotlightPainter({required this.objetivo});

  final Rect? objetivo;

  @override
  void paint(Canvas canvas, Size size) {
    final hueco = objetivo == null
        ? null
        : RRect.fromRectAndRadius(objetivo!, const Radius.circular(14));
    final sombra = Path()..fillType = PathFillType.evenOdd;
    sombra.addRect(Offset.zero & size);
    if (hueco != null) sombra.addRRect(hueco);
    canvas.drawPath(sombra, Paint()..color = const Color(0xB3000000));
    if (hueco != null) {
      canvas.drawRRect(
        hueco,
        Paint()
          ..color = const Color(0xFFB9E5AC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(GuiaSpotlightPainter oldDelegate) =>
      oldDelegate.objetivo != objetivo;
}

class _PuntaGlobo extends CustomPainter {
  const _PuntaGlobo({required this.arriba});
  final bool arriba;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, arriba ? size.height : 0)
      ..lineTo(size.width / 2, arriba ? 0 : size.height)
      ..lineTo(size.width, arriba ? size.height : 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFBFFFB));
  }

  @override
  bool shouldRepaint(_PuntaGlobo oldDelegate) => oldDelegate.arriba != arriba;
}
