// ═══ library.dart · BIBLIOTECA Y AÑADIR PLANTA ═══
//   LibraryScreen  → lista de las 47 plantas con filtros por categoría y buscador.
//   showSpecDetail → hoja con la ficha de una especie (cuidados, cosecha, consejos).
//   AddPlantScreen → formulario para añadir una planta a tu jardín
//                    (foto, apodo, lugar, fecha de siembra, frecuencia de riego).
// Los DATOS de las plantas no están aquí: están en data/library.dart.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/library.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'plant_detail.dart';
import 'shell.dart';
import 'timeline.dart';

void openLibrary(BuildContext context, {PlantCategory? category}) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => LibraryScreen(initial: category)));
}

/// Pequeña etiqueta con el tiempo de cosecha/floración.
class GrowthBadge extends StatelessWidget {
  final Growth g;
  const GrowthBadge(this.g, {super.key});
  @override
  Widget build(BuildContext context) {
    final icon = g.isHarvest ? '🧺' : (g.label == 'Floración' ? '🌸' : '🌱');
    return Pill('$icon ${fmtDuration(g.min, g.max)}', kind: PillKind.green, fontSize: 10);
  }
}

/// Biblioteca de plantas por categorías (imagen 3 "Plant Library").
class LibraryScreen extends StatefulWidget {
  final PlantCategory? initial;
  const LibraryScreen({super.key, this.initial});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  PlantCategory? _cat;
  bool _byTime = false;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _cat = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final list = plantLibrary.where((s) {
      if (_cat != null && s.category != _cat) return false;
      return _q.isEmpty || '${s.name} ${s.sci}'.toLowerCase().contains(_q);
    }).toList();
    if (_byTime) {
      list.sort((a, b) => (a.growth?.min ?? 1 << 30).compareTo(b.growth?.min ?? 1 << 30));
    }

    return LeafPage(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 40),
        children: [
          TopBar(
            title: '📚 Biblioteca',
            trailing: CircleBtn(onTap: () => openTimeline(context, category: _cat), child: const Icon(Icons.timelapse_rounded)),
          ),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: C.muted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Buscar planta…', hintStyle: TextStyle(color: C.muted)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          ChoiceChips<PlantCategory?>(
            items: [(null, 'Todas'), for (final c in PlantCategory.values) (c, '${c.icon} ${c.label}')],
            value: _cat,
            onChanged: (v) => setState(() => _cat = v),
          ),
          const SizedBox(height: 4),
          SectionHead(
            '${list.length} plantas',
            action: _byTime ? '⏱️ Por tiempo ✓' : '⏱️ Ordenar por tiempo',
            onAction: () => setState(() => _byTime = !_byTime),
          ),
          for (final s in list)
            Glass(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () => showSpecDetail(context, s),
              child: Row(children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .5), borderRadius: BorderRadius.circular(14)),
                  child: Emoji(s.emoji, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(s.sci, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic, color: C.muted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 4, runSpacing: 4, children: [
                      if (s.growth != null) GrowthBadge(s.growth!),
                      if (_cat == null) Pill('${s.category.icon} ${s.category.label}', fontSize: 10),
                      for (final t in s.tags.take(2)) Pill(t, fontSize: 10),
                    ]),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: C.muted),
              ]),
            ),
          Glass(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddPlantScreen(spec: customBase))),
            child: const Row(children: [
              SizedBox(width: 58, height: 58, child: Center(child: Emoji('➕', size: 28))),
              SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Otra planta', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('Añádela con tus propios cuidados', style: TextStyle(color: C.muted, fontSize: 12)),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: C.muted),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Ficha resumida de una planta de la biblioteca.
void showSpecDetail(BuildContext context, PlantSpec s) {
  final g = s.growth;
  final h = s.hydro;
  Widget mini(String i, String k, String v) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .6), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Emoji(i, size: 18),
            const SizedBox(height: 4),
            Text(k, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(v, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: C.muted)),
          ]),
        ),
      );

  showGlassSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Emoji(s.emoji, size: 72)),
        const SizedBox(height: 6),
        Text(s.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text(s.sci, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic, color: C.muted)),
        const SizedBox(height: 8),
        Center(child: Pill('${s.category.icon} ${s.category.label}')),
        if (g != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: C.green100, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Emoji(g.isHarvest ? '🧺' : (g.label == 'Floración' ? '🌸' : '🌱'), size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${g.label}: ${fmtDuration(g.min, g.max)}', style: const TextStyle(fontWeight: FontWeight.w700, color: C.green800)),
                  Text(g.from, style: const TextStyle(fontSize: 12, color: C.green800)),
                  if (g.repeat > 0)
                    Text('Después: ${g.repeatNote ?? 'cada ${fmtDuration(g.repeat, g.repeat)}'}', style: const TextStyle(fontSize: 12, color: C.green800)),
                ]),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        if (h != null)
          Row(children: [mini('⚗️', 'pH', h.ph), mini('⚡', 'EC', h.ec), mini('☀️', 'Luz', s.light), mini('🌡️', 'Temp', s.temp)])
        else
          Row(children: [
            mini('💧', 'Agua', 'Cada ${s.every[CareTask.water]} días'),
            mini('☀️', 'Luz', s.light),
            mini('🌡️', 'Temp', s.temp),
            mini(s.toxic ? '⚠️' : '🐾', 'Mascotas', s.toxic ? 'Tóxica' : 'Segura'),
          ]),
        if (h != null) ...[
          const SizedBox(height: 10),
          Text('🔧 Sistema recomendado: ${h.system}', style: const TextStyle(fontSize: 13)),
        ],
        const SizedBox(height: 14),
        Text(s.about, style: const TextStyle(color: C.muted, height: 1.6)),
        const SizedBox(height: 18),
        Btn('＋  Añadir a mi jardín', onTap: () {
          Navigator.pop(ctx);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddPlantScreen(spec: s)));
        }),
      ]));
}

/// Añadir planta: foto, nombre, lugar, fecha de siembra y último riego.
class AddPlantScreen extends StatefulWidget {
  final PlantSpec spec;
  const AddPlantScreen({super.key, required this.spec});
  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nick = TextEditingController();
  final _every = TextEditingController(text: '7');
  late String _room = widget.spec.isHydro ? 'Sistema hidropónico' : rooms.first;
  int _ago = 0; // días desde el último riego; 99 = no lo sé
  DateTime _planted = today();
  XFile? _photo;

  bool get _custom => widget.spec.id == customSpecId;
  Growth? get _growth => widget.spec.growth;

  @override
  void dispose() {
    _nick.dispose();
    _every.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    final nick = _nick.text.trim();
    if (_custom && nick.isEmpty) {
      toast(context, 'Escribe el nombre de la planta');
      return;
    }
    final waterEvery = _custom ? ((int.tryParse(_every.text) ?? 7).clamp(1, 365)) : (widget.spec.every[CareTask.water] ?? 0);
    final last = <CareTask, DateTime>{};
    if (waterEvery > 0) {
      // "No lo sé" => toca regar hoy
      last[CareTask.water] = addDays(today(), -(_ago == 99 ? waterEvery : _ago));
    }
    final p = Plant(
      id: newId(),
      specId: widget.spec.id,
      nickname: nick.isNotEmpty ? nick : (_custom ? '' : widget.spec.name),
      room: _room,
      photo: _photo == null ? null : await state.storePhoto(await _photo!.readAsBytes()),
      addedAt: DateTime.now(),
      plantedAt: _growth != null ? _planted : null,
      last: last,
      custom: _custom ? {CareTask.water: waterEvery} : {},
    );
    await state.addPlant(p);
    if (!mounted) return;
    toast(context, '🌱 ${p.name} añadida');
    Navigator.of(context).popUntil((r) => r.isFirst);
    openPlant(context, p);
  }

  String _plantedLabel() {
    final d = daysBetween(_planted, today());
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${fmtDate(_planted)} (hace $d días)';
  }

  @override
  Widget build(BuildContext context) {
    final g = _growth;
    final waters = !widget.spec.isHydro && (widget.spec.every[CareTask.water] ?? 0) > 0;
    return LeafPage(
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 40),
        children: [
          const TopBar(title: 'Nueva planta'),
          GestureDetector(
            onTap: () async {
              final src = await pickSource(context);
              if (src == null) return;
              final x = await ImagePicker().pickImage(source: src, maxWidth: 1080, imageQuality: 80);
              if (x != null) setState(() => _photo = x);
            },
            child: Glass(
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: _photo != null
                    ? FutureBuilder(
                        future: _photo!.readAsBytes(),
                        builder: (_, snap) => snap.hasData ? Image.memory(snap.data!, fit: BoxFit.cover) : const SizedBox(),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Emoji(_custom ? '📷' : widget.spec.emoji, size: 60),
                        const SizedBox(height: 6),
                        const Text('Toca para añadir una foto', style: TextStyle(color: C.muted)),
                      ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassField(label: _custom ? 'Nombre de la planta' : 'Apodo (opcional)', controller: _nick, hint: _custom ? 'Ej. Lavanda' : widget.spec.name),
          if (_custom) GlassField(label: '💧 Regar cada (días)', controller: _every, keyboard: TextInputType.number),
          const Padding(padding: EdgeInsets.only(left: 4, bottom: 8), child: Text('¿Dónde está?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ChoiceChips<String>(items: [for (final r in rooms) (r, r)], value: _room, onChanged: (v) => setState(() => _room = v)),
          if (g != null) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('📅 Fecha de inicio (${g.from})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Glass(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _planted,
                  firstDate: addDays(today(), -(365 * 6)),
                  lastDate: today(),
                  helpText: 'Fecha de inicio',
                );
                if (d != null) setState(() => _planted = dayOf(d));
              },
              child: Row(children: [
                const Icon(Icons.event_rounded, color: C.green700),
                const SizedBox(width: 10),
                Expanded(child: Text(_plantedLabel(), style: const TextStyle(fontWeight: FontWeight.w600))),
                const Text('Cambiar', style: TextStyle(color: C.green700, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                '${g.label} esperada: ${fmtDate(addDays(_planted, g.min))} – ${fmtDate(addDays(_planted, g.max))}'
                '${g.max >= 365 ? ' ${addDays(_planted, g.max).year}' : ''}',
                style: const TextStyle(color: C.muted, fontSize: 12),
              ),
            ),
          ],
          if (waters || _custom) ...[
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('¿Cuándo la regaste por última vez?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            ChoiceChips<int>(
              items: const [(0, 'Hoy'), (2, 'Hace 2 días'), (5, 'Hace 5 días'), (10, 'Hace +1 semana'), (99, 'No lo sé')],
              value: _ago,
              onChanged: (v) => setState(() => _ago = v),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text('Así calculamos el próximo riego.', style: TextStyle(color: C.muted, fontSize: 12)),
            ),
          ],
          if (widget.spec.isHydro) ...[
            const SizedBox(height: 18),
            Glass(
              child: Row(children: [
                const Emoji('💧', size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    [
                      'Te recordaremos medir pH y EC cada ${widget.spec.every[CareTask.ph]} días',
                      'rellenar el depósito cada ${widget.spec.every[CareTask.topUp]} días',
                      if ((widget.spec.every[CareTask.nutrients] ?? 0) > 0) 'cambiar la solución cada ${widget.spec.every[CareTask.nutrients]} días',
                    ].join(', ') + (g != null && g.isHarvest ? ' y avisarte cuando toque cosechar.' : '.'),
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          Btn('Guardar en mi jardín', onTap: _save),
        ],
      ),
    );
  }
}
