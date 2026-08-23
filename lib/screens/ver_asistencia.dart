import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import '../models/asistencia.dart';
import '../models/estudiante.dart';
import '../services/asistencia_service.dart';
import '../services/estudiante_service.dart';
import '../utils/file_helper.dart';

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

  Future<void> _exportarExcel({bool soloHoy = false}) async {
    try {
      final registrosAExportar = soloHoy
          ? _registros.where((r) {
              final hoy = DateTime.now();
              return r.fecha.year == hoy.year && r.fecha.month == hoy.month && r.fecha.day == hoy.day;
            }).toList()
          : _registros;

      if (registrosAExportar.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay registros para exportar'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

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
      for (var reg in registrosAExportar) {
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
      final bytes = excel.save();
      if (bytes != null) {
        final ahora = DateTime.now();
        final nombre = soloHoy ? 'asistencia_hoy_${ahora.day}-${ahora.month}-${ahora.year}.xlsx' : 'asistencia_completa.xlsx';
        await FileHelper.saveAndShare(bytes, nombre, 'Reporte de Asistencia');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel exportado correctamente'), backgroundColor: Colors.green),
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

  Future<void> _editarEstado(Asistencia registro) async {
    String nuevoEstado = registro.estado;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Editar: ${registro.nombreCorto}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RU: ${registro.ru}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 16),
              ...['Presente', 'Tarde', 'Permiso', 'Ausente'].map((estado) {
                final colores = {
                  'Presente': Colors.green,
                  'Tarde': Colors.orange,
                  'Permiso': Colors.blue,
                  'Ausente': Colors.red,
                };
                final color = colores[estado] ?? Colors.grey;
                return RadioListTile<String>(
                  title: Text(estado, style: const TextStyle(color: Colors.white)),
                  value: estado,
                  groupValue: nuevoEstado,
                  activeColor: color,
                  onChanged: (value) => setDialogState(() => nuevoEstado = value!),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () => Navigator.pop(context, nuevoEstado),
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF00FFCC))),
          ),
        ],
      ),
    );

    if (result != null && result != registro.estado) {
      try {
        await _asistenciaService.actualizarEstado(registro.id!, result);
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

  Future<void> _eliminarRegistro(Asistencia registro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar registro', style: TextStyle(color: Colors.white)),
        content: Text(
          'Eliminar registro de ${registro.nombreCorto} del ${registro.fecha.day}/${registro.fecha.month}/${registro.fecha.year}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent))),
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

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC)));
    }

    final hoy = DateTime.now();
    final registrosHoy = _registros.where((r) =>
        r.fecha.year == hoy.year && r.fecha.month == hoy.month && r.fecha.day == hoy.day).toList();

    final totalEstudiantes = _estudiantes.length;
    final registradosHoy = registrosHoy.map((r) => r.ru).toSet().length;
    final faltantes = totalEstudiantes - registradosHoy;
    final porcReg = totalEstudiantes > 0 ? (registradosHoy / totalEstudiantes * 100.0) : 0.0;
    final porcFalt = totalEstudiantes > 0 ? (faltantes / totalEstudiantes * 100.0) : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard
            Row(
              children: [
                Expanded(child: _buildDashCard('Total', '$totalEstudiantes', '100%', Colors.green, 100)),
                const SizedBox(width: 10),
                Expanded(child: _buildDashCard('Registrados', '$registradosHoy', '${porcReg.toStringAsFixed(1)}%', const Color(0xFF0066FF), porcReg)),
                const SizedBox(width: 10),
                Expanded(child: _buildDashCard('Faltantes', '$faltantes', '${porcFalt.toStringAsFixed(1)}%', Colors.orange, porcFalt)),
              ],
            ),
            const SizedBox(height: 16),

            // Botones exportar
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    icon: Icons.today,
                    label: 'Excel Hoy',
                    color: const Color(0xFF0066FF),
                    onTap: _registros.isEmpty ? null : () => _exportarExcel(soloHoy: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildExportButton(
                    icon: Icons.file_download,
                    label: 'Excel Completo',
                    color: const Color(0xFF00FFCC),
                    onTap: _registros.isEmpty ? null : () => _exportarExcel(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Titulo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Registros de Asistencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                if (_registros.isNotEmpty)
                  Text('${_registros.length} registros', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de registros
            if (_registros.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.how_to_reg, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No hay registros', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _registros.length,
                itemBuilder: (context, index) {
                  final reg = _registros[index];
                  return _buildRegistroCard(reg);
                },
              ),

            // Eliminar todos
            if (_registros.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Eliminar TODOS', style: TextStyle(color: Colors.redAccent)),
                        content: const Text('Esta accion eliminara todos los registros. No se puede deshacer.', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar todos', style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    );
                    if (confirmar == true) {
                      await _asistenciaService.eliminarTodos();
                      _cargarDatos();
                    }
                  },
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
          ],
        ),
      ),
    );
  }

  Widget _buildDashCard(String title, String value, String pct, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(pct, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress / 100, backgroundColor: Colors.white.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 5),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistroCard(Asistencia reg) {
    final colores = {
      'Presente': Colors.green,
      'Tarde': Colors.orange,
      'Permiso': Colors.blue,
      'Ausente': Colors.red,
    };
    final color = colores[reg.estado] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(reg.estado[0], style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        title: Text(
          reg.nombreCompleto,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'RU: ${reg.ru}  |  ${reg.fecha.day}/${reg.fecha.month}/${reg.fecha.year}  ${reg.hora}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionBtn(icon: Icons.edit, color: const Color(0xFF00FFCC), onTap: () => _editarEstado(reg)),
            const SizedBox(width: 6),
            _buildActionBtn(icon: Icons.delete, color: Colors.redAccent, onTap: () => _eliminarRegistro(reg)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
