import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estudiante.dart';

class EstudianteService {
  final _supabase = Supabase.instance.client;

  Future<List<Estudiante>> leerEstudiantes() async {
    try {
      final response =
          await _supabase.from('estudiantes').select('*').order('ru');
      return (response as List)
          .map((e) => Estudiante.fromMap(e))
          .toList();
    } catch (e) {
      throw Exception('Error al leer estudiantes: $e');
    }
  }

  Future<Estudiante?> buscarPorRu(String ru) async {
    try {
      final response = await _supabase
          .from('estudiantes')
          .select('*')
          .eq('ru', ru)
          .maybeSingle();
      if (response == null) return null;
      return Estudiante.fromMap(response);
    } catch (e) {
      throw Exception('Error al buscar estudiante: $e');
    }
  }

  Future<bool> existeRu(String ru) async {
    try {
      final response = await _supabase
          .from('estudiantes')
          .select('ru')
          .eq('ru', ru)
          .maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception('Error al verificar RU: $e');
    }
  }

  Future<void> registrar(Estudiante estudiante) async {
    try {
      await _supabase.from('estudiantes').insert(estudiante.toMap());
    } catch (e) {
      throw Exception('Error al registrar estudiante: $e');
    }
  }

  Future<void> actualizar(String ruActual, Estudiante estudiante) async {
    try {
      await _supabase
          .from('estudiantes')
          .update(estudiante.toMap())
          .eq('ru', ruActual);

      if (ruActual != estudiante.ru) {
        await _supabase
            .from('asistencia')
            .update({'ru': estudiante.ru}).eq('ru', ruActual);
      }
    } catch (e) {
      throw Exception('Error al actualizar estudiante: $e');
    }
  }

  Future<void> eliminar(String ru) async {
    try {
      await _supabase.from('asistencia').delete().eq('ru', ru);
      await _supabase.from('estudiantes').delete().eq('ru', ru);
    } catch (e) {
      throw Exception('Error al eliminar estudiante: $e');
    }
  }
}
