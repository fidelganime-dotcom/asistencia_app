import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/estudiante.dart';
import '../services/estudiante_service.dart';

class RegistrarEstudianteScreen extends StatefulWidget {
  const RegistrarEstudianteScreen({super.key});

  @override
  State<RegistrarEstudianteScreen> createState() =>
      _RegistrarEstudianteScreenState();
}

class _RegistrarEstudianteScreenState
    extends State<RegistrarEstudianteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ruController = TextEditingController();
  final _nombresController = TextEditingController();
  final _paternoController = TextEditingController();
  final _maternoController = TextEditingController();
  final _service = EstudianteService();
  bool _guardando = false;
  Estudiante? _ultimoRegistrado;

  @override
  void dispose() {
    _ruController.dispose();
    _nombresController.dispose();
    _paternoController.dispose();
    _maternoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final ru = _ruController.text.trim();
      final existe = await _service.existeRu(ru);
      if (existe) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este RU ya existe en la base de datos'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _guardando = false);
        return;
      }

      final estudiante = Estudiante(
        ru: ru,
        nombres: _nombresController.text.trim(),
        apellidoPaterno: _paternoController.text.trim(),
        apellidoMaterno: _maternoController.text.trim(),
      );

      await _service.registrar(estudiante);

      setState(() {
        _ultimoRegistrado = estudiante;
        _guardando = false;
      });

      _ruController.clear();
      _nombresController.clear();
      _paternoController.clear();
      _maternoController.clear();
      _formKey.currentState!.reset();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estudiante registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _ruController,
                  label: 'RU',
                  icon: Icons.numbers,
                  hint: 'Ingrese el RU (solo numeros)',
                  isNumeric: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nombresController,
                  label: 'Nombres',
                  icon: Icons.person,
                  hint: 'Ingrese los nombres',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _paternoController,
                  label: 'Apellido Paterno',
                  icon: Icons.badge,
                  hint: 'Ingrese el apellido paterno',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _maternoController,
                  label: 'Apellido Materno',
                  icon: Icons.badge_outlined,
                  hint: 'Ingrese el apellido materno',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Guardar Estudiante',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_ultimoRegistrado != null) ...[
            const SizedBox(height: 30),
            _buildQRCard(_ultimoRegistrado!),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es obligatorio';
        }
        if (isNumeric && !RegExp(r'^\d+$').hasMatch(value.trim())) {
          return 'Solo se permiten numeros';
        }
        return null;
      },
    );
  }

  Widget _buildQRCard(Estudiante estudiante) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1428),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0066FF), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'QR Generado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            estudiante.nombreCorto,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          Text(
            'RU: ${estudiante.ru}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: estudiante.ru,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implementar descarga del QR
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcion de descarga proximamente'),
                  ),
                );
              },
              icon: const Icon(Icons.download, color: Color(0xFF0066FF)),
              label: const Text('Descargar QR'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0066FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
