// ═══ timeline.dart · TIEMPOS DE CULTIVO ═══
// Lista de todas las plantas con cosecha/floración, ordenadas de la más rápida
// a la más lenta y agrupadas por rango (_buckets). La barra usa escala
// logarítmica de 7 días a 5 años (_lo, _hi).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/library.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'library.dart';
import 'shell.dart';

void openTimeline(BuildContext context, {PlantCategory? category}) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => TimelineScreen(initial: category)));
}

/// Tiempos de cosecha, floración y crecimiento: de lo más rápido a lo que tarda años.
class TimelineScreen extends StatefulWidget {
  final PlantCategory? initial;
  const TimelineScreen({super.key, this.initial});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  PlantCategory? _cat;

  // ✏️ MODIFICAR: grupos por duración (días máximos, título).
  static const _buckets = [
    (30, '⚡ Menos de 1 mes'),
    (90, '🌱 1 a 3 meses'),
    (180, '🌿 3 a 6 meses'),
    (365, '🌳 6 meses a 1 año'),
    (99999, '⏳ Más de 1 año'),
  ];

  // Escala logarítmica de 7 días a 5 años para que se vean rápidas y lentas.
  static const _lo = 7.0, _hi = 1825.0;
  double _pos(int days) => ((math.log(days.clamp(_lo, _hi)) - math.log(_lo)) / (math.log(_hi) - math.log(_lo))).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _cat = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final list = plantLibrary.where((s) => s.growth != null && (_cat == null || s.category == _cat)).toList()
      ..sort((a, b) => a.growth!.min != b.growth!.min ? a.growth!.min.compareTo(b.growth!.min) : a.growth!.max.compareTo(b.growth!.max));

    final children = <Widget>[];
    var lower = 0;
    for (final (upper, title) in _buckets) {
      final group = list.where((s) => s.growth!.min > lower && s.growth!.min <= upper).toList();
      lower = upper;
      if (group.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ));
      children.addAll(group.map(_row));
    }

    return LeafPage(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 40),
        children: [
          const TopBar(title: '⏱️ Tiempos de cultivo'),
          const Text(
            'Cuánto tarda cada planta en darte cosecha, flores o estar formada, de la más rápida a la que tarda años.',
            style: TextStyle(color: C.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          ChoiceChips<PlantCategory?>(
            items: [
              (null, 'Todas'),
              for (final c in PlantCategory.values)
                if (c != PlantCategory.interior) (c, c.label),
            ],
            leading: (c) => c == null ? null : CategoryIcon(c, size: 18),
            value: _cat,
            onChanged: (v) => setState(() => _cat = v),
          ),
          const SizedBox(height: 14),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: LayoutBuilder(builder: (_, c) {
              return SizedBox(
                height: 16,
                child: Stack(children: [
                  for (final (d, l) in const [(7, '1 sem'), (30, '1 mes'), (180, '6 m'), (365, '1 año'), (1825, '5 años')])
                    Positioned(
                      left: (_pos(d) * c.maxWidth - 20).clamp(0.0, c.maxWidth - 40),
                      width: 40,
                      child: Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: C.muted)),
                    ),
                ]),
              );
            }),
          ),
          ...children,
          const SizedBox(height: 12),
          const Text('Tiempos orientativos: dependen de la variedad, la luz, la temperatura y el sistema de cultivo.',
              textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _row(PlantSpec s) {
    final g = s.growth!;
    final color = switch (s.category) {
      PlantCategory.hidroponia => const Color(0xFF4A9BB5),
      PlantCategory.huerto => const Color(0xFFD9822B),
      PlantCategory.suculenta => C.green600,
      PlantCategory.flor => const Color(0xFFD45D8C),
      PlantCategory.interior => C.green700,
    };
    return Glass(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => showSpecDetail(context, s),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Emoji(s.emoji, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text('${s.category.icon} ${g.label} ${g.from}', style: const TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
          Text(fmtDuration(g.min, g.max), style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ]),
        if (g.repeat > 0)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 4),
            child: Text('🔁 Después: ${g.repeatNote ?? 'cada ${fmtDuration(g.repeat, g.repeat)}'}',
                style: const TextStyle(fontSize: 11.5, color: C.muted)),
          ),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (_, c) {
          final a = _pos(g.min) * c.maxWidth, b = math.max(_pos(g.max) * c.maxWidth, a + 8);
          return SizedBox(
            height: 8,
            child: Stack(children: [
              Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(99))),
              Positioned(
                left: a,
                width: b - a,
                top: 0,
                bottom: 0,
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}
