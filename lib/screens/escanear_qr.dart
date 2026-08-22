import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/estudiante_service.dart';
import '../services/asistencia_service.dart';

class EscanearQRScreen extends StatefulWidget {
  const EscanearQRScreen({super.key});

  @override
  State<EscanearQRScreen> createState() => _EscanearQRScreenState();
}

class _EscanearQRScreenState extends State<EscanearQRScreen> {
  final _estudianteService = EstudianteService();
  final _asistenciaService = AsistenciaService();
  MobileScannerController? _cameraController;
  bool _procesando = false;
  String? _ultimoResultado;
  bool _escaneoActivo = true;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_escaneoActivo || _procesando) return;

    for (final barcode in capture.barcodes) {
      final data = barcode.rawValue;
      if (data != null && data != _ultimoResultado) {
        _ultimoResultado = data;
        _procesarQR(data);
        break;
      }
    }
  }

  Future<void> _procesarQR(String ru) async {
    if (!mounted) return;
    setState(() => _procesando = true);

    try {
      final estudiante = await _estudianteService.buscarPorRu(ru);

      if (!mounted) return;

      if (estudiante == null) {
        _mostrarResultado(
          exito: false,
          titulo: 'Estudiante no encontrado',
          mensaje: 'No existe un estudiante con RU: $ru',
        );
        setState(() => _procesando = false);
        return;
      }

      final duplicado = await _asistenciaService.verificarDuplicado(ru);

      if (!mounted) return;

      if (duplicado != null) {
        _mostrarResultado(
          exito: false,
          titulo: 'Ya registró hoy',
          mensaje:
              '${estudiante.nombreCorto} ya registro asistencia a las ${duplicado['hora']}',
        );
        setState(() => _procesando = false);
        return;
      }

      await _asistenciaService.registrarAsistencia(
        ru: estudiante.ru,
        nombres: estudiante.nombres,
        apellidoPaterno: estudiante.apellidoPaterno,
        apellidoMaterno: estudiante.apellidoMaterno,
        estado: 'Presente',
      );

      _mostrarResultado(
        exito: true,
        titulo: 'Asistencia Registrada',
        mensaje:
            '${estudiante.nombreCorto}\nRU: ${estudiante.ru}\nHora: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      _mostrarResultado(
        exito: false,
        titulo: 'Error',
        mensaje: 'Error al procesar: $e',
      );
    }

    setState(() => _procesando = false);
  }

  void _mostrarResultado({
    required bool exito,
    required String titulo,
    required String mensaje,
  }) {
    if (!mounted) return;

    // Pausar escaneo mientras se muestra el dialog
    setState(() => _escaneoActivo = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A1428),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: exito ? const Color(0xFF00FFCC) : Colors.redAccent,
            width: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              exito ? Icons.check_circle : Icons.error,
              color: exito ? const Color(0xFF00FFCC) : Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: exito ? const Color(0xFF00FFCC) : Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Reanudar escaneo
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _escaneoActivo = true;
                      _ultimoResultado = null;
                    });
                  }
                });
              },
              child: Text(
                'Continuar',
                style: TextStyle(
                  color: exito ? const Color(0xFF00FFCC) : Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con instrucciones
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0A1428),
          child: const Column(
            children: [
              Icon(Icons.qr_code_scanner, color: Color(0xFF00FFCC), size: 40),
              SizedBox(height: 8),
              Text(
                'Apunta la camara al codigo QR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'El escaneo es automatico',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),

        // Camara
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _cameraController,
                onDetect: _onDetect,
              ),
              // Overlay de escaneo
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _procesando
                          ? Colors.orange
                          : const Color(0xFF00FFCC),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Indicador de procesamiento
              if (_procesando)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FFCC),
                    strokeWidth: 3,
                  ),
                ),
              // Marco decorativo
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Escaneo automatico activo',
                      style: TextStyle(
                        color: Color(0xFF00FFCC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Boton de pausa/reanudar
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0A1428),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _escaneoActivo = !_escaneoActivo;
                });
                if (_escaneoActivo) {
                  _cameraController?.start();
                } else {
                  _cameraController?.stop();
                }
              },
              icon: Icon(
                _escaneoActivo ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              label: Text(
                _escaneoActivo ? 'Pausar escaneo' : 'Reanudar escaneo',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _escaneoActivo
                    ? Colors.orange
                    : const Color(0xFF00FFCC),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
