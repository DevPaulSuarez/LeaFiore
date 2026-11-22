// ═══ shell.dart · ESTRUCTURA PRINCIPAL Y BARRA INFERIOR ═══
// Contiene las 4 pestañas (Inicio, Mi jardín, Cuidados, Perfil) y la barra
// flotante de cristal con el botón de escanear en el centro.
//   _tabBtn(...)  → cada botón de la barra (icono y texto ✏️).
//   Shell.goTab() → cambiar de pestaña desde otra pantalla.
//   openScan()    → abrir el escáner.   LeafPage → fondo para pantallas secundarias.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/ui.dart';
import 'care.dart';
import 'garden.dart';
import 'home.dart';
import 'profile.dart';
import 'scan.dart';

/// Contenedor principal con la barra inferior flotante de vidrio (imagen 2).
class Shell extends StatefulWidget {
  const Shell({super.key});

  /// Cambia de pestaña desde cualquier pantalla hija.
  static void goTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_ShellState>()?.setTab(index);

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void setTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: LeafBackground(
        child: IndexedStack(index: _tab, children: const [HomeScreen(), GardenScreen(), CareScreen(), ProfileScreen()]),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: C.glassBorder),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                // ✏️ MODIFICAR: iconos y nombres de la barra inferior.
                _tabBtn(0, Icons.home_rounded, 'Inicio'),
                _tabBtn(1, Icons.eco_rounded, 'Mi jardín'),
                _ScanTab(onTap: () => openScan(context)),
                _tabBtn(2, Icons.water_drop_rounded, 'Cuidados'),
                _tabBtn(3, Icons.person_rounded, 'Perfil'),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(int i, IconData icon, String label) {
    final on = _tab == i;
    final color = on ? C.green700 : C.muted;
    return InkResponse(
      onTap: () => setTab(i),
      radius: 36,
      child: SizedBox(
        width: 62,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, style: TextStyle(fontSize: 11, color: color, fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
          ),
        ]),
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanTab({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.green500, C.green800]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: C.green800.withValues(alpha: .45), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 28),
        ),
      );
}

/// Abre el escáner, opcionalmente asignado a una planta.
void openScan(BuildContext context, {String? plantId}) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScanScreen(plantId: plantId)));
}

/// Página secundaria con el mismo fondo de hojas.
class LeafPage extends StatelessWidget {
  final Widget child;
  const LeafPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(body: LeafBackground(child: child));
}
