import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MaterialAprendeDialog extends StatefulWidget {
  const MaterialAprendeDialog({
    super.key,
    required this.titulo,
    required this.archivo,
    required this.esAudio,
  });

  final String titulo;
  final String archivo;
  final bool esAudio;

  @override
  State<MaterialAprendeDialog> createState() => _MaterialAprendeDialogState();
}

class _MaterialAprendeDialogState extends State<MaterialAprendeDialog>
    with WidgetsBindingObserver {
  static const _verde = Color(0xFF306339);
  AudioPlayer? _player;
  final _suscripciones = <StreamSubscription<dynamic>>[];
  Duration _duracion = Duration.zero;
  Duration _posicion = Duration.zero;
  bool _reproduciendo = false;
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.esAudio) return;
    WidgetsBinding.instance.addObserver(this);
    final player = _player = AudioPlayer();
    _suscripciones.addAll([
      player.onDurationChanged.listen((valor) {
        if (mounted) setState(() => _duracion = valor);
      }, onError: _falloAudio),
      player.onPositionChanged.listen((valor) {
        if (mounted) setState(() => _posicion = valor);
      }, onError: _falloAudio),
      player.onPlayerStateChanged.listen((estado) {
        if (mounted) {
          setState(() => _reproduciendo = estado == PlayerState.playing);
        }
      }, onError: _falloAudio),
    ]);
    unawaited(_alternarAudio());
  }

  void _falloAudio(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _reproduciendo = false;
      _error = 'No pudimos reproducir el audio. Intenta otra vez.';
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _player != null) {
      unawaited(_pausar());
    }
  }

  Future<void> _pausar() async {
    try {
      await _player?.pause();
    } catch (_) {
      // Puede coincidir con el cierre del reproductor.
    }
  }

  Future<void> _alternarAudio() async {
    final player = _player;
    if (player == null || _ocupado) return;
    final reintentar = _error != null;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      if (_reproduciendo) {
        await player.pause();
      } else if (player.source == null ||
          player.state == PlayerState.completed ||
          reintentar) {
        await player.play(AssetSource(widget.archivo.substring(7)));
      } else {
        await player.resume();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos reproducir el audio. Intenta otra vez.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _moverAudio(double milisegundos) async {
    try {
      await _player?.seek(Duration(milliseconds: milisegundos.round()));
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pudimos mover el audio. Intenta otra vez.');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final suscripcion in _suscripciones) {
      unawaited(suscripcion.cancel());
    }
    final player = _player;
    if (player != null) unawaited(player.dispose());
    super.dispose();
  }

  String _tiempo(Duration valor) =>
      '${valor.inMinutes}:${(valor.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _audio() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.headphones, size: 72, color: _verde),
        const SizedBox(height: 16),
        Slider(
          activeColor: _verde,
          max: _duracion.inMilliseconds > 0
              ? _duracion.inMilliseconds.toDouble()
              : 1,
          value: _posicion.inMilliseconds.toDouble().clamp(
            0,
            _duracion.inMilliseconds.toDouble(),
          ),
          onChanged: _duracion > Duration.zero && !_ocupado
              ? _moverAudio
              : null,
          semanticFormatterCallback: (valor) =>
              _tiempo(Duration(milliseconds: valor.round())),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(_tiempo(_posicion)), Text(_tiempo(_duracion))],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _verde,
            foregroundColor: Colors.white,
          ),
          onPressed: _ocupado ? null : _alternarAudio,
          icon: _ocupado
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_reproduciendo ? Icons.pause : Icons.play_arrow),
          label: Text(_reproduciendo ? 'Pausar' : 'Reproducir'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFFFBFFFB),
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _verde,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _verde),
                ),
              ],
            ),
          ),
          if (widget.esAudio)
            Flexible(child: SingleChildScrollView(child: _audio()))
          else ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'Desliza para ver toda la imagen. Usa dos dedos para ampliarla.',
                style: TextStyle(color: _verde, fontSize: 13),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: SingleChildScrollView(
                  child: Image.asset(
                    widget.archivo,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    semanticLabel: widget.titulo,
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No pudimos abrir la imagen. Intenta otra vez.',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
