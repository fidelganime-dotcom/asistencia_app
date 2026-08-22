class Asistencia {
  final int? id;
  final String ru;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final DateTime fecha;
  final String hora;
  final String estado;

  Asistencia({
    this.id,
    required this.ru,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.fecha,
    required this.hora,
    required this.estado,
  });

  String get nombreCompleto =>
      '$nombres $apellidoPaterno $apellidoMaterno'.trim().toUpperCase();

  factory Asistencia.fromMap(Map<String, dynamic> map) {
    return Asistencia(
      id: map['id'],
      ru: map['ru']?.toString() ?? '',
      nombres: map['nombres'] ?? '',
      apellidoPaterno: map['apellido_paterno'] ?? '',
      apellidoMaterno: map['apellido_materno'] ?? '',
      fecha: DateTime.parse(map['fecha']),
      hora: map['hora'] ?? '',
      estado: map['estado'] ?? 'Presente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ru': ru,
      'nombres': nombres,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'fecha': fecha.toIso8601String().split('T')[0],
      'hora': hora,
      'estado': estado,
    };
  }
}
