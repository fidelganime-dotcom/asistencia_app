import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asistencia.dart';
import '../utils/fecha_helper.dart';

class AsistenciaService {
  final _supabase = Supabase.instance.client;

  Future<List<Asistencia>> leerAsistencia() async {
    try {
      final response = await _supabase
          .from('asistencia')
          .select('*')
          .order('id', ascending: true);
      return (response as List)
          .map((e) => Asistencia.fromMap(e))
          .toList();
    } catch (e) {
      throw Exception('Error al leer asistencia: $e');
    }
  }

  Future<Map<String, dynamic>?> verificarDuplicado(String ru) async {
    try {
      final fechaHoy = FechaHelper.fechaActual();
      final response = await _supabase
          .from('asistencia')
          .select('*')
          .eq('ru', ru)
          .eq('fecha', fechaHoy)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error al verificar duplicado: $e');
    }
  }

  Future<void> registrarAsistencia({
    required String ru,
    required String nombres,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String estado,
  }) async {
    try {
      await _supabase.from('asistencia').insert({
        'ru': ru,
        'nombres': nombres,
        'apellido_paterno': apellidoPaterno,
        'apellido_materno': apellidoMaterno,
        'fecha': FechaHelper.fechaActual(),
        'hora': FechaHelper.horaActual(),
        'estado': estado,
      });
    } catch (e) {
      throw Exception('Error al registrar asistencia: $e');
    }
  }

  Future<void> actualizarEstado(int id, String nuevoEstado) async {
    try {
      await _supabase
          .from('asistencia')
          .update({'estado': nuevoEstado}).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  Future<void> eliminarRegistro(int id) async {
    try {
      await _supabase.from('asistencia').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar registro: $e');
    }
  }

  Future<void> eliminarTodos() async {
    try {
      await _supabase.from('asistencia').delete().neq('id', 0);
    } catch (e) {
      throw Exception('Error al eliminar todos los registros: $e');
    }
  }
}
