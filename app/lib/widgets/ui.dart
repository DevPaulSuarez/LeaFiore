// ═══ ui.dart · COMPONENTES VISUALES REUTILIZABLES ═══
// Piezas que se usan en todas las pantallas:
//   LeafBackground → fondo verde con hojas.   Glass → tarjeta de cristal (glassmorphism).
//   Btn / CircleBtn → botones.   Pill → etiqueta de color.   TopBar → cabecera.
//   Segment → selector de pestañas.   ChoiceChips → chips.   GlassField → campo de texto.
//   PlantThumb → miniatura de planta.   toast / showGlassSheet / confirm → avisos y diálogos.
//   fmtDate / weekdays → formato de fechas.
// Cambia el estilo aquí y se aplica en toda la app.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Fondo verde claro con hojas difuminadas (estilo de la imagen 2).
class LeafBackground extends StatelessWidget {
  final Widget child;
  const LeafBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE3EDDE), Color(0xFFB8CEB2)],
            ),
          ),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: const Stack(children: [
              _Leaf(left: -120, top: -80, w: 300, h: 480, angle: -.45, opacity: .55),
              _Leaf(right: -110, top: 300, w: 240, h: 400, angle: .6, opacity: .5),
              _Leaf(left: 30, bottom: -170, w: 220, h: 360, angle: 1.0, opacity: .4),
              _Leaf(right: 40, top: -140, w: 180, h: 300, angle: -1.0, opacity: .3),
            ]),
          ),
        ),
      ),
      Positioned.fill(child: child),
    ]);
  }
}

class _Leaf extends StatelessWidget {
  final double? left, right, top, bottom;
  final double w, h, angle, opacity;
  const _Leaf({this.left, this.right, this.top, this.bottom, required this.w, required this.h, required this.angle, required this.opacity});

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(topRight: Radius.circular(w), bottomLeft: Radius.circular(w)),
              gradient: LinearGradient(colors: [
                const Color(0xFF4E7D4F).withValues(alpha: opacity),
                const Color(0xFF2F5A35).withValues(alpha: opacity),
              ]),
            ),
          ),
        ),
      );
}

/// Tarjeta de vidrio esmerilado.
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double alpha;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.alpha = .42,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [BoxShadow(color: C.green900.withValues(alpha: .10), blurRadius: 30, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: C.glass(alpha),
            shape: RoundedRectangleBorder(borderRadius: br, side: BorderSide(color: C.glassBorder)),
            child: InkWell(
              onTap: onTap,
              borderRadius: br,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura de planta: foto si la hay, si no su emoji.
class PlantThumb extends StatelessWidget {
  final Plant plant;
  final double size;
  final double radius;
  const PlantThumb(this.plant, {super.key, this.size = 54, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: Colors.white.withValues(alpha: .45),
        alignment: Alignment.center,
        child: plant.photo != null
            ? Image.file(state.photoFile(plant.photo!), width: size, height: size, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(plant.spec.emoji, style: TextStyle(fontSize: size * .55)))
            : Text(plant.spec.emoji, style: TextStyle(fontSize: size * .55)),
      ),
    );
  }
}

class Emoji extends StatelessWidget {
  final String e;
  final double size;
  const Emoji(this.e, {super.key, this.size = 20});
  @override
  Widget build(BuildContext context) => Text(e, style: TextStyle(fontSize: size, height: 1.1));
}

/// Icono redondeado verde con un emoji.
class RoundIcon extends StatelessWidget {
  final String emoji;
  final double size;
  const RoundIcon(this.emoji, {super.key, this.size = 46});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: C.buttonGradient, borderRadius: BorderRadius.circular(size * .3)),
        child: Emoji(emoji, size: size * .42),
      );
}

enum PillKind { plain, green, warn, bad }

PillKind pillFor(HealthStatus s) => switch (s) {
      HealthStatus.sana => PillKind.green,
      HealthStatus.atencion => PillKind.warn,
      HealthStatus.enferma => PillKind.bad,
    };

String statusText(HealthStatus s) => switch (s) {
      HealthStatus.sana => 'Sana',
      HealthStatus.atencion => 'Atención',
      HealthStatus.enferma => 'Enferma',
    };

class Pill extends StatelessWidget {
  final String text;
  final PillKind kind;
  final double fontSize;
  const Pill(this.text, {super.key, this.kind = PillKind.plain, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      PillKind.plain => (Colors.white.withValues(alpha: .62), C.ink),
      PillKind.green => (C.green100, C.green800),
      PillKind.warn => (const Color(0xFFF7EAD0), const Color(0xFF8A5D12)),
      PillKind.bad => (const Color(0xFFF6DCD5), const Color(0xFF8F3424)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withValues(alpha: .6))),
      child: Text(text, style: TextStyle(fontSize: fontSize, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}

/// Punto de color + texto de estado.
class StatusLine extends StatelessWidget {
  final HealthStatus level;
  final String text;
  const StatusLine(this.level, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      HealthStatus.sana => C.green500,
      HealthStatus.atencion => C.amber,
      HealthStatus.enferma => C.red,
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: C.muted))),
    ]);
  }
}

class SectionHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHead(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: const TextStyle(color: C.green700, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ]),
      );
}

enum BtnStyle { primary, ghost, danger }

class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BtnStyle style;
  final bool small;
  final bool expand;
  final Widget? trailing;

  const Btn(this.label, {super.key, this.onTap, this.style = BtnStyle.primary, this.small = false, this.expand = true, this.trailing});

  @override
  Widget build(BuildContext context) {
    final h = small ? 38.0 : 54.0;
    final r = BorderRadius.circular(small ? 12 : 18);
    final (Gradient? g, Color? bg, Color fg) = switch (style) {
      BtnStyle.primary => (C.buttonGradient, null, Colors.white),
      BtnStyle.ghost => (null, Colors.white.withValues(alpha: .62), C.green800),
      BtnStyle.danger => (null, const Color(0xFFF6DCD5), const Color(0xFF8F3424)),
    };
    return Opacity(
      opacity: onTap == null ? .5 : 1,
      child: Container(
        height: h,
        width: expand ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: g,
          color: bg,
          borderRadius: r,
          border: style == BtnStyle.ghost ? Border.all(color: C.glassBorder) : null,
          boxShadow: style == BtnStyle.primary
              ? [BoxShadow(color: C.green700.withValues(alpha: .35), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: small ? 16 : 22),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: trailing != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: small ? 13 : 15)),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool dark;
  final bool dot;
  const CircleBtn({super.key, required this.child, this.onTap, this.dark = false, this.dot = false});

  @override
  Widget build(BuildContext context) => ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: dark ? Colors.black.withValues(alpha: .35) : C.glass(),
            shape: CircleBorder(side: BorderSide(color: dark ? Colors.white24 : C.glassBorder)),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(alignment: Alignment.center, children: [
                  IconTheme(data: IconThemeData(color: dark ? Colors.white : C.ink, size: 20), child: child),
                  if (dot)
                    Positioned(top: 9, right: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle))),
                ]),
              ),
            ),
          ),
        ),
      );
}

/// Barra superior simple: atrás + título + acción.
class TopBar extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final bool big;
  const TopBar({super.key, this.title, this.leading, this.trailing, this.big = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          height: 44,
          child: Row(children: [
            leading ?? (big ? const SizedBox() : CircleBtn(onTap: () => Navigator.maybePop(context), child: const Icon(Icons.arrow_back_rounded))),
            Expanded(
              child: Text(
                title ?? '',
                textAlign: big ? TextAlign.left : TextAlign.center,
                style: TextStyle(fontSize: big ? 26 : 17, fontWeight: big ? FontWeight.w700 : FontWeight.w600),
              ),
            ),
            trailing ?? const SizedBox(width: 42),
          ]),
        ),
      );
}

/// Segmentado tipo "Hoy / Próximas / Hechas".
class Segment<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  const Segment({super.key, required this.items, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Glass(
        radius: 99,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: items.map((it) {
            final on = it.$1 == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(it.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: on ? C.green600 : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: on ? [BoxShadow(color: C.green700.withValues(alpha: .35), blurRadius: 12, offset: const Offset(0, 4))] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(it.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: on ? Colors.white : C.muted)),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class ChoiceChips<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  const ChoiceChips({super.key, required this.items, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((it) {
          final on = it.$1 == value;
          return GestureDetector(
            onTap: () => onChanged(it.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: on ? C.green600 : Colors.white.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: on ? C.green600 : C.glassBorder),
              ),
              child: Text(it.$2, style: TextStyle(fontSize: 13, color: on ? Colors.white : C.ink)),
            ),
          );
        }).toList(),
      );
}

class GlassField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? help;
  final bool obscure;
  final TextInputType? keyboard;
  const GlassField({super.key, required this.label, required this.controller, this.hint, this.help, this.obscure = false, this.keyboard});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 6), child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            autocorrect: !obscure,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white.withValues(alpha: .62),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.glassBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.green600)),
            ),
          ),
          if (help != null) Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 0), child: Text(help!, style: const TextStyle(fontSize: 12, color: C.muted))),
        ]),
      );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 2200)));
}

/// Hoja inferior con efecto vidrio.
Future<T?> showGlassSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: C.green900.withValues(alpha: .35),
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .88),
          color: const Color(0xFFF0F6EC).withValues(alpha: .94),
          padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: const Color(0xFFB8C6B4), borderRadius: BorderRadius.circular(3)))),
              builder(ctx),
            ]),
          ),
        ),
      ),
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String message, {String ok = 'Eliminar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok, style: const TextStyle(color: C.red))),
      ],
    ),
  );
  return r ?? false;
}

String fmtDate(DateTime d) {
  const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
  return '${d.day} ${m[d.month - 1]}';
}

String fmtDateTime(DateTime d) => '${fmtDate(d)} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

const weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
