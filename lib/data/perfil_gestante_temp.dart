class PerfilGestanteTemp {
  static Map<String, dynamic>? _perfil;

  static void guardar(Map<String, dynamic> datos) {
    _perfil = Map<String, dynamic>.from(datos);
  }

  static void actualizar(Map<String, dynamic> nuevosDatos) {
    _perfil = {
      ...?_perfil,
      ...nuevosDatos,
    };
  }

  static Map<String, dynamic>? obtener() {
    return _perfil == null ? null : Map<String, dynamic>.from(_perfil!);
  }

  static bool get existePerfil => _perfil != null;

  static void limpiar() {
    _perfil = null;
  }

  static Map<String, dynamic> obtenerParaModelo() {
    return _perfil ??
        {
          'Edad_Materna': 25,
          'Semanas_Gestacion': 34,
          'Numero_Embarazos': 1,
          'Cesarea_Previa': 0,
          'Diabetes': 0,
          'Hipertension_Previa': 0,
          'Preeclampsia_Previa': 0,
          'Anemia_Gestacional': 0,
          'Presion_Basal_Sistolica': 110,
          'Presion_Basal_Diastolica': 70,
        };
  }
}