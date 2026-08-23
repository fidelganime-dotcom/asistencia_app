import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/asistencia.dart';
import '../models/estudiante.dart';
import '../services/asistencia_service.dart';
import '../services/estudiante_service.dart';

class VerAsistenciaScreen extends StatefulWidget {
  const VerAsistenciaScreen({super.key});

  @override
  State<VerAsistenciaScreen> createState() => _VerAsistenciaScreenState();
}

class _VerAsistenciaScreenState extends State<VerAsistenciaScreen> {
  final _asistenciaService = AsistenciaService();
  final _estudianteService = EstudianteService();
  List<Asistencia> _registros = [];
  List<Estudiante> _estudiantes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final resultados = await Future.wait([
        _asistenciaService.leerAsistencia(),
        _estudianteService.leerEstudiantes(),
      ]);
      _registros = resultados[0] as List<Asistencia>;
      _estudiantes = resultados[1] as List<Estudiante>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _cargando = false);
  }

  Future<void> _exportarExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Asistencia'];

      sheet.appendRow([
        TextCellValue('RU'),
        TextCellValue('Nombres'),
        TextCellValue('Apellido Paterno'),
        TextCellValue('Apellido Materno'),
        TextCellValue('Fecha'),
        TextCellValue('Hora'),
        TextCellValue('Estado'),
      ]);

      for (var reg in _registros) {
        sheet.appendRow([
          TextCellValue(reg.ru),
          TextCellValue(reg.nombres),
          TextCellValue(reg.apellidoPaterno),
          TextCellValue(reg.apellidoMaterno),
          TextCellValue('${reg.fecha.day}/${reg.fecha.month}/${reg.fecha.year}'),
          TextCellValue(reg.hora),
          TextCellValue(reg.estado),
        ]);
      }

      excel.delete('Sheet1');

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final filePath = '${directory.path}/asistencia_${now.day}-${now.month}-${now.year}.xlsx';
      final file = File(filePath);
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Reporte de Asistencia');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel exportado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportarExcelHoy() async {
    try {
      final hoy = DateTime.now();
      final registrosHoy = _registros
          .where((r) =>
              r.fecha.year == hoy.year &&
              r.fecha.month == hoy.month &&
              r.fecha.day == hoy.day)
          .toList();

      if (registrosHoy.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay registros para hoy'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      var excel = Excel.createExcel();
      Sheet sheet = excel['Asistencia Hoy'];

      sheet.appendRow([
        TextCellValue('RU'),
        TextCellValue('Nombres'),
        TextCellValue('Apellido Paterno'),
        TextCellValue('Apellido Materno'),
        TextCellValue('Fecha'),
        TextCellValue('Hora'),
        TextCellValue('Estado'),
      ]);

      for (var reg in registrosHoy) {
        sheet.appendRow([
          TextCellValue(reg.ru),
          TextCellValue(reg.nombres),
          TextCellValue(reg.apellidoPaterno),
          TextCellValue(reg.apellidoMaterno),
          TextCellValue('${reg.fecha.day}/${reg.fecha.month}/${reg.fecha.year}'),
          TextCellValue(reg.hora),
          TextCellValue(reg.estado),
        ]);
      }

      excel.delete('Sheet1');

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/asistencia_hoy_${hoy.day}-${hoy.month}-${hoy.year}.xlsx';
      final file = File(filePath);
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Asistencia del dia ${hoy.day}/${hoy.month}/${hoy.year}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel del dia exportado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    final hoy = DateTime.now();
    final registrosHoy = _registros
        .where((r) =>
            r.fecha.year == hoy.year &&
            r.fecha.month == hoy.month &&
            r.fecha.day == hoy.day)
        .toList();

    final totalEstudiantes = _estudiantes.length;
    final registradosHoy = registrosHoy.map((r) => r.ru).toSet().length;
    final faltantes = totalEstudiantes - registradosHoy;

    final porcentajeRegistrados =
        totalEstudiantes > 0 ? (registradosHoy / totalEstudiantes * 100.0) : 0.0;
    final porcentajeFaltantes =
        totalEstudiantes > 0 ? (faltantes / totalEstudiantes * 100.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard cards
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard('Total', '$totalEstudiantes', '100%', Colors.green, 100),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDashboardCard(
                  'Registrados',
                  '$registradosHoy',
                  '${porcentajeRegistrados.toStringAsFixed(1)}%',
                  const Color(0xFF0066FF),
                  porcentajeRegistrados,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDashboardCard(
                  'Faltantes',
                  '$faltantes',
                  '${porcentajeFaltantes.toStringAsFixed(1)}%',
                  Colors.orange,
                  porcentajeFaltantes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botones de exportar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _registros.isEmpty ? null : _exportarExcelHoy,
                  icon: const Icon(Icons.today, color: Colors.white),
                  label: const Text('Excel Hoy', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _registros.isEmpty ? null : _exportarExcel,
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  label: const Text('Excel Completo', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabla de registros
          const Text(
            'Registros de Asistencia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (_registros.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No hay registros de asistencia', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _registros.length,
              itemBuilder: (context, index) {
                final reg = _registros[index];
                return Card(
                  color: const Color(0xFF0A1428),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[800]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getColorByEstado(reg.estado),
                      child: Text(
                        reg.estado[0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      reg.nombreCompleto,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'RU: ${reg.ru} | ${reg.fecha.day}/${reg.fecha.month}/${reg.fecha.year} ${reg.hora}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'Presente', child: Text('Presente')),
                        const PopupMenuItem(value: 'Tarde', child: Text('Tarde')),
                        const PopupMenuItem(value: 'Permiso', child: Text('Permiso')),
                        const PopupMenuItem(value: 'Ausente', child: Text('Ausente')),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'eliminar') {
                          await _eliminarRegistro(reg);
                        } else {
                          await _actualizarEstado(reg, value);
                        }
                      },
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Eliminar todos
          if (_registros.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmarEliminarTodos,
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                label: const Text('Eliminar todos los registros', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String value, String percentage, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1428),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(percentage, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorByEstado(String estado) {
    switch (estado) {
      case 'Presente': return Colors.green;
      case 'Tarde': return Colors.orange;
      case 'Permiso': return Colors.blue;
      case 'Ausente': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _actualizarEstado(Asistencia registro, String nuevoEstado) async {
    try {
      await _asistenciaService.actualizarEstado(registro.id!, nuevoEstado);
      _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminarRegistro(Asistencia registro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('Eliminar registro de ${registro.nombreCompleto} del ${registro.fecha.day}/${registro.fecha.month}/${registro.fecha.year}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _asistenciaService.eliminarRegistro(registro.id!);
        _cargarDatos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _confirmarEliminarTodos() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar TODOS los registros'),
        content: const Text('Esta accion eliminara TODOS los registros de asistencia. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar todos', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _asistenciaService.eliminarTodos();
        _cargarDatos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
