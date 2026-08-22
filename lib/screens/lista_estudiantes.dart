import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            onChanged: _buscar,
          ),
          const SizedBox(height: 16),
          Text(
            '${_filtrados.length} estudiantes encontrados',
            style: const TextStyle(color: Colors.white70),
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
                      ? const Color(0xFF0066FF).withOpacity(0.2)
                      : const Color(0xFF0A1428),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0066FF)
                          : Colors.grey[800]!,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'RU: ${est.ru}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.qr_code,
                              color: Color(0xFF00FFCC)),
                          onPressed: () => _mostrarQR(context, est),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () => _mostrarDialogoEditar(context, est),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent),
                          onPressed: () => _eliminar(est),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() => _seleccionado = est);
                    },
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'RU: ${estudiante.ru}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: estudiante.ru,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Escanea este codigo para registrar asistencia',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),
          ],
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
              TextField(
                controller: ruCtrl,
                decoration: const InputDecoration(labelText: 'RU'),
              ),
              TextField(
                controller: nombresCtrl,
                decoration: const InputDecoration(labelText: 'Nombres'),
              ),
              TextField(
                controller: paternoCtrl,
                decoration: const InputDecoration(labelText: 'Apellido Paterno'),
              ),
              TextField(
                controller: maternoCtrl,
                decoration: const InputDecoration(labelText: 'Apellido Materno'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final nuevo = Estudiante(
                ru: ruCtrl.text.trim(),
                nombres: nombresCtrl.text.trim(),
                apellidoPaterno: paternoCtrl.text.trim(),
                apellidoMaterno: maternoCtrl.text.trim(),
              );
              await _service.actualizar(estudiante.ru, nuevo);
              Navigator.pop(context);
              _cargarEstudiantes();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
