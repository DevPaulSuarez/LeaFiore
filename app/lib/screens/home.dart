// ═══ home.dart · PESTAÑA «INICIO» ═══
// Saludo, buscador, carrusel de plantas, cuidados de hoy, próximas cosechas,
// «Explorar plantas» por categoría, tiempos de cultivo, últimos diagnósticos y guía.
//   _harvests() → calcula qué plantas están cerca de cosecha/floración.
//   PlantCard   → tarjeta de planta (se usa también en Mi jardín).
//   ScanRow     → fila de un diagnóstico.
// Para reordenar secciones, mueve los bloques dentro de build().

import 'package:flutter/material.dart';

import '../data/library.dart';
import '../models.dart';
import '../services/notifications.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';
import 'library.dart';
import 'plant_detail.dart';
import 'result.dart';
import 'shell.dart';
import 'timeline.dart';

/// Inicio (imagen 2 izquierda).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final h = DateTime.now().hour;
    // ✏️ MODIFICAR: saludo según la hora.
    final greet = h < 12 ? 'Buenos días' : (h < 20 ? 'Buenas tardes' : 'Buenas noches');
    final tasks = state.allTasks().where((t) => t.due <= 0).toList();
    final water = tasks.where((t) => t.task == CareTask.water).toList();
    final plants = state.plants.where((p) => p.name.toLowerCase().contains(_q)).toList();
    final article = articles[DateTime.now().day % articles.length];

    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 130),
      children: [
        TopBar(
          leading: CircleBtn(onTap: () => openLibrary(context), child: const Icon(Icons.menu_rounded)),
          trailing: CircleBtn(
            dot: tasks.isNotEmpty,
            onTap: () async {
              final ok = await Notifications.instance.requestPermission();
              if (context.mounted) toast(context, ok ? '🔔 Recordatorios activados' : 'Activa las notificaciones en Ajustes del teléfono');
            },
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        Text('$greet,', style: const TextStyle(fontSize: 28, height: 1.15)),
        Text('${state.userName.isEmpty ? 'Jardinero/a' : state.userName} 🌿', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.15)),
        const SizedBox(height: 6),
        const Text('Cuida tus plantas y ellas florecerán 🌱', style: TextStyle(color: C.muted, fontSize: 14)),
        const SizedBox(height: 18),
        Glass(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: C.muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Buscar en mis plantas…', hintStyle: TextStyle(color: C.muted)),
              ),
            ),
          ]),
        ),
        SectionHead('Mis plantas', action: 'Ver todas', onAction: () => Shell.goTab(context, 1)),
        if (state.plants.isEmpty)
          Glass(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Emoji('🪴', size: 56),
              const SizedBox(height: 8),
              const Text('Tu jardín está vacío.\nAñade tu primera planta para recibir recordatorios.', textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
              const SizedBox(height: 14),
              Btn('Añadir planta', expand: false, onTap: () => openLibrary(context)),
            ]),
          )
        else
          SizedBox(
            height: 236,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                for (final p in plants) Padding(padding: const EdgeInsets.only(right: 12), child: PlantCard(p)),
                SizedBox(
                  width: 140,
                  child: Glass(
                    padding: const EdgeInsets.all(10),
                    onTap: () => openLibrary(context),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_rounded, size: 40, color: C.green700),
                      SizedBox(height: 6),
                      Text('Añadir', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('Nueva planta', style: TextStyle(fontSize: 12, color: C.muted)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        SectionHead('Cuidados de hoy', action: tasks.isEmpty ? null : '${tasks.length} tareas', onAction: () => Shell.goTab(context, 2)),
        if (water.isNotEmpty)
          _Row(
            icon: '💧',
            title: 'Regar ${water.length} planta${water.length > 1 ? 's' : ''}',
            sub: water.map((t) => t.plant.name).join(', '),
            onTap: () => Shell.goTab(context, 2),
          ),
        for (final t in tasks.where((t) => t.task != CareTask.water).take(3))
          _Row(icon: t.task.icon, title: '${t.task.label}: ${t.plant.name}', sub: dueLabel(t.due), late: t.due < 0, onTap: () => showTaskSheet(context, t.plant, t.task)),
        if (tasks.isEmpty) const _Row(icon: '✨', title: 'Todo al día', sub: 'No hay tareas pendientes hoy'),
        if (_harvests(state).isNotEmpty) ...[
          const SectionHead('🧺 Próximas cosechas y floraciones'),
          for (final (p, days, label) in _harvests(state).take(4))
            _Row(
              icon: label == 'Cosecha' ? '🧺' : (label == 'Floración' ? '🌸' : '🌱'),
              title: '$label: ${p.name}',
              sub: days <= 0 ? '¡Ya está lista!' : 'Faltan ${fmtDuration(days, days)}',
              onTap: () => openPlant(context, p),
            ),
        ],
        const SectionHead('Explorar plantas'),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              for (final c in PlantCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 100,
                    child: Glass(
                      padding: const EdgeInsets.all(8),
                      onTap: () => openLibrary(context, category: c),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Emoji(c.icon, size: 28),
                        const SizedBox(height: 6),
                        Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Glass(
          padding: const EdgeInsets.all(16),
          onTap: () => openTimeline(context),
          child: const Row(children: [
            RoundIcon('⏱️'),
            SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tiempos de cultivo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                SizedBox(height: 3),
                Text('De microgreens en 7 días a frutales en años', style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: C.muted),
          ]),
        ),
        if (state.scans.isNotEmpty) ...[
          SectionHead('Últimos diagnósticos', action: 'Nuevo', onAction: () => openScan(context)),
          for (final s in state.scans.take(3)) ScanRow(s),
        ],
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Guía de cuidado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 6),
                Text(article.title, style: const TextStyle(fontSize: 12, color: C.muted)),
                const SizedBox(height: 12),
                Btn('Leer', small: true, expand: false, style: BtnStyle.ghost, onTap: () => showArticle(context, article)),
              ]),
            ),
            Emoji(article.emoji, size: 54),
          ]),
        ),
      ],
    );
  }
}

/// Plantas con cosecha/floración pendiente, de la más próxima a la más lejana.
List<(Plant, int, String)> _harvests(AppState state) {
  final out = <(Plant, int, String)>[];
  for (final p in state.plants) {
    final g = p.spec.growth;
    final pr = growthProgress(p);
    if (g == null || pr == null || pr.done) continue;
    final d = g.isHarvest ? (state.dueIn(p, CareTask.harvest) ?? pr.left) : pr.left;
    if (!g.isHarvest && d < -30) continue; // la floración ya pasó
    out.add((p, d, g.label));
  }
  out.sort((a, b) => a.$2.compareTo(b.$2));
  return out;
}

class _Row extends StatelessWidget {
  final String icon, title, sub;
  final bool late;
  final VoidCallback? onTap;
  const _Row({required this.icon, required this.title, required this.sub, this.late = false, this.onTap});

  @override
  Widget build(BuildContext context) => Glass(
        margin: const EdgeInsets.only(bottom: 10),
        onTap: onTap,
        child: Row(children: [
          RoundIcon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 3),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: late ? C.red : C.muted)),
            ]),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: C.muted),
        ]),
      );
}

/// Tarjeta de planta usada en Inicio y Mi jardín.
class PlantCard extends StatelessWidget {
  final Plant plant;
  final bool showCare;
  const PlantCard(this.plant, {super.key, this.showCare = false});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hl = state.health(plant);
    return SizedBox(
      width: showCare ? null : 140,
      child: Glass(
        padding: const EdgeInsets.all(10),
        onTap: () => openPlant(context, plant),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          LayoutBuilder(builder: (_, c) => PlantThumb(plant, size: c.maxWidth, radius: 16)),
          const SizedBox(height: 10),
          Text(plant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(plant.room, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: C.muted)),
          const SizedBox(height: 6),
          StatusLine(hl.level, hl.text),
          if (showCare) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 4, runSpacing: 4, children: [
              for (final t in CareTask.values)
                if (state.dueIn(plant, t) case final d?)
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: d < 0 ? const Color(0xFFF6DCD5) : (d == 0 ? C.green100 : Colors.white.withValues(alpha: .55)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Tooltip(message: '${t.label}: ${dueLabel(d)}', child: Emoji(t.icon, size: 12)),
                  ),
            ]),
          ],
        ]),
      ),
    );
  }
}

/// Fila de diagnóstico.
class ScanRow extends StatelessWidget {
  final Scan scan;
  const ScanRow(this.scan, {super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Glass(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => openResult(context, scan),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(state.photoFile(scan.photo), width: 54, height: 54, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(width: 54, height: 54, child: Center(child: Emoji('🌿', size: 28)))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(scan.result.problem, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text('${scan.result.plantGuess} · ${fmtDate(scan.at)}', style: const TextStyle(fontSize: 12, color: C.muted)),
          ]),
        ),
        Pill(statusText(scan.result.status), kind: pillFor(scan.result.status)),
      ]),
    );
  }
}
