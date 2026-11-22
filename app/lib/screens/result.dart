import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'shell.dart';

void openResult(BuildContext context, Scan s) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(scanId: s.id)));
}

/// Resultado del diagnóstico: problema, gravedad, tratamiento y prevención.
class ResultScreen extends StatelessWidget {
  final String scanId;
  const ResultScreen({super.key, required this.scanId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.scans.where((x) => x.id == scanId).firstOrNull;
    if (s == null) return const LeafPage(child: SizedBox());
    final r = s.result;
    final plant = state.plantById(s.plantId);
    final top = MediaQuery.of(context).padding.top;
    const sev = {'ninguna': 'Ninguna', 'leve': 'Leve', 'moderada': 'Moderada', 'grave': 'Grave'};
    final icon = switch (r.status) {
      HealthStatus.sana => '✅',
      HealthStatus.atencion => '👀',
      HealthStatus.enferma => '⚠️',
    };

    return LeafPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          SizedBox(
            height: 280 + top,
            child: Stack(fit: StackFit.expand, children: [
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, .6, 1],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.file(state.photoFile(s.photo), fit: BoxFit.cover),
              ),
              Positioned(
                top: top + 12,
                left: 20,
                right: 20,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  CircleBtn(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_rounded)),
                  CircleBtn(
                    onTap: () async {
                      if (!await confirm(context, '¿Eliminar este diagnóstico?', 'Se borrará la foto y el resultado.')) return;
                      await state.deleteScan(s);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Icon(Icons.delete_outline_rounded),
                  ),
                ]),
              ),
            ]),
          ),
          Transform.translate(
            offset: const Offset(0, -60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Glass(
                  alpha: .7,
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 8, children: [
                      Pill('$icon ${statusText(r.status)}', kind: pillFor(r.status)),
                      if (s.demo) const Pill('Demo'),
                    ]),
                    const SizedBox(height: 10),
                    Text(r.problem, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${r.plantGuess}${plant != null ? ' · ${plant.name}' : ''} · ${fmtDate(s.at)}', style: const TextStyle(color: C.muted)),
                    if (!r.isPlant) ...[
                      const SizedBox(height: 10),
                      const Pill('No parece una planta. Prueba con otra foto.', kind: PillKind.warn),
                    ],
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Confianza ${r.confidence}%', style: const TextStyle(color: C.muted, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: r.confidence / 100,
                              minHeight: 8,
                              color: C.green600,
                              backgroundColor: Colors.white.withValues(alpha: .6),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 18),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Gravedad', style: TextStyle(color: C.muted, fontSize: 13)),
                        Text(sev[r.severity] ?? r.severity, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                    const SizedBox(height: 14),
                    Text(r.description, style: const TextStyle(fontSize: 14, height: 1.6)),
                  ]),
                ),
                if (r.treatment.isNotEmpty)
                  _Block('🩺 Qué hacer', Column(children: [
                    for (var i = 0; i < r.treatment.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: C.green600,
                            child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(r.treatment[i], style: const TextStyle(fontSize: 14, height: 1.45))),
                        ]),
                      ),
                  ])),
                if (r.causes.isNotEmpty) _Block('🔎 Posibles causas', _bullets(r.causes)),
                _Block('💧 Riego recomendado', Text(r.waterAdvice, style: const TextStyle(color: C.muted, height: 1.6))),
                if (r.prevention.isNotEmpty) _Block('🛡️ Prevención', _bullets(r.prevention)),
                const SizedBox(height: 16),
                if (plant == null && state.plants.isNotEmpty) ...[
                  Btn('🪴  Guardar en una de mis plantas', style: BtnStyle.ghost, onTap: () => _assign(context, s)),
                  const SizedBox(height: 10),
                ],
                if (plant != null && r.status != HealthStatus.sana) ...[
                  Btn('🔔  Recordarme revisar en 7 días', onTap: () {
                    plant.followUp = addDays(today(), 7);
                    state.save();
                    toast(context, 'Te recordaremos revisar el tratamiento');
                  }),
                  const SizedBox(height: 10),
                ],
                Btn('📷  Nuevo diagnóstico', style: BtnStyle.ghost, onTap: () {
                  Navigator.pop(context);
                  openScan(context, plantId: s.plantId);
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullets(List<String> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final t in items)
          Padding(padding: const EdgeInsets.only(bottom: 5), child: Text('•  $t', style: const TextStyle(color: C.muted, fontSize: 14, height: 1.5))),
      ]);

  void _assign(BuildContext context, Scan s) {
    final state = AppScope.read(context);
    showGlassSheet(context, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('¿De qué planta es?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          for (final p in state.plants)
            Glass(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () {
                s.plantId = p.id;
                state.save();
                Navigator.pop(ctx);
                toast(context, 'Guardado en el historial de ${p.name}');
              },
              child: Row(children: [
                PlantThumb(p),
                const SizedBox(width: 14),
                Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(p.room, style: const TextStyle(color: C.muted, fontSize: 12)),
              ]),
            ),
        ]));
  }
}

class _Block extends StatelessWidget {
  final String title;
  final Widget child;
  const _Block(this.title, this.child);

  @override
  Widget build(BuildContext context) => Glass(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          child,
        ]),
      );
}
