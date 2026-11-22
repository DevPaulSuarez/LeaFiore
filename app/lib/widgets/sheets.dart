import 'package:flutter/material.dart';

import '../data/library.dart';
import '../models.dart';
import '../screens/plant_detail.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'ui.dart';

/// Hoja con acciones de una tarea: hecho / posponer (imagen 3).
void showTaskSheet(BuildContext context, Plant p, CareTask t) {
  final state = AppScope.read(context);
  final d = state.dueIn(p, t) ?? 0;
  showGlassSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          PlantThumb(p),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${t.icon} ${t.label}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('${p.name} · ${dueLabel(d)}', style: const TextStyle(color: C.muted, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        Btn('✔  Marcar como hecho', onTap: () {
          state.complete(p, t);
          Navigator.pop(ctx);
          toast(context, '${t.icon} ${t.label}: ${p.name} ✔');
        }),
        const SizedBox(height: 10),
        Btn('⏰  Posponer 1 día', style: BtnStyle.ghost, onTap: () {
          state.snooze(p, t, 1);
          Navigator.pop(ctx);
          toast(context, 'Pospuesto a mañana');
        }),
        const SizedBox(height: 10),
        Btn('⏰  Posponer 2 días', style: BtnStyle.ghost, onTap: () {
          state.snooze(p, t, 2);
          Navigator.pop(ctx);
          toast(context, 'Pospuesto 2 días');
        }),
        const SizedBox(height: 10),
        Btn('Ver planta', style: BtnStyle.ghost, onTap: () {
          Navigator.pop(ctx);
          openPlant(context, p);
        }),
      ]));
}

void showArticle(BuildContext context, Article a) {
  showGlassSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Pill(a.tag, kind: PillKind.green),
        const SizedBox(height: 12),
        Text('${a.emoji} ${a.title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(a.body, style: const TextStyle(color: C.muted, height: 1.7, fontSize: 15)),
        const SizedBox(height: 20),
        Btn('Entendido', onTap: () => Navigator.pop(ctx)),
      ]));
}

void showGuides(BuildContext context) {
  showGlassSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Guías de cuidado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        for (final a in articles)
          Glass(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => showArticle(context, a),
            child: Row(children: [
              RoundIcon(a.emoji),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(a.tag, style: const TextStyle(color: C.muted, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: C.muted),
            ]),
          ),
      ]));
}
