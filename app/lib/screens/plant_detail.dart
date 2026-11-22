import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/library.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';
import 'result.dart';
import 'shell.dart';

void openPlant(BuildContext context, Plant p) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: p.id)));
}

/// Ficha de la planta (imagen 2 centro + recordatorios e historial de la imagen 3).
class PlantDetailScreen extends StatelessWidget {
  final String plantId;
  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.plantById(plantId);
    if (p == null) return const LeafPage(child: SizedBox());
    final spec = p.spec;
    final hl = state.health(p);
    final scans = state.scans.where((s) => s.plantId == p.id).toList();
    final top = MediaQuery.of(context).padding.top;

    return LeafPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ---------- cabecera ----------
          SizedBox(
            height: 340 + top,
            child: Stack(children: [
              if (p.photo != null)
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0, .7, 1],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: Image.file(state.photoFile(p.photo!), fit: BoxFit.cover),
                  ),
                )
              else
                Positioned(right: 4, bottom: 10, child: Emoji(spec.emoji, size: 170)),
              Padding(
                padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TopBar(trailing: CircleBtn(onTap: () => _menu(context, p), child: const Icon(Icons.more_horiz_rounded))),
                  SizedBox(
                    width: 220,
                    child: Text(p.name,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          color: p.photo != null ? Colors.white : C.ink,
                          shadows: p.photo != null ? const [Shadow(blurRadius: 10, color: Colors.black54)] : null,
                        )),
                  ),
                  const SizedBox(height: 6),
                  Text(spec.sci.isEmpty ? p.room : spec.sci,
                      style: TextStyle(fontStyle: FontStyle.italic, color: p.photo != null ? Colors.white : C.muted, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [Pill('● ${hl.text}', kind: pillFor(hl.level)), Pill('📍 ${p.room}')]),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // ---------- resumen ----------
              Glass(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Resumen de cuidados', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(children: [
                    if (spec.hydro case final h?) ...[
                      _Stat('⚗️', 'pH', h.ph),
                      _Stat('⚡', 'EC', h.ec),
                    ] else
                      _Stat('💧', 'Agua', 'Cada ${p.interval(CareTask.water)} días'),
                    _Stat('☀️', 'Luz', spec.light),
                    _Stat('🌡️', 'Temp', spec.temp),
                    if (!spec.isHydro) _Stat('💨', 'Humedad', spec.humidity),
                  ]),
                  if (spec.hydro case final h?) ...[
                    const SizedBox(height: 10),
                    Text('🔧 Sistema: ${h.system}', style: const TextStyle(fontSize: 13, color: C.muted)),
                  ],
                ]),
              ),
              if (spec.growth != null) _GrowthCard(plant: p),
              SectionHead('Próximos cuidados', action: 'Ajustar', onAction: () => _frequency(context, p)),
              SizedBox(
                height: 142,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    for (final t in CareTask.values)
                      if (state.dueIn(p, t) case final d?) _CareRing(plant: p, task: t, due: d),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Builder(builder: (context) {
                    final harvestNow = (state.dueIn(p, CareTask.harvest) ?? 1) <= 0;
                    final task = harvestNow ? CareTask.harvest : (spec.isHydro ? CareTask.topUp : CareTask.water);
                    final label = switch (task) {
                      CareTask.harvest => '🧺  Registrar cosecha',
                      CareTask.topUp => '🚰  Rellené el depósito',
                      _ => '💧  Registrar riego',
                    };
                    return Btn(label, onTap: () {
                      state.complete(p, task);
                      toast(context, '${task.icon} ${task.label}: ${p.name} ✔');
                    });
                  }),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Glass(
                    padding: EdgeInsets.zero,
                    radius: 18,
                    alpha: .62,
                    onTap: () => openScan(context, plantId: p.id),
                    child: const Center(child: Icon(Icons.photo_camera_rounded, color: C.green800)),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              // ---------- consejos ----------
              Glass(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💡 Consejos', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  for (final t in spec.tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('•  $t', style: const TextStyle(color: C.muted, fontSize: 13, height: 1.5)),
                    ),
                  const SizedBox(height: 6),
                  Text(spec.toxic ? '⚠️ Tóxica para mascotas si la ingieren.' : '🐾 Segura para mascotas.',
                      style: const TextStyle(color: C.muted, fontSize: 13)),
                ]),
              ),
              // ---------- recordatorios ----------
              const SectionHead('Recordatorios'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3.1,
                padding: EdgeInsets.zero,
                children: [
                  for (final t in [...relevantTasks(p), if (spec.growth?.isHarvest ?? false) CareTask.harvest])
                    if (t == CareTask.harvest || p.interval(t) > 0)
                      Glass(
                        radius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onTap: () {
                          p.remindersOff.contains(t) ? p.remindersOff.remove(t) : p.remindersOff.add(t);
                          state.save();
                        },
                        child: Row(children: [
                          Expanded(child: Text('${t.icon} ${t.label}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                          IgnorePointer(
                            child: SizedBox(
                              width: 44,
                              height: 28,
                              child: FittedBox(
                                child: Switch(value: !p.remindersOff.contains(t), onChanged: (_) {}, activeTrackColor: C.green600),
                              ),
                            ),
                          ),
                        ]),
                      ),
                ],
              ),
              // ---------- diagnósticos ----------
              SectionHead('Salud y diagnósticos', action: 'Escanear', onAction: () => openScan(context, plantId: p.id)),
              if (scans.isEmpty)
                const Glass(
                  padding: EdgeInsets.all(20),
                  child: Text('Sin diagnósticos todavía. Toma una foto de una hoja, insecto o la planta entera.',
                      textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
                )
              else
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final s in scans)
                      GestureDetector(
                        onTap: () => openResult(context, s),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(fit: StackFit.expand, children: [
                            Image.file(state.photoFile(s.photo), fit: BoxFit.cover),
                            Positioned(left: 6, bottom: 6, child: Pill(fmtDate(s.at), fontSize: 10)),
                          ]),
                        ),
                      ),
                  ],
                ),
              // ---------- historial ----------
              const SectionHead('Historial'),
              if (p.history.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('Aquí aparecerán los riegos y cuidados que registres.', style: TextStyle(color: C.muted, fontSize: 13)),
                ),
              for (final h in p.history.take(8))
                Glass(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    RoundIcon(h.task.icon, size: 36),
                    const SizedBox(width: 12),
                    Expanded(child: Text(h.task.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text(fmtDateTime(h.at), style: const TextStyle(color: C.muted, fontSize: 12)),
                  ]),
                ),
              const SizedBox(height: 12),
              Glass(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('📖 Sobre ${spec.specIdName(p)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(spec.about, style: const TextStyle(color: C.muted, height: 1.6, fontSize: 13)),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _frequency(BuildContext context, Plant p) {
    final state = AppScope.read(context);
    final tasks = relevantTasks(p);
    final ctrls = {for (final t in tasks) t: TextEditingController(text: '${p.interval(t)}')};
    showGlassSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Frecuencia de cuidados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Cada cuántos días. 0 = no aplica.', style: TextStyle(color: C.muted)),
          const SizedBox(height: 16),
          for (final t in tasks)
            GlassField(label: '${t.icon} ${t.label}', controller: ctrls[t]!, keyboard: TextInputType.number),
          Btn('Guardar', onTap: () {
            for (final t in tasks) {
              p.custom[t] = (int.tryParse(ctrls[t]!.text) ?? 0).clamp(0, 999);
            }
            state.save();
            Navigator.pop(ctx);
            toast(context, 'Frecuencias actualizadas');
          }),
        ]));
  }

  void _menu(BuildContext context, Plant p) {
    final state = AppScope.read(context);
    final nick = TextEditingController(text: p.name);
    var room = p.room;
    showGlassSheet(context, (ctx) => StatefulBuilder(
          builder: (ctx, setS) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            GlassField(label: 'Nombre', controller: nick),
            const Padding(padding: EdgeInsets.only(left: 4, bottom: 8), child: Text('Lugar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ChoiceChips<String>(items: [for (final r in rooms) (r, r)], value: room, onChanged: (r) => setS(() => room = r)),
            const SizedBox(height: 16),
            Btn('📷  Cambiar foto', style: BtnStyle.ghost, onTap: () async {
              final source = await pickSource(ctx);
              if (source == null) return;
              final x = await ImagePicker().pickImage(source: source, maxWidth: 1080, imageQuality: 80);
              if (x == null) return;
              p.photo = await state.storePhoto(await x.readAsBytes());
              await state.save();
              if (context.mounted) toast(context, 'Foto actualizada');
            }),
            const SizedBox(height: 10),
            Btn('Guardar', onTap: () {
              p.nickname = nick.text.trim();
              p.room = room;
              state.save();
              Navigator.pop(ctx);
            }),
            const SizedBox(height: 10),
            Btn('Eliminar planta', style: BtnStyle.danger, onTap: () async {
              if (!await confirm(ctx, '¿Eliminar ${p.name}?', 'Se borrarán también sus diagnósticos.')) return;
              await state.deletePlant(p);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                Navigator.pop(context);
                toast(context, 'Planta eliminada');
              }
            }),
          ]),
        ));
  }
}

extension on PlantSpec {
  String specIdName(Plant p) => id == customSpecId ? p.name : name;
}

/// Pregunta si usar cámara o galería.
Future<ImageSource?> pickSource(BuildContext context) => showGlassSheet<ImageSource>(
      context,
      (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Btn('📷  Tomar foto', onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        const SizedBox(height: 10),
        Btn('🖼️  Elegir de la galería', style: BtnStyle.ghost, onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ]),
    );

class _Stat extends StatelessWidget {
  final String icon, k, v;
  const _Stat(this.icon, this.k, this.v);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .45), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Emoji(icon, size: 18),
            const SizedBox(height: 6),
            Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(v, textAlign: TextAlign.center, maxLines: 3, style: const TextStyle(fontSize: 10.5, color: C.muted, height: 1.25)),
          ]),
        ),
      );
}

/// Anillo de progreso hacia el próximo cuidado (imagen 3).
class _CareRing extends StatelessWidget {
  final Plant plant;
  final CareTask task;
  final int due;
  const _CareRing({required this.plant, required this.task, required this.due});

  @override
  Widget build(BuildContext context) {
    final g = plant.spec.growth;
    final every = switch (task) {
      CareTask.check => 7,
      CareTask.harvest => plant.last[CareTask.harvest] == null ? g!.min : g!.repeat,
      _ => plant.interval(task),
    };
    final pct = due <= 0 ? 1.0 : ((every - due) / every).clamp(.04, 1.0);
    final color = due < 0 ? C.red : (due <= 1 ? C.amber : C.green600);
    return GestureDetector(
      onTap: () => showTaskSheet(context, plant, task),
      child: SizedBox(
        width: 96,
        child: Column(children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: Colors.white.withValues(alpha: .55),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Emoji(task.icon, size: 20),
                Text(task.label.split(' ').first, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          Text(dueLabel(due), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: due < 0 ? C.red : C.muted)),
        ]),
      ),
    );
  }
}

/// Tareas con frecuencia que aplican a esta planta (hidroponía o tierra).
List<CareTask> relevantTasks(Plant p) {
  const hydroOnly = {CareTask.topUp, CareTask.ph, CareTask.nutrients};
  return CareTask.periodic.where((t) => p.spec.isHydro ? hydroOnly.contains(t) || p.interval(t) > 0 : !hydroOnly.contains(t)).toList();
}

/// Progreso hacia la cosecha / floración.
class _GrowthCard extends StatelessWidget {
  final Plant plant;
  const _GrowthCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final g = plant.spec.growth!;
    final pr = growthProgress(plant)!;
    final start = plant.startedAt;
    final from = addDays(start, g.min), to = addDays(start, g.max);
    final icon = g.isHarvest ? '🧺' : (g.label == 'Floración' ? '🌸' : '🌱');
    final String status;
    if (pr.done) {
      status = 'Cosechada ✔';
    } else if (pr.ready) {
      status = g.isHarvest ? '¡Lista para cosechar!' : (g.label == 'Floración' ? 'En época de floración' : '¡Ya está formada!');
    } else {
      status = 'Faltan ${fmtDuration(pr.left, pr.left)}';
    }
    final lastH = plant.last[CareTask.harvest];

    return Glass(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Emoji(icon, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${g.label} · ${fmtDuration(g.min, g.max)} ${g.from}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(status, style: TextStyle(color: pr.ready ? C.green700 : C.muted, fontWeight: pr.ready ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: pr.pct, minHeight: 10, color: pr.ready ? C.green600 : C.green500, backgroundColor: Colors.white.withValues(alpha: .6)),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('Inicio ${fmtDate(start)} · día ${pr.elapsed.clamp(0, 99999)}', style: const TextStyle(fontSize: 11, color: C.muted))),
          Flexible(
            child: Text('Meta: ${fmtDate(from)} – ${fmtDate(to)}${g.max >= 365 ? ' ${to.year}' : ''}',
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: C.muted)),
          ),
        ]),
        if (g.repeat > 0) ...[
          const SizedBox(height: 8),
          Text('🔁 Después: ${g.repeatNote ?? 'cada ${fmtDuration(g.repeat, g.repeat)}'}', style: const TextStyle(fontSize: 12, color: C.muted)),
        ],
        if (lastH != null) Text('Última cosecha: ${fmtDate(lastH)}', style: const TextStyle(fontSize: 12, color: C.muted)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: start.isAfter(today()) ? today() : start,
              firstDate: addDays(today(), -(365 * 6)),
              lastDate: today(),
              helpText: 'Fecha de inicio',
            );
            if (d == null || !context.mounted) return;
            plant.plantedAt = dayOf(d);
            AppScope.read(context).save();
          },
          child: const Text('📅 Cambiar fecha de inicio', style: TextStyle(fontSize: 12, color: C.green700, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
