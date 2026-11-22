import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leafiore/data/library.dart';
import 'package:leafiore/models.dart';
import 'package:leafiore/screens/care.dart';
import 'package:leafiore/screens/garden.dart';
import 'package:leafiore/screens/home.dart';
import 'package:leafiore/screens/intro.dart';
import 'package:leafiore/screens/library.dart';
import 'package:leafiore/screens/plant_detail.dart';
import 'package:leafiore/screens/profile.dart';
import 'package:leafiore/screens/scan.dart';
import 'package:leafiore/screens/shell.dart';
import 'package:leafiore/screens/timeline.dart';
import 'package:leafiore/state/app_state.dart';
import 'package:leafiore/widgets/ui.dart';

/// Dibuja cada pantalla en tamaño de teléfono para detectar errores de diseño
/// (desbordes, excepciones). Con --update-goldens guarda capturas en test/goldens.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  AppState demoState() {
    final s = AppState()
      ..onboarded = true
      ..userName = 'Paul';
    Plant mk(String id, String spec, String room, int ago) => Plant(
          id: id,
          specId: spec,
          nickname: '',
          room: room,
          addedAt: addDays(DateTime.now(), -(30)),
          last: {CareTask.water: addDays(today(), -(ago))},
        );
    s.plants = [mk('h', 'h_lechuga', 'Sistema hidropónico', 0)..plantedAt = addDays(today(), -(26)), mk('a', 'monstera', 'Sala', 8), mk('b', 'sansevieria', 'Dormitorio', 3), mk('c', 'espatifilo', 'Baño', 4), mk('d', 'orquidea', 'Sala', 1)];
    s.plants.first.history.add(HistoryEntry(CareTask.water, addDays(DateTime.now(), -(8))));
    return s;
  }

  Future<void> show(WidgetTester t, Widget screen, String name, {AppState? state}) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final s = state ?? demoState();
    await t.pumpWidget(AppScope(
      state: s,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: LeafBackground(child: screen)),
      ),
    ));
    await t.pump(const Duration(milliseconds: 400));
    final error = t.takeException();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    if (error is FlutterError) debugPrint(error.toStringDeep());
    expect(error, isNull, reason: 'Error de diseño en $name');
  }

  testWidgets('intro', (t) async => show(t, const IntroScreen(), '01_intro', state: AppState()));
  testWidgets('inicio', (t) async => show(t, const HomeScreen(), '02_inicio'));
  testWidgets('inicio vacío', (t) async => show(t, const HomeScreen(), '03_inicio_vacio', state: AppState()..onboarded = true));
  testWidgets('jardín', (t) async => show(t, const GardenScreen(), '04_jardin'));
  testWidgets('cuidados', (t) async => show(t, const CareScreen(), '05_cuidados'));
  testWidgets('perfil', (t) async => show(t, const ProfileScreen(), '06_perfil'));
  testWidgets('biblioteca', (t) async => show(t, const LibraryScreen(), '07_biblioteca'));
  testWidgets('ficha', (t) async => show(t, const PlantDetailScreen(plantId: 'a'), '08_ficha'));
  testWidgets('escáner', (t) async => show(t, const ScanScreen(plantId: 'a'), '09_escaner'));
  testWidgets('añadir', (t) async => show(t, AddPlantScreen(spec: plantLibrary.first), '10_anadir'));
  testWidgets('tiempos', (t) async => show(t, const TimelineScreen(), '12_tiempos'));
  testWidgets('ficha hidroponía', (t) async => show(t, const PlantDetailScreen(plantId: 'h'), '13_ficha_hidro'));
  testWidgets('añadir hidroponía', (t) async => show(t, AddPlantScreen(spec: plantLibrary.firstWhere((p) => p.id == 'h_fresa')), '14_anadir_hidro'));
  testWidgets('shell', (t) async => show(t, const Shell(), '11_shell'));
}
