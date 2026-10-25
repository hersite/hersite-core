import 'package:flutter/material.dart';

/// La imagen ya incluye el círculo; no se recorta ni se añade un segundo borde.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'img/logo_app.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'Logo de la app: mujer embarazada dentro de un círculo',
  );
}
