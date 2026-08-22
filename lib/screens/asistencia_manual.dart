import 'package:flutter/material.dart';
import '../models/estudiante.dart';
import '../services/estudiante_service.dart';
import '../services/asistencia_service.dart';

class AsistenciaManualScreen extends StatefulWidget {
  const AsistenciaManualScreen({super.key});

  @override
  State<AsistenciaManualScreen> createState() => _AsistenciaManualScreenState();
}

class _AsistenciaManualScreenState extends State<AsistenciaManualScreen> {
  final _estudianteService = EstudianteService();
  final _asistenciaService = AsistenciaService();
  List<Estudiante> _estudiantes = [];
  Estudiante? _seleccionado;
  String _estado = 'Presente';
  bool _cargando = true;
  bool _autenticado = false;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() => _cargando = true);
    try {
      _estudiantes = await _estudianteService.leerEstudiantes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _cargando = false);
  }

  void _autenticar() {
    if (_passwordController.text == 'pocoyo123') {
      setState(() => _autenticado = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrasena incorrecta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _registrarAsistencia() async {
    if (_seleccionado == null) return;

    try {
      final duplicado =
          await _asistenciaService.verificarDuplicado(_seleccionado!.ru);

      if (duplicado != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Ya registro asistencia hoy a las ${duplicado['hora']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _asistenciaService.registrarAsistencia(
        ru: _seleccionado!.ru,
        nombres: _seleccionado!.nombres,
        apellidoPaterno: _seleccionado!.apellidoPaterno,
        apellidoMaterno: _seleccionado!.apellidoMaterno,
        estado: _estado,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Asistencia registrada: ${_seleccionado!.nombreCorto} - $_estado'),
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

  @override
  Widget build(BuildContext context) {
    if (!_autenticado) {
      return _buildPasswordScreen();
    }
    return _buildAsistenciaScreen();
  }

  Widget _buildPasswordScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          color: const Color(0xFF0A1428),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.orange, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: Colors.orange, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Acceso Restringido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingrese la contrasena para continuar',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contrasena',
                    prefixIcon: const Icon(Icons.key),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
                  onSubmitted: (_) => _autenticar(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _autenticar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ingresar',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAsistenciaScreen() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_estudiantes.isEmpty) {
      return const Center(
        child: Text(
          'No hay estudiantes registrados',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Estudiante',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Estudiante>(
            value: _seleccionado,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[900],
              prefixIcon: const Icon(Icons.person),
            ),
            items: _estudiantes.map((est) {
              return DropdownMenuItem(
                value: est,
                child: Text('${est.ru} - ${est.nombreCorto}'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _seleccionado = value);
            },
          ),
          if (_seleccionado != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1428),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos del estudiante',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('RU', _seleccionado!.ru),
                  _infoRow('Nombres', _seleccionado!.nombres),
                  _infoRow('Apellido Paterno', _seleccionado!.apellidoPaterno),
                  _infoRow('Apellido Materno', _seleccionado!.apellidoMaterno),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Estado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Presente', label: Text('Presente')),
                ButtonSegment(value: 'Tarde', label: Text('Tarde')),
                ButtonSegment(value: 'Permiso', label: Text('Permiso')),
                ButtonSegment(value: 'Ausente', label: Text('Ausente')),
              ],
              selected: {_estado},
              onSelectionChanged: (values) {
                setState(() => _estado = values.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF0066FF);
                  }
                  return Colors.grey[900];
                }),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _registrarAsistencia,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Registrar Asistencia',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFCC),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
