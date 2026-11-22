// ═══ scan.dart · ESCÁNER (BOTÓN CENTRAL) ═══
// Eliges modo (planta/hoja/insecto), la planta, y tomas o eliges una foto.
// La envía a services/diagnosis.dart (o usa la demo si no hay clave de API),
// guarda el resultado y abre result.dart.
//   pickImage(maxWidth…, imageQuality) → tamaño/calidad de la foto enviada.
//   _describe() → texto extra sobre la planta que se envía a la IA.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/diagnosis.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'home.dart';
import 'result.dart';

/// Escáner de diagnóstico (imagen 3, pantalla de cámara).
class ScanScreen extends StatefulWidget {
  final String? plantId;
  const ScanScreen({super.key, this.plantId});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  ScanMode _mode = ScanMode.hoja;
  String? _plantId;
  Uint8List? _photo;
  bool _busy = false;
  late final AnimationController _line = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _plantId = widget.plantId;
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  Future<void> _take(ImageSource source) async {
    final state = AppScope.read(context);
    final XFile? x;
    try {
      // ✏️ MODIFICAR: tamaño y calidad de la foto que se envía.
      x = await ImagePicker().pickImage(source: source, maxWidth: 1568, maxHeight: 1568, imageQuality: 85);
    } catch (e) {
      if (mounted) toast(context, 'No se pudo abrir la cámara. Revisa los permisos.');
      return;
    }
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _photo = bytes;
      _busy = true;
    });

    final plant = state.plantById(_plantId);
    Diagnosis result;
    try {
      if (state.apiKey.isNotEmpty) {
        result = await DiagnosisService.diagnose(
          apiKey: state.apiKey,
          jpegBytes: bytes,
          mode: _mode,
          plantName: plant == null ? null : _describe(plant),
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 1800));
        result = DiagnosisService.demo(_mode);
        if (mounted) toast(context, 'Modo demo · añade tu clave en Perfil');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _photo = null;
      });
      toast(context, e is DiagnosisException ? e.message : 'Sin conexión. Inténtalo de nuevo.');
      return;
    }

    final name = await state.storePhoto(bytes);
    final scan = Scan(
      id: newId(),
      at: DateTime.now(),
      plantId: _plantId,
      mode: _mode,
      photo: name,
      result: result,
      demo: state.apiKey.isEmpty,
    );
    if (plant != null && plant.photo == null && _mode == ScanMode.planta) plant.photo = name;
    await state.addScan(scan);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultScreen(scanId: scan.id)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      body: Column(children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            if (_photo != null)
              Image.memory(_photo!, fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(colors: [Color(0xFF2F4A36), Color(0xFF0F1A12)], radius: .9),
                ),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Opacity(opacity: .85, child: Emoji(_mode.icon, size: 80)),
                  const SizedBox(height: 12),
                  const Text('Toca el botón para tomar una foto\no elige una de tu galería',
                      textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFCFE0C6))),
                ]),
              ),
            // marco de enfoque
            LayoutBuilder(builder: (_, c) {
              final rect = Rect.fromLTRB(c.maxWidth * .14, c.maxHeight * .24, c.maxWidth * .86, c.maxHeight * .72);
              return Stack(children: [
                Positioned.fromRect(rect: rect, child: CustomPaint(painter: _FramePainter())),
                if (_busy)
                  AnimatedBuilder(
                    animation: _line,
                    builder: (_, _) => Positioned(
                      left: rect.left,
                      width: rect.width,
                      top: rect.top + rect.height * _line.value,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.transparent, Color(0xFFB9F5A0), Colors.transparent]),
                          boxShadow: [BoxShadow(color: const Color(0xFFB9F5A0).withValues(alpha: .8), blurRadius: 18)],
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
            if (_busy)
              Container(
                color: const Color(0xFF0F1A12).withValues(alpha: .45),
                alignment: Alignment.center,
                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 54, height: 54, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4)),
                  SizedBox(height: 16),
                  Text('Analizando…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Revisando hojas, plagas y síntomas', style: TextStyle(color: Color(0xFFCFE0C6), fontSize: 13)),
                ]),
              ),
            Positioned(
              top: pad.top + 12,
              left: 18,
              right: 18,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                CircleBtn(dark: true, onTap: _busy ? null : () => Navigator.pop(context), child: const Icon(Icons.close_rounded)),
                CircleBtn(dark: true, onTap: () => _help(context), child: const Icon(Icons.help_outline_rounded)),
              ]),
            ),
            if (!_busy)
              Positioned(
                top: pad.top + 70,
                left: 0,
                right: 0,
                child: Text(_mode.hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 6, color: Colors.black)])),
              ),
          ]),
        ),
        // ---------- controles ----------
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _busy ? 0 : 1,
          child: IgnorePointer(
            ignoring: _busy,
            child: Container(
              padding: EdgeInsets.fromLTRB(18, 16, 18, pad.bottom + 20),
              color: const Color(0xFF0F1A12),
              child: Column(children: [
                if (state.plants.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _plantId,
                        isExpanded: true,
                        dropdownColor: C.green800,
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Sin asignar a una planta', overflow: TextOverflow.ellipsis)),
                          for (final p in state.plants) DropdownMenuItem(value: p.id, child: Text('${p.name} · ${p.room}', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setState(() => _plantId = v),
                      ),
                    ),
                  ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final m in ScanMode.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _mode = m),
                        child: Column(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: m == _mode ? Colors.white : Colors.white12,
                              border: Border.all(color: m == _mode ? Colors.white30 : Colors.white24, width: m == _mode ? 4 : 1),
                            ),
                            child: Emoji(m.icon, size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(m.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: m == _mode ? Colors.white : const Color(0xFFB9C9B2),
                                fontWeight: m == _mode ? FontWeight.w600 : FontWeight.w400,
                              )),
                        ]),
                      ),
                    ),
                ]),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _SideBtn(icon: Icons.photo_library_rounded, onTap: () => _take(ImageSource.gallery)),
                  GestureDetector(
                    onTap: () => _take(ImageSource.camera),
                    child: Container(
                      width: 78,
                      height: 78,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                      child: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.photo_camera_rounded, color: C.green800, size: 28)),
                    ),
                  ),
                  _SideBtn(icon: Icons.history_rounded, onTap: () => _history(context)),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  void _help(BuildContext context) {
    final hasKey = AppScope.read(context).apiKey.isNotEmpty;
    showGlassSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Consejos para un buen diagnóstico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final t in const [
            'Usa luz natural, sin flash.',
            'Para hojas: fotografía también el envés, ahí se esconden muchas plagas.',
            'Para insectos: acércate todo lo que permita el enfoque.',
            'Para la planta completa: que se vea la maceta y el sustrato.',
            'Asigna la foto a tu planta para guardar su historial de salud.',
          ])
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('•  $t', style: const TextStyle(color: C.muted, height: 1.5))),
          const SizedBox(height: 10),
          Text(hasKey ? '✅ Diagnóstico con IA activo.' : '⚠️ Sin clave de API: se mostrará un resultado de ejemplo. Añádela en Perfil.',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          Btn('Entendido', onTap: () => Navigator.pop(ctx)),
        ]));
  }

  void _history(BuildContext context) {
    final state = AppScope.read(context);
    showGlassSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Diagnósticos anteriores', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (state.scans.isEmpty) const Text('Todavía no hay diagnósticos.', style: TextStyle(color: C.muted)),
          for (final s in state.scans) ScanRow(s),
        ]));
  }
}

String _describe(Plant p) {
  final s = p.spec;
  final base = '${s.name}${s.sci.isEmpty ? '' : ' (${s.sci})'}';
  final h = s.hydro;
  if (h == null) return base;
  return '$base, cultivada en hidroponía (${h.system}; pH ideal ${h.ph}, EC ${h.ec}). '
      'Considera también problemas de solución nutritiva, pH, raíces y algas';
}

class _SideBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SideBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(width: 52, height: 52, child: Icon(icon, color: Colors.white)),
        ),
      );
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 34.0, r = 14.0;
    void corner(Offset o, double dx, double dy) {
      final path = Path()
        ..moveTo(o.dx, o.dy + dy * l)
        ..lineTo(o.dx, o.dy + dy * r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + dx * r, o.dy)
        ..lineTo(o.dx + dx * l, o.dy);
      canvas.drawPath(path, p);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(s.width, 0), -1, 1);
    corner(Offset(0, s.height), 1, -1);
    corner(Offset(s.width, s.height), -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
