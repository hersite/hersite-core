import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

enum TipoRecordatorio { pastilla, cita }

enum RepeticionRecordatorio { unaVez, diaria }

enum EstadoAviso { pendiente, exacto, aproximado, sinPermiso, error }

class Recordatorio {
  const Recordatorio({
    required this.id,
    required this.perfilId,
    required this.tipo,
    required this.titulo,
    required this.fechaHora,
    this.repeticion = RepeticionRecordatorio.unaVez,
    this.completado = false,
    this.estadoAviso = EstadoAviso.pendiente,
    this.claveAnterior,
    this.respaldoId,
  });

  final int id;
  final int perfilId;
  final TipoRecordatorio tipo;
  final String titulo;

  // Fecha y hora de Lima, sin conversión a la zona horaria del dispositivo.
  final DateTime fechaHora;
  final RepeticionRecordatorio repeticion;
  final bool completado;
  final EstadoAviso estadoAviso;
  final String? claveAnterior;
  final String? respaldoId;

  bool get esDiario => repeticion == RepeticionRecordatorio.diaria;
  bool get requiereAtencion =>
      estadoAviso == EstadoAviso.sinPermiso || estadoAviso == EstadoAviso.error;

  static DateTime siguienteHoraDiaria(DateTime fecha, DateTime ahora) {
    final hoy = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      fecha.hour,
      fecha.minute,
    );
    return hoy.isAfter(ahora) ? hoy : hoy.add(const Duration(days: 1));
  }

  DateTime proximaFecha(DateTime ahora) =>
      esDiario ? siguienteHoraDiaria(fechaHora, ahora) : fechaHora;

  bool estaVencido(DateTime ahora) =>
      !completado && !esDiario && !fechaHora.isAfter(ahora);

  String fechaTexto(DateTime ahora) =>
      DateFormat('dd/MM/yyyy HH:mm').format(proximaFecha(ahora));

  Recordatorio copyWith({
    DateTime? fechaHora,
    bool? completado,
    EstadoAviso? estadoAviso,
  }) => Recordatorio(
    id: id,
    perfilId: perfilId,
    tipo: tipo,
    titulo: titulo,
    fechaHora: fechaHora ?? this.fechaHora,
    repeticion: repeticion,
    completado: completado ?? this.completado,
    estadoAviso: estadoAviso ?? this.estadoAviso,
    claveAnterior: claveAnterior,
    respaldoId: respaldoId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'perfil_id': perfilId,
    'tipo': tipo.name,
    'titulo': titulo,
    'fecha_hora': fechaHora.toIso8601String(),
    'repeticion': repeticion.name,
    'completado': completado,
    'estado_aviso': estadoAviso.name,
    'clave_anterior': claveAnterior,
    'respaldo_id': respaldoId,
  };

  factory Recordatorio.fromJson(Map<String, dynamic> json) => Recordatorio(
    id: json['id'] as int,
    perfilId: json['perfil_id'] as int,
    tipo: TipoRecordatorio.values.byName(json['tipo'] as String),
    titulo: json['titulo'] as String,
    fechaHora: DateTime.parse(json['fecha_hora'] as String),
    repeticion: RepeticionRecordatorio.values.byName(
      json['repeticion'] as String? ?? 'unaVez',
    ),
    completado: json['completado'] == true,
    estadoAviso: EstadoAviso.values.byName(
      json['estado_aviso'] as String? ?? 'pendiente',
    ),
    claveAnterior: json['clave_anterior'] as String?,
    respaldoId: json['respaldo_id'] as String? ?? const Uuid().v4(),
  );

  static DateTime leerFechaAnterior(String fecha, String hora) {
    final partes = fecha.split('/').map(int.parse).toList();
    if (partes.length != 3) {
      throw const FormatException('Fecha de recordatorio inválida.');
    }
    final horaNormalizada = hora.toLowerCase().replaceAll(
      RegExp(r'[\s.\u00a0\u202f]'),
      '',
    );
    final coincidencia = RegExp(
      r'^(\d{1,2}):(\d{2})(am|pm)?$',
    ).firstMatch(horaNormalizada);
    if (coincidencia == null) {
      throw const FormatException('Hora de recordatorio inválida.');
    }
    var horas = int.parse(coincidencia[1]!);
    final minutos = int.parse(coincidencia[2]!);
    final periodo = coincidencia[3];
    if (minutos > 59 ||
        (periodo == null ? horas > 23 : horas < 1 || horas > 12)) {
      throw const FormatException('Hora de recordatorio fuera de rango.');
    }
    if (periodo != null) {
      horas = horas % 12 + (periodo == 'pm' ? 12 : 0);
    }
    final resultado = DateTime(partes[2], partes[1], partes[0], horas, minutos);
    if (resultado.day != partes[0] ||
        resultado.month != partes[1] ||
        resultado.year != partes[2]) {
      throw const FormatException('Fecha de recordatorio fuera de rango.');
    }
    return resultado;
  }
}
