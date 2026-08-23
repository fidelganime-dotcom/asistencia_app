import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import '../models/estudiante.dart';
import '../services/estudiante_service.dart';
import '../utils/file_helper.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class ListaEstudiantesScreen extends StatefulWidget {
  const ListaEstudiantesScreen({super.key});

  @override
  State<ListaEstudiantesScreen> createState() => _ListaEstudiantesScreenState();
}

class _ListaEstudiantesScreenState extends State<ListaEstudiantesScreen> {
  final _service = EstudianteService();
  final _buscarController = TextEditingController();
  List<Estudiante> _estudiantes = [];
  List<Estudiante> _filtrados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() => _cargando = true);
    try {
      _estudiantes = await _service.leerEstudiantes();
      _filtrados = _estudiantes;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _cargando = false);
  }

  void _buscar(String query) {
    setState(() {
      _filtrados = _estudiantes
          .where((e) =>
              e.ru.contains(query) ||
              e.nombreCompleto.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _eliminar(Estudiante estudiante) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar eliminacion', style: TextStyle(color: Colors.white)),
        content: Text(
          'Eliminar a ${estudiante.nombreCorto} (RU: ${estudiante.ru})?\n\nSe eliminaran tambien todos sus registros de asistencia.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _service.eliminar(estudiante.ru);
        _cargarEstudiantes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estudiante eliminado'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _exportarExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Estudiantes'];
      sheet.appendRow([
        TextCellValue('RU'),
        TextCellValue('Nombres'),
        TextCellValue('Apellido Paterno'),
        TextCellValue('Apellido Materno'),
      ]);
      for (var est in _estudiantes) {
        sheet.appendRow([
          TextCellValue(est.ru),
          TextCellValue(est.nombres),
          TextCellValue(est.apellidoPaterno),
          TextCellValue(est.apellidoMaterno),
        ]);
      }
      excel.delete('Sheet1');
      final bytes = excel.save();
      if (bytes != null) {
        await FileHelper.saveAndShare(bytes, 'estudiantes.xlsx', 'Lista de Estudiantes');
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

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC)));
    }

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
            // Barra de busqueda
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _buscarController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar por RU o nombre...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: _buscar,
              ),
            ),
            const SizedBox(height: 16),

            // Contador y boton exportar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFCC).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filtrados.length} estudiantes',
                    style: const TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold),
                  ),
                ),
                _buildGlassButton(
                  icon: Icons.file_download,
                  label: 'Excel',
                  color: const Color(0xFF00FFCC),
                  onTap: _estudiantes.isEmpty ? null : _exportarExcel,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de estudiantes
            if (_filtrados.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No hay estudiantes registrados',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filtrados.length,
                itemBuilder: (context, index) {
                  final est = _filtrados[index];
                  return _buildEstudianteCard(est);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildEstudianteCard(Estudiante est) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0066FF), Color(0xFF00FFCC)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              est.nombres[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(
          est.nombreCorto,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'RU: ${est.ru}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconButton(
              icon: Icons.qr_code,
              color: const Color(0xFF00FFCC),
              onTap: () => _mostrarQR(context, est),
            ),
            _buildIconButton(
              icon: Icons.credit_card,
              color: Colors.orange,
              onTap: () => _mostrarTarjeta(context, est),
            ),
            _buildIconButton(
              icon: Icons.edit,
              color: Colors.white70,
              onTap: () => _mostrarDialogoEditar(context, est),
            ),
            _buildIconButton(
              icon: Icons.delete,
              color: Colors.redAccent,
              onTap: () => _eliminar(est),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _mostrarQR(BuildContext context, Estudiante estudiante) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0D1B2A)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(
              estudiante.nombreCompleto,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('RU: ${estudiante.ru}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: estudiante.ru, version: QrVersions.auto, size: 200),
            ),
            const SizedBox(height: 16),
            Text('Escanea para registrar asistencia', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _mostrarTarjeta(BuildContext context, Estudiante estudiante) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF0D1B2A)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              // Barra arrastrable
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Contenido scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Tarjeta
                      Container(
                        width: 320,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0066FF).withValues(alpha: 0.8),
                              const Color(0xFF00FFCC).withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'INGENIERIA DE SISTEMAS',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              estudiante.nombreCompleto,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'RU: ${estudiante.ru}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: QrImageView(
                                data: estudiante.ru,
                                version: QrVersions.auto,
                                size: 280,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('UAP - Ingenieria de Sistemas', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botones fijos abajo
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _descargarTarjeta(estudiante);
                        },
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Descargar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFCC),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cerrar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _descargarTarjeta(Estudiante estudiante) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(600, 800);

      // Fondo solido azul degradado sin transparencia
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0066FF), Color(0xFF00CCAA)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(30)),
        bgPaint,
      );

      // INGENIERIA DE SISTEMAS
      final titlePainter = TextPainter(
        text: const TextSpan(
          text: 'INGENIERIA DE SISTEMAS',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      titlePainter.layout();
      titlePainter.paint(canvas, Offset((size.width - titlePainter.width) / 2, 50));

      // Nombre del estudiante
      final namePainter = TextPainter(
        text: TextSpan(
          text: estudiante.nombreCompleto,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        maxLines: 2,
        textDirection: ui.TextDirection.ltr,
      );
      namePainter.layout(maxWidth: size.width - 60);
      namePainter.paint(canvas, Offset((size.width - namePainter.width) / 2, 120));

      // RU - fondo semitransparente
      final ruBgPaint = Paint()..color = const Color(0x33FFFFFF);
      final ruTextPainter = TextPainter(
        text: TextSpan(
          text: 'RU: ${estudiante.ru}',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      ruTextPainter.layout();
      final ruX = (size.width - ruTextPainter.width - 48) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(ruX, 210, ruTextPainter.width + 48, ruTextPainter.height + 20), const Radius.circular(20)),
        ruBgPaint,
      );
      ruTextPainter.paint(canvas, Offset(ruX + 24, 220));

      // QR - fondo BLANCO PURO
      final qrBgPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH((size.width - 380) / 2, 290, 380, 380), const Radius.circular(20)),
        qrBgPaint,
      );

      // QR modulos NEGROS sobre fondo blanco
      final qrPainter = QrPainter(
        data: estudiante.ru,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
      );
      canvas.save();
      canvas.translate((size.width - 350) / 2, 305);
      qrPainter.paint(canvas, const Size(350, 350));
      canvas.restore();

      // Footer
      final footerPainter = TextPainter(
        text: TextSpan(
          text: 'UAP - Ingenieria de Sistemas',
          style: TextStyle(fontSize: 22, color: Colors.white.withValues(alpha: 0.8)),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      footerPainter.layout();
      footerPainter.paint(canvas, Offset((size.width - footerPainter.width) / 2, 700));

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      await FileHelper.saveAndShare(bytes, 'tarjeta_${estudiante.ru}.png', 'Tarjeta de ${estudiante.nombreCorto}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarjeta descargada'), backgroundColor: Color(0xFF00FFCC)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoEditar(BuildContext context, Estudiante estudiante) {
    final ruCtrl = TextEditingController(text: estudiante.ru);
    final nombresCtrl = TextEditingController(text: estudiante.nombres);
    final paternoCtrl = TextEditingController(text: estudiante.apellidoPaterno);
    final maternoCtrl = TextEditingController(text: estudiante.apellidoMaterno);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Estudiante', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(controller: ruCtrl, label: 'RU'),
              _buildDialogField(controller: nombresCtrl, label: 'Nombres'),
              _buildDialogField(controller: paternoCtrl, label: 'Apellido Paterno'),
              _buildDialogField(controller: maternoCtrl, label: 'Apellido Materno'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final nuevo = Estudiante(
                ru: ruCtrl.text.trim(),
                nombres: nombresCtrl.text.trim(),
                apellidoPaterno: paternoCtrl.text.trim(),
                apellidoMaterno: maternoCtrl.text.trim(),
              );
              await _service.actualizar(estudiante.ru, nuevo);
              if (mounted) Navigator.pop(context);
              _cargarEstudiantes();
            },
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF00FFCC))),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
