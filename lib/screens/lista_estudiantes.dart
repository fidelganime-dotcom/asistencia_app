import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/estudiante.dart';
import '../services/estudiante_service.dart';

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
  Estudiante? _seleccionado;

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
        title: const Text('Confirmar eliminacion'),
        content: Text(
            'Eliminar a ${estudiante.nombreCorto} (RU: ${estudiante.ru})?\n\nSe eliminaran tambien todos sus registros de asistencia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _service.eliminar(estudiante.ru);
        _cargarEstudiantes();
        setState(() => _seleccionado = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estudiante eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
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

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/estudiantes.xlsx';
      final file = File(filePath);
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Lista de Estudiantes');
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

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _buscarController,
            decoration: InputDecoration(
              labelText: 'Buscar estudiante',
              hintText: 'Por RU o nombre...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            onChanged: _buscar,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filtrados.length} estudiantes encontrados',
                style: const TextStyle(color: Colors.white70),
              ),
              ElevatedButton.icon(
                onPressed: _estudiantes.isEmpty ? null : _exportarExcel,
                icon: const Icon(Icons.file_download, color: Colors.white),
                label: const Text('Exportar Excel', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_filtrados.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No hay estudiantes registrados',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
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
                final isSelected = _seleccionado?.ru == est.ru;
                return Card(
                  color: isSelected
                      ? const Color(0xFF0066FF).withValues(alpha: 0.2)
                      : const Color(0xFF0A1428),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.grey[800]!,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0066FF),
                      child: Text(
                        est.nombres[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      est.nombreCorto,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'RU: ${est.ru}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code, color: Color(0xFF00FFCC)),
                          onPressed: () => _mostrarQR(context, est),
                        ),
                        IconButton(
                          icon: const Icon(Icons.credit_card, color: Colors.orange),
                          onPressed: () => _mostrarTarjeta(context, est),
                          tooltip: 'Ver tarjeta',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () => _mostrarDialogoEditar(context, est),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _eliminar(est),
                        ),
                      ],
                    ),
                    onTap: () => setState(() => _seleccionado = est),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _mostrarQR(BuildContext context, Estudiante estudiante) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1428),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              estudiante.nombreCompleto,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('RU: ${estudiante.ru}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            QrImageView(
              data: estudiante.ru,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text('Escanea este codigo para registrar asistencia', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _mostrarTarjeta(BuildContext context, Estudiante estudiante) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1428),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Tarjeta
              Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1428), Color(0xFF1A2A4A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0066FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'INGENIERIA DE SISTEMAS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00FFCC),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      estudiante.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'RU: ${estudiante.ru}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: estudiante.ru,
                        version: QrVersions.auto,
                        size: 180,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UAP - Ingenieria de Sistemas',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tarjeta mostrada - captura pantalla para guardar'),
                        backgroundColor: Color(0xFF00FFCC),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text('Capturar pantalla', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoEditar(BuildContext context, Estudiante estudiante) {
    final ruCtrl = TextEditingController(text: estudiante.ru);
    final nombresCtrl = TextEditingController(text: estudiante.nombres);
    final paternoCtrl = TextEditingController(text: estudiante.apellidoPaterno);
    final maternoCtrl = TextEditingController(text: estudiante.apellidoMaterno);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Estudiante'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ruCtrl, decoration: const InputDecoration(labelText: 'RU')),
              TextField(controller: nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres')),
              TextField(controller: paternoCtrl, decoration: const InputDecoration(labelText: 'Apellido Paterno')),
              TextField(controller: maternoCtrl, decoration: const InputDecoration(labelText: 'Apellido Materno')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
