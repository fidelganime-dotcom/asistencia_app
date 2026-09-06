import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _modoClaro = false;

  final _pantallas = const [
    RegistrarEstudianteScreen(),
    ListaEstudiantesScreen(),
    EscanearQRScreen(),
    AsistenciaManualScreen(),
    VerAsistenciaScreen(),
  ];

  final _iconos = const [
    Icons.person_add_rounded,
    Icons.list_alt_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.edit_note_rounded,
    Icons.bar_chart_rounded,
  ];

  final _titulos = const [
    'Registrar',
    'Lista',
    'Escanear',
    'Manual',
    'Asistencia',
  ];

  @override
  Widget build(BuildContext context) {
    // Sincronizar con el tema actual del sistema
    final bool temaSistemaClaro = Theme.of(context).brightness == Brightness.light;
    if (temaSistemaClaro != _modoClaro) {
      setState(() => _modoClaro = temaSistemaClaro);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0066FF), Color(0xFF00FFCC)],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INGENIERIA DE SISTEMAS',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                ),
                Text(
                  'Logica, Programacion e Inteligencia',
                  style: TextStyle(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botón para alternar modo claro/oscuro
          IconButton(
            icon: Icon(
              _modoClaro ? Icons.dark_mode : Icons.light_mode,
              color: _modoClaro ? Colors.white : Colors.black87,
            ),
            tooltip: _modoClaro ? 'Modo oscuro' : 'Modo claro',
            onPressed: () {
              setState(() {
                _modoClaro = !_modoClaro;
              });
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _modoClaro ? Color(0xFFE0E5EC) : Color(0xFF0D1B2A),
              _modoClaro ? Color(0xFF1B2838) : Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: SafeArea(child: _pantallas[_indiceActual]),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: NavigationBar(
            selectedIndex: _indiceActual,
            onDestinationSelected: (index) => setState(() => _indiceActual = index),
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0xFF0066FF).withValues(alpha: 0.3),
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: List.generate(5, (index) {
              final isSelected = _indiceActual == index;
              final color = index == 2 ? const Color(0xFF00FFCC) : const Color(0xFF0066FF);
              return NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Icon(
                    _iconos[index],
                    color: isSelected ? color : Colors.white54,
                    size: 24,
                  ),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconos[index], color: color, size: 24),
                ),
                label: _titulos[index],
              );
            }),
          ),
        ),
      ),
    );
  }
}