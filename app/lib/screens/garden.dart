import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'home.dart';
import 'library.dart';
import 'plant_detail.dart';

/// Mi jardín (imagen 3): plantas en cuadrícula o agrupadas por lugar.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  bool _byRoom = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final plants = state.plants;
    final roomsUsed = {for (final p in plants) p.room}.toList();

    return Stack(children: [
      CustomScrollView(slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 0),
          sliver: SliverList.list(children: [
            TopBar(
              title: 'Mi jardín',
              big: true,
              trailing: CircleBtn(onTap: () => openLibrary(context), child: const Icon(Icons.add_rounded)),
            ),
            Segment<bool>(
              items: const [(false, 'Plantas'), (true, 'Lugares')],
              value: _byRoom,
              onChanged: (v) => setState(() => _byRoom = v),
            ),
            const SizedBox(height: 16),
            if (plants.isEmpty)
              Glass(
                padding: const EdgeInsets.all(28),
                child: Column(children: [
                  const Emoji('🌱', size: 56),
                  const SizedBox(height: 8),
                  const Text('Aún no tienes plantas.', style: TextStyle(color: C.muted)),
                  const SizedBox(height: 14),
                  Btn('Explorar biblioteca', expand: false, onTap: () => openLibrary(context)),
                ]),
              ),
          ]),
        ),
        if (plants.isNotEmpty && !_byRoom)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .54,
              ),
              itemCount: plants.length,
              itemBuilder: (_, i) => PlantCard(plants[i], showCare: true),
            ),
          ),
        if (plants.isNotEmpty && _byRoom)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
            sliver: SliverList.list(children: [
              for (final r in roomsUsed)
                Builder(builder: (context) {
                  final ps = plants.where((p) => p.room == r).toList();
                  return Glass(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(r, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                        Text('${ps.length} planta${ps.length > 1 ? 's' : ''}', style: const TextStyle(color: C.muted, fontSize: 13)),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final p in ps)
                          GestureDetector(
                            onTap: () => openPlant(context, p),
                            child: Column(children: [
                              PlantThumb(p, size: 60),
                              const SizedBox(height: 4),
                              SizedBox(width: 64, child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                            ]),
                          ),
                      ]),
                    ]),
                  );
                }),
            ]),
          ),
      ]),
      if (plants.isNotEmpty)
        Positioned(
          right: 22,
          bottom: MediaQuery.of(context).padding.bottom + 104,
          child: FloatingActionButton(
            heroTag: 'add-plant',
            backgroundColor: C.green600,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: () => openLibrary(context),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
    ]);
  }
}
