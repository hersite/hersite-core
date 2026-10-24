import 'package:flutter/material.dart';

/// Solo presenta el borrador: no guarda datos ni modifica la sesión.
class ResumenRegistroDialog extends StatelessWidget {
  final Map<String, dynamic> datos;

  const ResumenRegistroDialog({super.key, required this.datos});

  static const _verde = Color(0xFF306339);
  static const _condiciones = <String, String>{
    'Cesarea_Previa': 'Cesárea previa',
    'Diabetes': 'Diabetes',
    'Hipertension_Previa': 'Hipertensión previa',
    'Preeclampsia_Previa': 'Pre-eclampsia previa',
    'Anemia_Gestacional': 'Anemia gestacional',
    'Embarazo_Multiple': 'Embarazo múltiple',
    'Antecedente_Hemorragia': 'Antecedente de hemorragia importante',
  };

  String get _fechaNacimiento {
    final fecha = DateTime.tryParse('${datos['Fecha_Nacimiento']}');
    if (fecha == null) return 'No indicada';
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFBFFFB),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight:
              MediaQuery.sizeOf(context).height -
              MediaQuery.paddingOf(context).vertical -
              40,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFE3F0E2),
                            child: Icon(
                              Icons.fact_check_outlined,
                              color: _verde,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Confirma tus datos',
                              style: TextStyle(
                                fontSize: 21,
                                color: _verde,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Revisa tu información antes de crear el perfil.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF434C43),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _seccion('Datos personales', [
                        _fila('Nombre', '${datos['Nombre']}'),
                        _fila('DNI', '${datos['DNI']}'),
                        _fila('Nacimiento', _fechaNacimiento),
                        _fila('Celular', '${datos['Celular']}'),
                      ]),
                      const SizedBox(height: 10),
                      _seccion('Embarazo y presión habitual', [
                        _fila(
                          'Gestación',
                          '${datos['Semanas_Gestacion']} semanas',
                        ),
                        _fila(
                          'Embarazos',
                          '${datos['Numero_Embarazos']} (incluye el actual)',
                        ),
                        _fila(
                          'Presión basal',
                          datos['Presion_Basal_Disponible'] == 1
                              ? '${datos['Presion_Basal_Sistolica']}/${datos['Presion_Basal_Diastolica']} mmHg'
                              : 'No la conozco',
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _seccion('Tus 7 condiciones', [
                        for (final condicion in _condiciones.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    condicion.value,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  datos[condicion.key] == 1 ? 'Sí' : 'No',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _verde,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Los botones permanecen visibles incluso con letra ampliada.
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Revisar datos'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> children) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F8F1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDCE9DA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: _verde,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        ...children,
      ],
    ),
  );

  Widget _fila(String etiqueta, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            etiqueta,
            style: const TextStyle(fontSize: 13, color: Color(0xFF596459)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            valor,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
