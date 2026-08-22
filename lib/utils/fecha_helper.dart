import 'package:intl/intl.dart';

class FechaHelper {
  static String fechaActual() {
    final ahora = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(ahora);
  }

  static String fechaFormateada() {
    final ahora = DateTime.now();
    return DateFormat('dd-MM-yyyy').format(ahora);
  }

  static String horaActual() {
    final ahora = DateTime.now();
    return DateFormat('HH:mm:ss').format(ahora);
  }

  static String fechaHoraFormateada() {
    final ahora = DateTime.now();
    return '${DateFormat('dd-MM-yyyy').format(ahora)} ${DateFormat('HH:mm:ss').format(ahora)}';
  }
}
