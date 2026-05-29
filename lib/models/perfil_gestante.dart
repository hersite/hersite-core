class PerfilGestante {
  final int? id;

  final String nombre;
  final String dni;
  final String celular;
  final String pinHash;
  final String pinSalt;

  final int edadMaterna;
  final int semanasGestacion;
  final int numeroEmbarazos;
  final int cesareaPrevia;
  final int diabetes;
  final int hipertensionPrevia;
  final int preeclampsiaPrevia;
  final int anemiaGestacional;
  final int presionBasalSistolica;
  final int presionBasalDiastolica;

  const PerfilGestante({
    this.id,
    required this.nombre,
    required this.dni,
    required this.celular,
    required this.pinHash,
    required this.pinSalt,
    required this.edadMaterna,
    required this.semanasGestacion,
    required this.numeroEmbarazos,
    required this.cesareaPrevia,
    required this.diabetes,
    required this.hipertensionPrevia,
    required this.preeclampsiaPrevia,
    required this.anemiaGestacional,
    required this.presionBasalSistolica,
    required this.presionBasalDiastolica,
  });

  Map<String, dynamic> toMapDb() {
    return {
      'nombre': nombre,
      'dni': dni,
      'celular': celular,
      'pin_hash': pinHash,
      'pin_salt': pinSalt,
      'edad_materna': edadMaterna,
      'semanas_gestacion': semanasGestacion,
      'numero_embarazos': numeroEmbarazos,
      'cesarea_previa': cesareaPrevia,
      'diabetes': diabetes,
      'hipertension_previa': hipertensionPrevia,
      'preeclampsia_previa': preeclampsiaPrevia,
      'anemia_gestacional': anemiaGestacional,
      'presion_basal_sistolica': presionBasalSistolica,
      'presion_basal_diastolica': presionBasalDiastolica,
    };
  }

  factory PerfilGestante.fromMapDb(Map<String, dynamic> map) {
    return PerfilGestante(
      id: map['id'] as int?,
      nombre: map['nombre'] as String? ?? '',
      dni: map['dni'] as String? ?? '',
      celular: map['celular'] as String? ?? '',
      pinHash: map['pin_hash'] as String? ?? '',
      pinSalt: map['pin_salt'] as String? ?? '',
      edadMaterna: map['edad_materna'] as int,
      semanasGestacion: map['semanas_gestacion'] as int,
      numeroEmbarazos: map['numero_embarazos'] as int,
      cesareaPrevia: map['cesarea_previa'] as int,
      diabetes: map['diabetes'] as int,
      hipertensionPrevia: map['hipertension_previa'] as int,
      preeclampsiaPrevia: map['preeclampsia_previa'] as int,
      anemiaGestacional: map['anemia_gestacional'] as int,
      presionBasalSistolica: map['presion_basal_sistolica'] as int,
      presionBasalDiastolica: map['presion_basal_diastolica'] as int,
    );
  }

  Map<String, dynamic> toModelInput() {
    return {
      'Edad_Materna': edadMaterna,
      'Semanas_Gestacion': semanasGestacion,
      'Numero_Embarazos': numeroEmbarazos,
      'Cesarea_Previa': cesareaPrevia,
      'Diabetes': diabetes,
      'Hipertension_Previa': hipertensionPrevia,
      'Preeclampsia_Previa': preeclampsiaPrevia,
      'Anemia_Gestacional': anemiaGestacional,
      'Presion_Basal_Sistolica': presionBasalSistolica,
      'Presion_Basal_Diastolica': presionBasalDiastolica,
    };
  }

  factory PerfilGestante.fromTempMap(Map<String, dynamic> map) {
    return PerfilGestante(
      id: map['IdPerfil'] as int?,
      nombre: map['Nombre'] as String? ?? '',
      dni: map['DNI'] as String? ?? '',
      celular: map['Celular'] as String? ?? '',
      pinHash: map['PinHash'] as String? ?? '',
      pinSalt: map['PinSalt'] as String? ?? '',
      edadMaterna: map['Edad_Materna'] as int,
      semanasGestacion: map['Semanas_Gestacion'] as int,
      numeroEmbarazos: map['Numero_Embarazos'] as int,
      cesareaPrevia: map['Cesarea_Previa'] as int,
      diabetes: map['Diabetes'] as int,
      hipertensionPrevia: map['Hipertension_Previa'] as int,
      preeclampsiaPrevia: map['Preeclampsia_Previa'] as int,
      anemiaGestacional: map['Anemia_Gestacional'] as int,
      presionBasalSistolica: map['Presion_Basal_Sistolica'] as int,
      presionBasalDiastolica: map['Presion_Basal_Diastolica'] as int,
    );
  }
}
