import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/notifications.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/leaf_logo.dart';
import 'shell.dart';

/// Pantalla de introducción (imagen 1): fondo verde oscuro, tarjeta de vidrio,
/// logo, nombre de la app y botón para empezar.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const _slides = [
    ('LeaFiore', 'Lleva la naturaleza a casa', 'Plantas bonitas.\nEspacios felices.\nTú, mejor.'),
    ('Cuidados', 'Nunca olvides regar', 'Te avisamos cuándo regar, abonar,\npulverizar y girar cada planta.'),
    ('Diagnóstico', 'Una foto lo dice todo', 'Fotografía hojas, insectos o la planta\nentera y te decimos qué le pasa.'),
  ];

  int _step = 0;
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = AppScope.read(context).userName;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final state = AppScope.read(context);
    state.userName = _name.text.trim();
    state.onboarded = true;
    await state.save();
    await Notifications.instance.requestPermission();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(pageBuilder: (_, _, _) => const Shell(), transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (title, tag, lines) = _slides[_step];
    final last = _step == _slides.length - 1;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A4430), Color(0xFF142318)]),
        ),
        child: Stack(children: [
          // Hojas grandes de fondo
          const _BigLeaf(right: -120, top: 60, size: 320, angle: .2, opacity: .55),
          const _BigLeaf(left: -120, bottom: 120, size: 260, angle: 1.8, opacity: .5),
          const _BigLeaf(right: -60, bottom: -40, size: 220, angle: 3.4, opacity: .3),
          const _BigLeaf(left: 40, top: -60, size: 160, angle: -.8, opacity: .25),
          SafeArea(
            child: Column(children: [
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 48,
                  child: last
                      ? null
                      : TextButton(
                          onPressed: () => setState(() => _step = _slides.length - 1),
                          child: const Text('Saltar', style: TextStyle(color: Color(0xFFD9E7D0))),
                        ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(26, 44, 26, 30),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(color: Colors.white.withValues(alpha: .22)),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Column(key: ValueKey(_step), mainAxisSize: MainAxisSize.min, children: [
                              const LeafLogo(size: 64, color: Color(0xFFDFECCF)),
                              const SizedBox(height: 8),
                              Text(title, style: serif(54)),
                              Text(tag, style: const TextStyle(color: Color(0xFFC9DDBF), fontSize: 16)),
                              const SizedBox(height: 24),
                              Text(lines, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE3ECDD), fontSize: 15, height: 1.7)),
                              const SizedBox(height: 30),
                              if (last) ...[
                                TextField(
                                  controller: _name,
                                  textAlign: TextAlign.center,
                                  maxLength: 24,
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: '¿Cómo te llamas?',
                                    hintStyle: const TextStyle(color: Color(0xFFC9DDBF)),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: .12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .3))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .3))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white70)),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                              _LightButton(
                                label: last ? 'Comenzar' : (_step == 0 ? 'Empezar' : 'Siguiente'),
                                onTap: last ? _finish : () => setState(() => _step++),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 26, top: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final on = i == _step;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: on ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(color: on ? Colors.white : Colors.white38, borderRadius: BorderRadius.circular(4)),
                    );
                  }),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LightButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LightButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          height: 54,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD9EBC9), Color(0xFFA9C99A)])),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(label, style: const TextStyle(color: C.green900, fontWeight: FontWeight.w600, fontSize: 15)),
                const Icon(Icons.arrow_forward_rounded, color: C.green900),
              ]),
            ),
          ),
        ),
      );
}

class _BigLeaf extends StatelessWidget {
  final double? left, right, top, bottom;
  final double size, angle, opacity;
  const _BigLeaf({this.left, this.right, this.top, this.bottom, required this.size, required this.angle, required this.opacity});

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
        child: Transform.rotate(
          angle: angle,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topRight: Radius.circular(size * .8), bottomLeft: Radius.circular(size * .8)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF6C9C64).withValues(alpha: opacity), const Color(0xFF2A4A2E).withValues(alpha: opacity)],
                ),
              ),
              child: CustomPaint(painter: _VeinPainter(opacity)),
            ),
          ),
        ),
      );
}

class _VeinPainter extends CustomPainter {
  final double opacity;
  _VeinPainter(this.opacity);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFFA8C99A).withValues(alpha: opacity * .6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(s.width * .1, s.height * .9), Offset(s.width * .9, s.height * .1), p);
    for (var i = 1; i < 5; i++) {
      final t = i / 5;
      final o = Offset(s.width * (.1 + .8 * t), s.height * (.9 - .8 * t));
      canvas.drawLine(o, o + Offset(-s.width * .12, -s.height * .12), p);
      canvas.drawLine(o, o + Offset(s.width * .12, s.height * .12), p);
    }
  }

  @override
  bool shouldRepaint(_VeinPainter old) => false;
}
