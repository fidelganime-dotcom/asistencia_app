import 'package:flutter/material.dart';
import 'registrar_estudiante.dart';
import 'lista_estudiantes.dart';
import 'escanear_qr.dart';
import 'asistencia_manual.dart';
import 'ver_asistencia.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0;

  final _pantallas = const [
    RegistrarEstudianteScreen(),
    ListaEstudiantesScreen(),
    EscanearQRScreen(),
    AsistenciaManualScreen(),
    VerAsistenciaScreen(),
  ];

  final _titulos = const [
    'Registrar Estudiante',
    'Lista Estudiantes',
    'Escanear QR',
    'Asistencia Manual',
    'Ver Asistencia',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.school, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INGENIERIA DE SISTEMAS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _titulos[_indiceActual],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0A1428),
        elevation: 0,
      ),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (index) {
          setState(() => _indiceActual = index);
        },
        backgroundColor: const Color(0xFF0A1428),
        indicatorColor: Colors.blue.withOpacity(0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_add_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.person_add, color: Color(0xFF0066FF)),
            label: 'Registrar',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.list_alt, color: Color(0xFF0066FF)),
            label: 'Lista',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.qr_code_scanner, color: Color(0xFF00FFCC)),
            label: 'Escanear',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.edit_note, color: Color(0xFF0066FF)),
            label: 'Manual',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF0066FF)),
            label: 'Asistencia',
          ),
        ],
      ),
    );
  }
}
