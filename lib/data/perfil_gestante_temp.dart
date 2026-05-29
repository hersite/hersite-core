class PerfilGestanteTemp {
  static Map<String, dynamic>? _perfil;

  static void guardar(Map<String, dynamic> datos) {
    _perfil = datos;
  }

  static void actualizar(Map<String, dynamic> nuevosDatos) {
    if (_perfil == null) {
      _perfil = nuevosDatos;
    } else {
      _perfil!.addAll(
        nuevosDatos,
      ); // Esto "fusiona" los datos nuevos con los que ya estaban
    }
  }

  static Map<String, dynamic>? obtener() {
    return _perfil;
  }

  static bool get existePerfil => _perfil != null;

  static void limpiar() {
    _perfil = null;
  }

  static Map<String, dynamic> obtenerParaModelo() {
    // Valores por defecto solo para evitar que la app se rompa
    // si alguien entra directo al flujo sin registrarse.
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
