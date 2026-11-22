import 'package:flutter_test/flutter_test.dart';
import 'package:leafiore/data/library.dart';
import 'package:leafiore/models.dart';
import 'package:leafiore/state/app_state.dart';

void main() {
  Plant plant({int lastDaysAgo = 0, String spec = 'monstera'}) => Plant(
        id: 'p1',
        specId: spec,
        nickname: '',
        room: 'Sala',
        addedAt: DateTime.now(),
        last: {CareTask.water: addDays(today(), -(lastDaysAgo))},
      );

  test('el riego toca según la frecuencia de la planta', () {
    final s = AppState();
    final p = plant(lastDaysAgo: 0);
    expect(s.dueIn(p, CareTask.water), 7); // monstera: cada 7 días
    p.last[CareTask.water] = addDays(today(), -(9));
    expect(s.dueIn(p, CareTask.water), -2);
  });

  test('posponer mueve la fecha y apagar el recordatorio la quita', () {
    final s = AppState();
    final p = plant(lastDaysAgo: 7);
    expect(s.dueIn(p, CareTask.water), 0);
    p.snooze[CareTask.water] = addDays(today(), 2);
    expect(s.dueIn(p, CareTask.water), 2);
    p.remindersOff.add(CareTask.water);
    expect(s.dueIn(p, CareTask.water), isNull);
  });

  test('frecuencia personalizada y tareas que no aplican', () {
    final s = AppState();
    final p = plant(spec: 'orquidea');
    expect(s.dueIn(p, CareTask.rotate), isNull); // orquídea no se gira
    p.custom[CareTask.water] = 3;
    expect(s.dueIn(p, CareTask.water), 3);
  });

  test('la planta se guarda y se lee igual', () {
    final p = plant(lastDaysAgo: 2)
      ..custom[CareTask.mist] = 5
      ..remindersOff.add(CareTask.rotate)
      ..history.add(HistoryEntry(CareTask.water, DateTime(2026, 1, 1)));
    final back = Plant.fromJson(p.toJson());
    expect(back.interval(CareTask.mist), 5);
    expect(back.remindersOff, {CareTask.rotate});
    expect(back.last[CareTask.water], p.last[CareTask.water]);
    expect(back.history.single.task, CareTask.water);
  });

  test('el diagnóstico se lee del JSON de la IA', () {
    final d = Diagnosis.fromJson({
      'is_plant': true, 'plant_guess': 'Potus', 'subject': 'hoja', 'status': 'enferma',
      'problem': 'Araña roja', 'confidence': 140, 'severity': 'grave', 'description': 'x',
      'causes': ['seco'], 'treatment': ['a', 'b'], 'prevention': [], 'water_advice': 'y',
    });
    expect(d.status, HealthStatus.enferma);
    expect(d.confidence, 100);
    expect(d.treatment.length, 2);
  });

  test('cosecha: primera al mínimo, luego se repite; cosecha única termina', () {
    final s = AppState();
    final lechuga = Plant(id: 'l', specId: 'h_lechuga', nickname: '', room: 'x', addedAt: DateTime.now(),
        plantedAt: addDays(today(), -(30)));
    expect(s.dueIn(lechuga, CareTask.harvest), 0); // lechuga: 30–45 días
    expect(s.dueIn(lechuga, CareTask.water), isNull); // hidroponía no se riega
    expect(s.dueIn(lechuga, CareTask.ph), isNotNull);
    lechuga.last[CareTask.harvest] = today();
    expect(s.dueIn(lechuga, CareTask.harvest), 7); // repite cada semana

    final rabano = Plant(id: 'r', specId: 'rabano', nickname: '', room: 'x', addedAt: DateTime.now(),
        plantedAt: addDays(today(), -(10)));
    expect(s.dueIn(rabano, CareTask.harvest), 15);
    rabano.last[CareTask.harvest] = today();
    expect(s.dueIn(rabano, CareTask.harvest), isNull);
    expect(growthProgress(rabano)!.done, isTrue);

    final rosa = Plant(id: 'f', specId: 'rosa', nickname: '', room: 'x', addedAt: DateTime.now());
    expect(s.dueIn(rosa, CareTask.harvest), isNull); // las flores no se "cosechan"
  });

  test('duraciones legibles', () {
    expect(fmtDuration(7, 14), '7–14 días');
    expect(fmtDuration(90, 120), '3–4 meses');
    expect(fmtDuration(730, 1095), '2–3 años');
    expect(fmtDuration(365, 540), '12–18 meses');
  });

  test('todas las plantas tienen datos coherentes', () {
    for (final p in plantLibrary) {
      if (p.growth case final g?) expect(g.min <= g.max, isTrue, reason: p.id);
      if (p.category == PlantCategory.hidroponia) expect(p.hydro, isNotNull, reason: p.id);
    }
    expect(plantLibrary.map((p) => p.id).toSet().length, plantLibrary.length);
  });
}
