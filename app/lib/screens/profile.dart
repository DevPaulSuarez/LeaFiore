// ═══ profile.dart · PESTAÑA «PERFIL» ═══
// Nombre, clave de API de Claude, estadísticas, notificaciones, guías,
// volver a ver la intro y borrar todos los datos.

import 'package:flutter/material.dart';

import '../services/notifications.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/sheets.dart';
import '../widgets/ui.dart';
import 'intro.dart';

/// Perfil y ajustes.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _key;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    _name = TextEditingController(text: s.userName);
    _key = TextEditingController(text: s.apiKey);
  }

  @override
  void dispose() {
    _name.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final doneCount = state.plants.fold<int>(0, (n, p) => n + p.history.length);
    final initial = state.userName.isEmpty ? '🌿' : state.userName.characters.first.toUpperCase();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 130),
      children: [
        const TopBar(title: 'Perfil', big: true),
        Glass(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: C.buttonGradient),
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(state.userName.isEmpty ? 'Jardinero/a' : state.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text('Cuidando ${state.plants.length} planta${state.plants.length == 1 ? '' : 's'}', style: const TextStyle(color: C.muted)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _stat('🪴', '${state.plants.length}', 'Plantas'),
          const SizedBox(width: 10),
          _stat('✔️', '$doneCount', 'Cuidados'),
          const SizedBox(width: 10),
          _stat('🔬', '${state.scans.length}', 'Diagnósticos'),
        ]),
        const SectionHead('Ajustes'),
        Glass(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            GlassField(label: 'Tu nombre', controller: _name),
            GlassField(
              label: '🔑 Clave de API de Claude (diagnóstico con IA)',
              controller: _key,
              hint: 'sk-ant-…',
              obscure: true,
              help: 'Se guarda solo en este teléfono. Sin clave, el escáner muestra resultados de ejemplo.',
            ),
            Btn('Guardar', onTap: () {
              state.userName = _name.text.trim();
              state.apiKey = _key.text.trim();
              state.save();
              FocusScope.of(context).unfocus();
              toast(context, 'Ajustes guardados');
            }),
          ]),
        ),
        const SizedBox(height: 12),
        _row('🔔', 'Notificaciones', 'Recordatorios diarios a las 9:00', () async {
          final ok = await Notifications.instance.requestPermission();
          if (context.mounted) toast(context, ok ? '🔔 Recordatorios activados' : 'Activa las notificaciones en Ajustes del teléfono');
        }),
        _row('📗', 'Guías de cuidado', 'Riego, plagas, trasplante…', () => showGuides(context)),
        _row('👋', 'Ver introducción', '', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IntroScreen()))),
        const SizedBox(height: 10),
        Btn('Borrar todos los datos', style: BtnStyle.danger, onTap: () async {
          if (!await confirm(context, '¿Borrar todo?', 'Se borrarán tus plantas, diagnósticos y ajustes.', ok: 'Borrar')) return;
          await state.resetAll();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const IntroScreen()), (_) => false);
        }),
        const SizedBox(height: 16),
        const Center(child: Text('LeaFiore · v1.0', style: TextStyle(color: C.muted, fontSize: 12))),
      ],
    );
  }

  Widget _stat(String i, String n, String l) => Expanded(
        child: Glass(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Emoji(i, size: 20),
            const SizedBox(height: 4),
            Text(n, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(l, style: const TextStyle(color: C.muted, fontSize: 11)),
          ]),
        ),
      );

  Widget _row(String icon, String title, String sub, VoidCallback onTap) => Glass(
        margin: const EdgeInsets.only(bottom: 10),
        onTap: onTap,
        child: Row(children: [
          RoundIcon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: C.muted, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.muted),
        ]),
      );
}
