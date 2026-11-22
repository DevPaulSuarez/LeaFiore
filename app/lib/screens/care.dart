// ═══ care.dart · PESTAÑA «CUIDADOS» ═══
// Pestañas Hoy / Próximas / Hechas, tira de la semana y lista de tareas.
//   _Week     → la tira de 7 días con puntito si hay tareas.
//   _TaskRow  → fila de una tarea pendiente (tocar = posponer, círculo = completar).
//   _DoneRow  → fila de una tarea ya hecha.
// Las tareas se calculan en state/app_state.dart → allTasks().

import 'package:flutter/material.dart';

import '../data/library.dart';
import '../models.dart';
import '../services/notifications.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';
import 'library.dart';

enum _Tab { today, upcoming, done }

/// Cuidados (imagen 2 derecha) con semana tipo calendario (imagen 3).
class CareScreen extends StatefulWidget {
  const CareScreen({super.key});
  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  _Tab _tab = _Tab.today;
  int _day = 0; // días respecto a hoy

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final tasks = state.allTasks();
    final done = [
      for (final p in state.plants)
        for (final h in p.history) (plant: p, entry: h),
    ]..sort((a, b) => b.entry.at.compareTo(a.entry.at));

    final children = <Widget>[];

    if (_tab == _Tab.today) {
      final items = _day == 0 ? tasks.where((t) => t.due <= 0).toList() : (_day > 0 ? tasks.where((t) => t.due == _day).toList() : <DueTask>[]);
      final dayDate = addDays(today(), _day);
      final doneThatDay = done.where((d) => dayOf(d.entry.at) == dayDate).toList();

      for (final t in CareTask.values) {
        final group = items.where((i) => i.task == t).toList();
        if (group.isEmpty) continue;
        children.add(_GroupTitle('${t.icon} ${t.label}'));
        children.addAll(group.map((d) => _TaskRow(d)));
      }
      if (doneThatDay.isNotEmpty) {
        children.add(const _GroupTitle('✔ Completadas'));
        children.addAll(doneThatDay.map((d) => _DoneRow(d.plant, d.entry)));
      }
      if (items.isEmpty && doneThatDay.isEmpty) children.add(_empty(context, _day));
    } else if (_tab == _Tab.upcoming) {
      final up = tasks.where((t) => t.due > 0 && t.due <= 30).toList();
      children.addAll(up.isEmpty ? [_empty(context, 1)] : up.map((d) => _TaskRow(d)));
    } else {
      children.addAll(done.isEmpty
          ? [
              const Glass(
                padding: EdgeInsets.all(28),
                child: Column(children: [Emoji('📋', size: 56), SizedBox(height: 8), Text('Aún no has completado tareas.', style: TextStyle(color: C.muted))]),
              )
            ]
          : done.take(40).map((d) => _DoneRow(d.plant, d.entry)));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 130),
      children: [
        TopBar(
          title: 'Cuidados',
          big: true,
          trailing: CircleBtn(
            onTap: () async {
              final ok = await Notifications.instance.requestPermission();
              if (context.mounted) toast(context, ok ? '🔔 Recordatorios activados' : 'Activa las notificaciones en Ajustes del teléfono');
            },
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        Segment<_Tab>(
          items: const [(_Tab.today, 'Hoy'), (_Tab.upcoming, 'Próximas'), (_Tab.done, 'Hechas')],
          value: _tab,
          onChanged: (v) => setState(() {
            _tab = v;
            _day = 0;
          }),
        ),
        const SizedBox(height: 16),
        if (_tab == _Tab.today) ...[
          _Week(selected: _day, tasks: tasks, onSelect: (d) => setState(() => _day = d)),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(
              _day == 0 ? '${tasks.where((t) => t.due <= 0).length} tareas pendientes · toca una para posponer' : _longDate(addDays(today(), _day)),
              style: const TextStyle(color: C.muted, fontSize: 13),
            ),
          ),
        ],
        ...children,
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Guía de cuidados', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 6),
                const Text('Aprende a mantener tus plantas felices y sanas.', style: TextStyle(fontSize: 12, color: C.muted)),
                const SizedBox(height: 12),
                Btn('Explorar', small: true, expand: false, style: BtnStyle.ghost, onTap: () => showGuides(context)),
              ]),
            ),
            const Emoji('📗', size: 54),
          ]),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, int off) {
    final state = AppScope.read(context);
    if (state.plants.isEmpty) {
      return Glass(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Emoji('🪴', size: 56),
          const SizedBox(height: 8),
          const Text('Añade plantas para ver sus cuidados.', style: TextStyle(color: C.muted)),
          const SizedBox(height: 14),
          Btn('Añadir planta', expand: false, onTap: () => openLibrary(context)),
        ]),
      );
    }
    return Glass(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Emoji(off < 0 ? '📅' : '✨', size: 56),
        const SizedBox(height: 8),
        Text(off < 0 ? 'Nada registrado ese día.' : 'No hay tareas para este día.', style: const TextStyle(color: C.muted)),
      ]),
    );
  }

  String _longDate(DateTime d) {
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    const days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return '${days[d.weekday - 1]}, ${d.day} de ${months[d.month - 1]}';
  }
}

class _Week extends StatelessWidget {
  final int selected;
  final List<DueTask> tasks;
  final ValueChanged<int> onSelect;
  const _Week({required this.selected, required this.tasks, required this.onSelect});

  @override
  Widget build(BuildContext context) => Glass(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(children: [
          for (var off = -1; off <= 5; off++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(off),
                child: Builder(builder: (_) {
                  final d = addDays(today(), off);
                  final on = off == selected;
                  final has = off > 0 ? tasks.any((t) => t.due == off) : (off == 0 && tasks.any((t) => t.due <= 0));
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: on ? C.green600 : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      Text(weekdays[d.weekday - 1], style: TextStyle(fontSize: 11, color: on ? Colors.white : C.muted)),
                      const SizedBox(height: 4),
                      Text('${d.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: on ? Colors.white : C.ink)),
                      const SizedBox(height: 3),
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: has ? (on ? Colors.white : C.amber) : Colors.transparent, shape: BoxShape.circle)),
                    ]),
                  );
                }),
              ),
            ),
        ]),
      );
}

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.muted, letterSpacing: .6)),
      );
}

class _TaskRow extends StatelessWidget {
  final DueTask t;
  const _TaskRow(this.t);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    return Glass(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => showTaskSheet(context, t.plant, t.task),
      child: Row(children: [
        PlantThumb(t.plant),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t.task.label} ${t.plant.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 3),
            Text('${t.task.icon} ${dueLabel(t.due)} · ${t.plant.room}',
                style: TextStyle(fontSize: 12, color: t.due < 0 ? C.red : (t.due == 0 ? C.green700 : C.muted))),
          ]),
        ),
        if (t.due <= 0)
          GestureDetector(
            onTap: () {
              state.complete(t.plant, t.task);
              toast(context, '${t.task.icon} ${t.task.label}: ${t.plant.name} ✔');
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.green500, width: 2)),
            ),
          ),
      ]),
    );
  }
}

class _DoneRow extends StatelessWidget {
  final Plant plant;
  final HistoryEntry entry;
  const _DoneRow(this.plant, this.entry);

  @override
  Widget build(BuildContext context) => Glass(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          PlantThumb(plant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${entry.task.label} ${plant.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 3),
              Text(fmtDateTime(entry.at), style: const TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: C.green600),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          ),
        ]),
      );
}
