import 'data/library.dart';

class HistoryEntry {
  final CareTask task;
  final DateTime at;
  HistoryEntry(this.task, this.at);

  Map<String, dynamic> toJson() => {'task': task.name, 'at': at.millisecondsSinceEpoch};
  factory HistoryEntry.fromJson(Map<String, dynamic> j) =>
      HistoryEntry(CareTask.values.asNameMap()[j['task']] ?? CareTask.water, DateTime.fromMillisecondsSinceEpoch(j['at']));
}

class Plant {
  final String id;
  String specId;
  String nickname;
  String room;
  String? photo; // nombre de archivo dentro de la carpeta de documentos
  DateTime addedAt;
  DateTime? plantedAt; // siembra / plantación / esqueje
  Map<CareTask, DateTime> last;
  Map<CareTask, DateTime> snooze;
  Map<CareTask, int> custom; // frecuencias personalizadas
  Set<CareTask> remindersOff;
  DateTime? followUp;
  List<HistoryEntry> history;

  Plant({
    required this.id,
    required this.specId,
    required this.nickname,
    required this.room,
    this.photo,
    required this.addedAt,
    this.plantedAt,
    Map<CareTask, DateTime>? last,
    Map<CareTask, DateTime>? snooze,
    Map<CareTask, int>? custom,
    Set<CareTask>? remindersOff,
    this.followUp,
    List<HistoryEntry>? history,
  })  : last = last ?? {},
        snooze = snooze ?? {},
        custom = custom ?? {},
        remindersOff = remindersOff ?? {},
        history = history ?? [];

  PlantSpec get spec => specId == customSpecId
      ? customBase
      : plantLibrary.firstWhere((s) => s.id == specId, orElse: () => customBase);

  String get name => nickname.isNotEmpty ? nickname : spec.name;

  DateTime get startedAt => plantedAt ?? addedAt;

  int interval(CareTask t) => custom[t] ?? spec.every[t] ?? 0;

  static Map<String, int> _dates(Map<CareTask, DateTime> m) =>
      m.map((k, v) => MapEntry(k.name, v.millisecondsSinceEpoch));
  static Map<CareTask, DateTime> _readDates(Map? m) => (m ?? {}).map(
      (k, v) => MapEntry(CareTask.values.byName(k), DateTime.fromMillisecondsSinceEpoch(v as int)));

  Map<String, dynamic> toJson() => {
        'id': id,
        'specId': specId,
        'nickname': nickname,
        'room': room,
        'photo': photo,
        'addedAt': addedAt.millisecondsSinceEpoch,
        'plantedAt': plantedAt?.millisecondsSinceEpoch,
        'last': _dates(last),
        'snooze': _dates(snooze),
        'custom': custom.map((k, v) => MapEntry(k.name, v)),
        'remindersOff': remindersOff.map((e) => e.name).toList(),
        'followUp': followUp?.millisecondsSinceEpoch,
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
        id: j['id'],
        specId: j['specId'],
        nickname: j['nickname'] ?? '',
        room: j['room'] ?? rooms.first,
        photo: j['photo'],
        addedAt: DateTime.fromMillisecondsSinceEpoch(j['addedAt']),
        plantedAt: j['plantedAt'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['plantedAt']),
        last: _readDates(j['last']),
        snooze: _readDates(j['snooze']),
        custom: (j['custom'] as Map? ?? {}).map((k, v) => MapEntry(CareTask.values.byName(k), v as int)),
        remindersOff: ((j['remindersOff'] as List?) ?? []).map((e) => CareTask.values.byName(e)).toSet(),
        followUp: j['followUp'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['followUp']),
        history: ((j['history'] as List?) ?? []).map((e) => HistoryEntry.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

enum HealthStatus { sana, atencion, enferma }

class Diagnosis {
  final bool isPlant;
  final String plantGuess;
  final HealthStatus status;
  final String problem;
  final int confidence;
  final String severity;
  final String description;
  final List<String> causes;
  final List<String> treatment;
  final List<String> prevention;
  final String waterAdvice;

  const Diagnosis({
    required this.isPlant,
    required this.plantGuess,
    required this.status,
    required this.problem,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.causes,
    required this.treatment,
    required this.prevention,
    required this.waterAdvice,
  });

  static List<String> _list(dynamic v) => ((v as List?) ?? []).map((e) => e.toString()).toList();

  factory Diagnosis.fromJson(Map<String, dynamic> j) => Diagnosis(
        isPlant: j['is_plant'] ?? true,
        plantGuess: j['plant_guess'] ?? 'Desconocida',
        status: HealthStatus.values.asNameMap()[j['status']] ?? HealthStatus.atencion,
        problem: j['problem'] ?? '',
        confidence: (j['confidence'] as num? ?? 0).toInt().clamp(0, 100),
        severity: j['severity'] ?? 'leve',
        description: j['description'] ?? '',
        causes: _list(j['causes']),
        treatment: _list(j['treatment']),
        prevention: _list(j['prevention']),
        waterAdvice: j['water_advice'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'is_plant': isPlant,
        'plant_guess': plantGuess,
        'status': status.name,
        'problem': problem,
        'confidence': confidence,
        'severity': severity,
        'description': description,
        'causes': causes,
        'treatment': treatment,
        'prevention': prevention,
        'water_advice': waterAdvice,
      };
}

enum ScanMode {
  planta('Planta', '🪴', 'Encuadra la planta completa con buena luz'),
  hoja('Hoja', '🍃', 'Acércate a la hoja afectada (anverso o envés)'),
  insecto('Insecto', '🐞', 'Enfoca el insecto lo más cerca posible');

  const ScanMode(this.label, this.icon, this.hint);
  final String label, icon, hint;
}

class Scan {
  final String id;
  final DateTime at;
  String? plantId;
  final ScanMode mode;
  final String photo; // nombre de archivo
  final Diagnosis result;
  final bool demo;

  Scan({
    required this.id,
    required this.at,
    required this.plantId,
    required this.mode,
    required this.photo,
    required this.result,
    required this.demo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.millisecondsSinceEpoch,
        'plantId': plantId,
        'mode': mode.name,
        'photo': photo,
        'result': result.toJson(),
        'demo': demo,
      };

  factory Scan.fromJson(Map<String, dynamic> j) => Scan(
        id: j['id'],
        at: DateTime.fromMillisecondsSinceEpoch(j['at']),
        plantId: j['plantId'],
        mode: ScanMode.values.byName(j['mode']),
        photo: j['photo'],
        result: Diagnosis.fromJson(Map<String, dynamic>.from(j['result'])),
        demo: j['demo'] ?? false,
      );
}

/// Una tarea pendiente: [due] = días hasta que toca (negativo = atrasada).
class DueTask {
  final Plant plant;
  final CareTask task;
  final int due;
  DueTask(this.plant, this.task, this.due);
}
