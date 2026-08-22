class Estudiante {
  final String ru;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;

  Estudiante({
    required this.ru,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
  });

  String get nombreCompleto =>
      '$nombres $apellidoPaterno $apellidoMaterno'.trim().toUpperCase();

  String get nombreCorto => '${nombres.split(' ').first} $apellidoPaterno'
      .trim()
      .toUpperCase();

  factory Estudiante.fromMap(Map<String, dynamic> map) {
    return Estudiante(
      ru: map['ru']?.toString() ?? '',
      nombres: map['nombres'] ?? '',
      apellidoPaterno: map['apellido_paterno'] ?? '',
      apellidoMaterno: map['apellido_materno'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ru': ru,
      'nombres': nombres,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
    };
  }
}
