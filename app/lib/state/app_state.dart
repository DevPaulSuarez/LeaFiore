// ═══ app_state.dart · CEREBRO DE LA APP ═══
// Guarda y carga todo (shared_preferences + fotos en el dispositivo) y calcula:
//   dueIn()          → en cuántos días toca una tarea (negativo = atrasada).
//   allTasks()       → todas las tareas pendientes ordenadas.
//   complete/snooze  → completar o posponer una tarea.
//   health()         → estado que se muestra en cada planta (sana, sed, plaga…).
//   growthProgress() → % de avance hasta la cosecha/floración.
//   addDays/daysBetween → cálculo de fechas por días (evita errores de horario de verano).
// AppScope.of(context) da acceso al estado desde cualquier pantalla.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/library.dart';
import '../models.dart';
import '../services/notifications.dart';

/// Progreso hacia el hito de crecimiento (cosecha/floración).
({double pct, int elapsed, int left, bool ready, bool done})? growthProgress(Plant p) {
  final g = p.spec.growth;
  if (g == null) return null;
  final elapsed = daysBetween(p.startedAt, today());
  final done = g.isHarvest && g.repeat == 0 && p.last[CareTask.harvest] != null;
  return (
    pct: (elapsed / g.min).clamp(0.0, 1.0),
    elapsed: elapsed,
    left: g.min - elapsed,
    ready: elapsed >= g.min,
    done: done,
  );
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime today() => dayOf(DateTime.now());
/// Días de calendario entre dos fechas (inmune a cambios de horario de verano).
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Suma días de calendario (no horas), para no desfasarse con el horario de verano.
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

String newId() {
  final r = Random();
  return List.generate(10, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[r.nextInt(36)]).join();
}

/// Estado global de la app, guardado en el dispositivo.
class AppState extends ChangeNotifier {
  static const _key = 'leafiore:v1';

  late SharedPreferences _prefs;
  late Directory docsDir;

  bool onboarded = false;
  String userName = '';
  String apiKey = '';
  List<Plant> plants = [];
  List<Scan> scans = [];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    docsDir = await getApplicationDocumentsDirectory();
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        onboarded = j['onboarded'] ?? false;
        userName = j['userName'] ?? '';
        apiKey = j['apiKey'] ?? '';
        plants = ((j['plants'] as List?) ?? []).map((e) => Plant.fromJson(Map<String, dynamic>.from(e))).toList();
        scans = ((j['scans'] as List?) ?? []).map((e) => Scan.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        debugPrint('No se pudo leer el estado guardado: $e');
      }
    }
  }

  Future<void> save() async {
    notifyListeners();
    await _prefs.setString(
      _key,
      jsonEncode({
        'onboarded': onboarded,
        'userName': userName,
        'apiKey': apiKey,
        'plants': plants.map((p) => p.toJson()).toList(),
        'scans': scans.map((s) => s.toJson()).toList(),
      }),
    );
    Notifications.instance.reschedule(this);
  }

  // ---------- fotos ----------
  File photoFile(String name) => File('${docsDir.path}/$name');

  Future<String> storePhoto(List<int> bytes) async {
    final name = 'foto_${DateTime.now().millisecondsSinceEpoch}_${newId()}.jpg';
    await photoFile(name).writeAsBytes(bytes);
    return name;
  }

  Future<void> _deletePhoto(String? name) async {
    if (name == null) return;
    final f = photoFile(name);
    if (await f.exists()) await f.delete();
  }

  // ---------- plantas ----------
  Plant? plantById(String? id) {
    for (final p in plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> addPlant(Plant p) async {
    plants.add(p);
    await save();
  }

  Future<void> deletePlant(Plant p) async {
    plants.remove(p);
    await _deletePhoto(p.photo);
    for (final s in scans.where((s) => s.plantId == p.id).toList()) {
      await _deletePhoto(s.photo);
      scans.remove(s);
    }
    await save();
  }

  // ---------- cuidados ----------
  /// Días hasta la próxima vez (negativo = atrasado). null = no aplica.
  int? dueIn(Plant p, CareTask t) {
    if (t == CareTask.check) {
      return p.followUp == null ? null : daysBetween(today(), p.followUp!);
    }
    if (t == CareTask.harvest) {
      final g = p.spec.growth;
      if (g == null || !g.isHarvest || p.remindersOff.contains(t)) return null;
      final lastH = p.last[t];
      DateTime due;
      if (lastH == null) {
        due = addDays(dayOf(p.startedAt), g.min);
      } else if (g.repeat > 0) {
        due = addDays(dayOf(lastH), g.repeat);
      } else {
        return null; // cosecha única ya hecha
      }
      final sn = p.snooze[t];
      if (sn != null && sn.isAfter(due)) due = sn;
      return daysBetween(today(), due);
    }
    final every = p.interval(t);
    if (every <= 0 || p.remindersOff.contains(t)) return null;
    var due = addDays(dayOf(p.last[t] ?? p.addedAt), every);
    final sn = p.snooze[t];
    if (sn != null && sn.isAfter(due)) due = sn;
    return daysBetween(today(), due);
  }

  List<DueTask> allTasks() {
    final out = <DueTask>[];
    for (final p in plants) {
      for (final t in CareTask.values) {
        final d = dueIn(p, t);
        if (d != null) out.add(DueTask(p, t, d));
      }
    }
    out.sort((a, b) => a.due != b.due ? a.due.compareTo(b.due) : a.task.index.compareTo(b.task.index));
    return out;
  }

  Future<void> complete(Plant p, CareTask t) async {
    if (t == CareTask.check) {
      p.followUp = null;
    } else {
      p.last[t] = DateTime.now();
    }
    p.snooze.remove(t);
    p.history.insert(0, HistoryEntry(t, DateTime.now()));
    if (p.history.length > 200) p.history = p.history.sublist(0, 200);
    await save();
  }

  Future<void> snooze(Plant p, CareTask t, int days) async {
    final when = addDays(today(), days);
    if (t == CareTask.check) {
      p.followUp = when;
    } else {
      p.snooze[t] = when;
    }
    await save();
  }

  Scan? lastScan(Plant p) {
    for (final s in scans) {
      if (s.plantId == p.id) return s;
    }
    return null;
  }

  /// Estado de salud que se muestra en tarjetas.
  ({HealthStatus level, String text}) health(Plant p) {
    final s = lastScan(p);
    if (s != null && s.result.status != HealthStatus.sana) {
      return (level: s.result.status, text: s.result.problem);
    }
    final w = dueIn(p, CareTask.water) ?? dueIn(p, CareTask.topUp);
    if (w != null && w < 0) return (level: HealthStatus.atencion, text: p.spec.isHydro ? 'Rellenar depósito' : 'Necesita agua');
    final h = dueIn(p, CareTask.harvest);
    if (h != null && h <= 0) return (level: HealthStatus.sana, text: '🧺 Lista para cosechar');
    return (level: HealthStatus.sana, text: 'Saludable');
  }

  // ---------- diagnósticos ----------
  Future<void> addScan(Scan s) async {
    scans.insert(0, s);
    await save();
  }

  Future<void> deleteScan(Scan s) async {
    scans.remove(s);
    await _deletePhoto(s.photo);
    await save();
  }

  Future<void> resetAll() async {
    for (final p in plants) {
      await _deletePhoto(p.photo);
    }
    for (final s in scans) {
      await _deletePhoto(s.photo);
    }
    onboarded = false;
    userName = '';
    apiKey = '';
    plants = [];
    scans = [];
    await save();
  }
}

/// Da acceso al [AppState] desde cualquier widget y lo reconstruye al cambiar.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

String dueLabel(int d) {
  if (d < -1) return 'Atrasado ${-d} días';
  if (d == -1) return 'Atrasado desde ayer';
  if (d == 0) return 'Hoy';
  if (d == 1) return 'Mañana';
  return 'En $d días';
}
