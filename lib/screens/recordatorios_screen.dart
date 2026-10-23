import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/recordatorio.dart';
import '../services/recordatorios_service.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen>
    with WidgetsBindingObserver {
  static const _verde = Color(0xFF306339);
  late final RecordatoriosService _service;
  List<Recordatorio> _registros = [];
  List<RecordatorioAnterior> _anteriores = [];
  String _filtro = 'Pendientes';
  bool _cargando = true;
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = RecordatoriosService.instance;
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_ocupado && !_cargando) {
      _cargar();
    }
  }

  Future<void> _leerDatos({bool solicitarPermisos = false}) async {
    final registros = await _service.restaurar(
      solicitarPermisos: solicitarPermisos,
    );
    final anteriores = await _service.anterioresSinCuenta();
    if (!mounted) return;
    setState(() {
      _registros = registros;
      _anteriores = anteriores;
      _error = null;
    });
  }

  Future<void> _cargar() async {
    if (_ocupado) return;
    setState(() => _cargando = true);
    try {
      await _leerDatos();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos cargar tus recordatorios. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mensaje(String texto, {bool advertencia = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: const Duration(seconds: 6),
        backgroundColor: advertencia ? Colors.orange.shade900 : _verde,
      ),
    );
  }

  String _mensajeAviso(Recordatorio registro) => switch (registro.estadoAviso) {
    EstadoAviso.sinPermiso =>
      'Guardado sin aviso: habilita las notificaciones y la categoría «Recordatorios de salud» en los ajustes del teléfono. Después pulsa Activar avisos.',
    EstadoAviso.error =>
      'Guardado, pero el aviso no pudo activarse. Pulsa Activar avisos para reintentar.',
    EstadoAviso.aproximado =>
      'Aviso con hora aproximada: Android puede retrasarlo. Para recibirlo a la hora elegida, permite alarmas exactas con Activar avisos.',
    EstadoAviso.pendiente =>
      'Guardado, pero la hora ya pasó. Reprograma el recordatorio para activar otro aviso.',
    _ => 'Recordatorio guardado con su aviso activado.',
  };

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await accion();
      await _leerDatos();
    } on ArgumentError catch (error) {
      _mensaje(error.message.toString(), advertencia: true);
    } catch (_) {
      _mensaje(
        'No se pudo completar el cambio. Revisa el recordatorio e intenta nuevamente.',
        advertencia: true,
      );
      try {
        await _leerDatos();
      } catch (_) {
        if (mounted) {
          setState(() => _error = 'No pudimos actualizar los recordatorios.');
        }
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<_DatosRecordatorio?> _formulario({
    required TipoRecordatorio tipo,
    Recordatorio? registro,
  }) => showModalBottomSheet<_DatosRecordatorio>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FormularioRecordatorio(
      tipo: tipo,
      registro: registro,
      reloj: _service.reloj,
    ),
  );

  Future<void> _crear(TipoRecordatorio tipo) async {
    final datos = await _formulario(tipo: tipo);
    if (datos == null || !mounted) return;
    await _ejecutar(() async {
      final registro = await _service.crear(
        tipo: tipo,
        titulo: datos.titulo,
        fechaHora: datos.fechaHora,
        repeticion: datos.repeticion,
      );
      _mensaje(
        _mensajeAviso(registro),
        advertencia: registro.estadoAviso != EstadoAviso.exacto,
      );
    });
  }

  Future<bool> _confirmar(String titulo, String texto, String aceptar) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(titulo),
          content: Text(texto),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(aceptar),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _cambiarEstado(Recordatorio registro) async {
    DateTime? nuevaFecha;
    if (registro.completado) {
      if (!registro.esDiario && !registro.fechaHora.isAfter(_service.reloj())) {
        final datos = await _formulario(
          tipo: registro.tipo,
          registro: registro,
        );
        if (datos == null || !mounted) return;
        nuevaFecha = datos.fechaHora;
      } else if (!await _confirmar(
        'Volver a pendiente',
        '¿Quieres volver a activar el aviso de ${registro.titulo}?',
        'Activar',
      )) {
        return;
      }
    } else {
      final texto = registro.esDiario
          ? 'Se detendrán todos los avisos diarios de ${registro.titulo}. Puedes reactivarlos desde Completados.'
          : registro.tipo == TipoRecordatorio.pastilla
          ? '¿Ya te tomaste ${registro.titulo}?'
          : '¿Quieres marcar ${registro.titulo} como completada?';
      if (!await _confirmar(
        registro.esDiario ? 'Finalizar repetición diaria' : 'Confirmar',
        texto,
        registro.esDiario ? 'Finalizar' : 'Marcar completado',
      )) {
        return;
      }
    }
    if (!mounted) return;
    await _ejecutar(() async {
      final actualizado = await _service.cambiarEstado(
        registro.id,
        completado: !registro.completado,
        nuevaFecha: nuevaFecha,
      );
      _mensaje(
        actualizado.completado
            ? 'Recordatorio completado. Su aviso está cancelado.'
            : _mensajeAviso(actualizado),
        advertencia:
            !actualizado.completado &&
            actualizado.estadoAviso != EstadoAviso.exacto,
      );
    });
  }

  Future<void> _reprogramar(Recordatorio registro) async {
    final datos = await _formulario(tipo: registro.tipo, registro: registro);
    if (datos == null || !mounted) return;
    await _ejecutar(() async {
      final actualizado = await _service.cambiarEstado(
        registro.id,
        completado: false,
        nuevaFecha: datos.fechaHora,
      );
      _mensaje(
        _mensajeAviso(actualizado),
        advertencia: actualizado.estadoAviso != EstadoAviso.exacto,
      );
    });
  }

  Future<void> _activarAvisos() => _ejecutar(() async {
    final registros = await _service.restaurar(solicitarPermisos: true);
    final fallaron = registros.any(
      (r) =>
          !r.completado &&
          !r.estaVencido(_service.reloj()) &&
          r.requiereAtencion,
    );
    final aproximados = registros.any(
      (r) => !r.completado && r.estadoAviso == EstadoAviso.aproximado,
    );
    _mensaje(
      fallaron
          ? 'Hay avisos sin activar. Revisa los permisos de notificaciones del teléfono.'
          : aproximados
          ? 'Avisos activados con hora aproximada: falta el permiso de alarmas exactas.'
          : 'Avisos revisados y activados para tus recordatorios futuros.',
      advertencia: fallaron || aproximados,
    );
  });

  Future<void> _recuperarAnteriores() async {
    final claves = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _ImportarAnteriores(anteriores: _anteriores),
    );
    if (claves == null || claves.isEmpty || !mounted) return;
    await _ejecutar(() async {
      await _service.importarAnteriores(claves);
      _mensaje(
        'Recordatorios recuperados para tu cuenta. Los vencidos necesitan una nueva fecha.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ahora = _service.reloj();
    final visibles = _registros
        .where(
          (r) =>
              _filtro == 'Todos' ||
              (_filtro == 'Completados' ? r.completado : !r.completado),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          IconButton(
            tooltip: 'Activar avisos',
            onPressed: _ocupado || _cargando ? null : _activarAvisos,
            icon: const Icon(Icons.notifications_active_outlined),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (_ocupado) const LinearProgressIndicator(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          'Tus pastillas y citas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _verde,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Guardados en este teléfono para tu cuenta. Funcionan sin internet.',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: ['Pendientes', 'Completados', 'Todos']
                              .map(
                                (filtro) => ChoiceChip(
                                  label: Text(filtro),
                                  selected: _filtro == filtro,
                                  onSelected: (_) =>
                                      setState(() => _filtro = filtro),
                                ),
                              )
                              .toList(),
                        ),
                        if (_anteriores.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hay recordatorios de una versión anterior sin cuenta asociada.',
                                  ),
                                  TextButton(
                                    onPressed: _ocupado
                                        ? null
                                        : _recuperarAnteriores,
                                    child: const Text(
                                      'Revisar y recuperar los míos',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_registros.any(
                          (r) =>
                              !r.completado &&
                              !r.estaVencido(ahora) &&
                              r.requiereAtencion,
                        ))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Hay recordatorios sin aviso. Pulsa la campana «Activar avisos» para revisar los permisos.',
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        for (final tipo in TipoRecordatorio.values) ...[
                          const SizedBox(height: 24),
                          Text(
                            tipo == TipoRecordatorio.pastilla
                                ? 'MIS PASTILLAS'
                                : 'MIS CITAS MÉDICAS',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _verde,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!visibles.any((r) => r.tipo == tipo))
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No hay recordatorios en esta vista.',
                              ),
                            ),
                          ...visibles
                              .where((r) => r.tipo == tipo)
                              .map((r) => _tarjeta(r, ahora)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _ocupado || _cargando || _error != null
                      ? null
                      : () => _crear(TipoRecordatorio.pastilla),
                  icon: const Icon(Icons.add),
                  label: const Text('Pastilla'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ocupado || _cargando || _error != null
                      ? null
                      : () => _crear(TipoRecordatorio.cita),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Cita'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(Recordatorio registro, DateTime ahora) {
    final vencido = registro.estaVencido(ahora);
    final estado = registro.completado
        ? 'Completado · aviso cancelado'
        : vencido
        ? 'Vencido · elige una nueva fecha para recibir otro aviso'
        : switch (registro.estadoAviso) {
            EstadoAviso.exacto => 'Aviso activado',
            EstadoAviso.aproximado => 'Aviso con hora aproximada',
            EstadoAviso.sinPermiso =>
              'Sin aviso: falta permiso de notificaciones',
            EstadoAviso.error => 'No se pudo activar el aviso',
            EstadoAviso.pendiente => 'Aviso pendiente de activación',
          };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        isThreeLine: true,
        onTap: _ocupado ? null : () => _cambiarEstado(registro),
        leading: Icon(
          registro.tipo == TipoRecordatorio.pastilla
              ? Icons.medication
              : Icons.calendar_month,
          color: _verde,
        ),
        title: Text(
          registro.titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: registro.completado ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              registro.esDiario
                  ? 'Todos los días a las ${DateFormat('HH:mm').format(registro.fechaHora)}'
                  : registro.fechaTexto(ahora),
            ),
            Text(
              estado,
              style: TextStyle(
                color: vencido || registro.requiereAtencion
                    ? Colors.orange.shade900
                    : null,
              ),
            ),
            if (registro.esDiario && !registro.completado)
              const Text('Toca para finalizar la repetición.'),
          ],
        ),
        trailing: registro.completado
            ? const Icon(Icons.check_circle, color: _verde)
            : IconButton(
                tooltip: registro.esDiario ? 'Cambiar hora' : 'Reprogramar',
                onPressed: _ocupado ? null : () => _reprogramar(registro),
                icon: const Icon(Icons.edit_calendar_outlined),
              ),
      ),
    );
  }
}

class _DatosRecordatorio {
  const _DatosRecordatorio(this.titulo, this.fechaHora, this.repeticion);
  final String titulo;
  final DateTime fechaHora;
  final RepeticionRecordatorio repeticion;
}

class _FormularioRecordatorio extends StatefulWidget {
  const _FormularioRecordatorio({
    required this.tipo,
    required this.reloj,
    this.registro,
  });
  final TipoRecordatorio tipo;
  final Recordatorio? registro;
  final DateTime Function() reloj;

  @override
  State<_FormularioRecordatorio> createState() =>
      _FormularioRecordatorioState();
}

class _FormularioRecordatorioState extends State<_FormularioRecordatorio> {
  final _form = GlobalKey<FormState>();
  final _validacion = GlobalKey();
  late final TextEditingController _nombre;
  late RepeticionRecordatorio _repeticion;
  DateTime? _fecha;
  TimeOfDay? _hora;
  String? _errorFecha;
  bool _intentoGuardar = false;

  List<String> get _camposFaltantes => [
    if (_nombre.text.trim().isEmpty) 'nombre',
    if (_repeticion == RepeticionRecordatorio.unaVez && _fecha == null) 'fecha',
    if (_hora == null) 'hora',
  ];

  void _actualizarValidacion() {
    if (_intentoGuardar) {
      setState(() => _errorFecha = null);
    }
  }

  @override
  void initState() {
    super.initState();
    final registro = widget.registro;
    _nombre = TextEditingController(text: registro?.titulo);
    _repeticion = registro?.repeticion ?? RepeticionRecordatorio.unaVez;
    if (registro != null) {
      _hora = TimeOfDay.fromDateTime(registro.fechaHora);
      _fecha = registro.fechaHora.isAfter(widget.reloj())
          ? registro.fechaHora
          : null;
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = widget.reloj();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha != null && !_fecha!.isBefore(hoy) ? _fecha : hoy,
      firstDate: hoy,
      lastDate: DateTime(ahora.year + 10, 12, 31),
    );
    if (elegida != null && mounted) {
      setState(() {
        _fecha = elegida;
        _errorFecha = null;
      });
    }
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.fromDateTime(widget.reloj()),
    );
    if (elegida != null && mounted) {
      setState(() {
        _hora = elegida;
        _errorFecha = null;
      });
    }
  }

  void _guardar() {
    setState(() => _intentoGuardar = true);
    final nombreValido = _form.currentState!.validate();
    if (_camposFaltantes.isNotEmpty || !nombreValido) {
      setState(() => _errorFecha = null);
      FocusScope.of(context).unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final aviso = _validacion.currentContext;
        if (mounted && aviso != null) {
          Scrollable.ensureVisible(
            aviso,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
      return;
    }
    final ahora = widget.reloj();
    final dia = _fecha ?? ahora;
    var fecha = DateTime(
      dia.year,
      dia.month,
      dia.day,
      _hora!.hour,
      _hora!.minute,
    );
    if (_repeticion == RepeticionRecordatorio.diaria) {
      fecha = Recordatorio.siguienteHoraDiaria(fecha, ahora);
    }
    if (!fecha.isAfter(ahora)) {
      setState(
        () => _errorFecha =
            'La fecha y hora deben ser posteriores a la hora actual.',
      );
      return;
    }
    Navigator.pop(
      context,
      _DatosRecordatorio(_nombre.text.trim(), fecha, _repeticion),
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      24,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.registro != null
                ? 'Reprogramar recordatorio'
                : widget.tipo == TipoRecordatorio.pastilla
                ? 'Agregar pastilla'
                : 'Agregar cita',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          if (_intentoGuardar && _camposFaltantes.isNotEmpty)
            Semantics(
              key: _validacion,
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Falta completar: ${_camposFaltantes.join(', ')}. Completa estos campos para continuar.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          TextFormField(
            controller: _nombre,
            readOnly: widget.registro != null,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre'),
            autovalidateMode: _intentoGuardar
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            onChanged: (_) => _actualizarValidacion(),
            validator: (texto) => texto == null || texto.trim().isEmpty
                ? 'Escribe un nombre.'
                : null,
          ),
          if (widget.tipo == TipoRecordatorio.pastilla) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<RepeticionRecordatorio>(
              initialValue: _repeticion,
              decoration: const InputDecoration(labelText: 'Repetición'),
              items: const [
                DropdownMenuItem(
                  value: RepeticionRecordatorio.unaVez,
                  child: Text('Una sola vez'),
                ),
                DropdownMenuItem(
                  value: RepeticionRecordatorio.diaria,
                  child: Text('Todos los días'),
                ),
              ],
              onChanged: widget.registro != null
                  ? null
                  : (valor) => setState(() {
                      _repeticion = valor!;
                      _errorFecha = null;
                    }),
            ),
          ],
          const SizedBox(height: 16),
          if (_repeticion == RepeticionRecordatorio.unaVez)
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Fecha'),
              subtitle: Text(
                _fecha == null
                    ? 'Seleccionar fecha'
                    : DateFormat('dd/MM/yyyy').format(_fecha!),
                style: _intentoGuardar && _fecha == null
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              trailing: _intentoGuardar && _fecha == null
                  ? Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    )
                  : null,
              onTap: _elegirFecha,
            ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Hora (Lima)'),
            subtitle: Text(
              _hora == null ? 'Seleccionar hora' : _hora!.format(context),
              style: _intentoGuardar && _hora == null
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
            trailing: _intentoGuardar && _hora == null
                ? Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  )
                : null,
            onTap: _elegirHora,
          ),
          if (_repeticion == RepeticionRecordatorio.diaria)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'El primer aviso será la próxima vez que llegue esta hora. Se repetirá cada día hasta que finalices el recordatorio.',
              ),
            ),
          if (_errorFecha != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _errorFecha!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardar,
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ImportarAnteriores extends StatefulWidget {
  const _ImportarAnteriores({required this.anteriores});
  final List<RecordatorioAnterior> anteriores;
  @override
  State<_ImportarAnteriores> createState() => _ImportarAnterioresState();
}

class _ImportarAnterioresState extends State<_ImportarAnteriores> {
  final _seleccionados = <String>{};
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Recuperar mis recordatorios'),
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona solo los que te pertenecen. Se guardarán en tu cuenta; los originales se conservarán.',
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: widget.anteriores.map((anterior) {
                String? fecha;
                try {
                  fecha = DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(anterior.fechaHora);
                } catch (_) {
                  /* El original no se elimina si su fecha no se reconoce. */
                }
                return CheckboxListTile(
                  title: Text(anterior.titulo),
                  subtitle: Text(
                    fecha ??
                        'Fecha u hora no reconocida. Conserva el original y crea un nuevo recordatorio.',
                  ),
                  value: _seleccionados.contains(anterior.clave),
                  onChanged: fecha == null
                      ? null
                      : (valor) => setState(() {
                          if (valor == true) {
                            _seleccionados.add(anterior.clave);
                          } else {
                            _seleccionados.remove(anterior.clave);
                          }
                        }),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _seleccionados.isEmpty
            ? null
            : () => Navigator.pop(context, _seleccionados),
        child: const Text('Recuperar'),
      ),
    ],
  );
}
