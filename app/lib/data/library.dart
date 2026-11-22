// ═══ library.dart · DATOS DE LAS PLANTAS ═══
// Aquí está TODA la información de las plantas. Para añadir una, copia un
// PlantSpec(...) de la lista plantLibrary y cambia sus valores.
//   PlantCategory → categorías (interior, hidroponía, huerto, suculenta, flor).
//   CareTask      → tipos de tarea con su nombre e icono.
//   Growth        → tiempo de cosecha/floración (min–max días, repetición).
//   Hydro         → pH, EC y sistema para hidroponía.
//   rooms         → lugares que se pueden elegir.   articles → guías de cuidado.
/// Biblioteca de plantas con sus cuidados, tiempos de cosecha/floración
/// y datos de hidroponía. Las frecuencias están en días (0 = no aplica).
/// Los tiempos son orientativos: dependen de la variedad, la luz y la temperatura.
library;

// ✏️ MODIFICAR: categorías (nombre y emoji de respaldo).
// La imagen de cada categoría está en assets/categorias/<nombre>.png
// (p. ej. assets/categorias/flor.png). Reemplázala por otra PNG con el mismo nombre.
enum PlantCategory {
  interior('Interior', '🪴'),
  hidroponia('Hidroponía', '💧'),
  huerto('Huerto', '🥕'),
  suculenta('Suculentas', '🌵'),
  flor('Flores', '🌸');

  const PlantCategory(this.label, this.icon);
  final String label, icon;

  /// Imagen 3D de la categoría.
  String get image => 'assets/categorias/$name.png';
}

/// Hito de crecimiento: cosecha, floración o planta formada.
class Growth {
  final String label; // 'Cosecha', 'Floración', 'Planta formada'…
  final String from; // 'desde siembra', 'desde esqueje'…
  final int min, max; // días
  final int repeat; // días entre cosechas/floraciones siguientes (0 = una sola vez)
  final String? repeatNote;

  const Growth(this.label, this.from, this.min, this.max, {this.repeat = 0, this.repeatNote});

  bool get isHarvest => label == 'Cosecha';
  int get avg => (min + max) ~/ 2;
}

/// Datos para cultivo hidropónico.
class Hydro {
  final String ph, ec, system;
  const Hydro(this.ph, this.ec, this.system);
}

class PlantSpec {
  final String id;
  final String name;
  final String sci;
  final String emoji;
  final PlantCategory category;
  final List<String> tags;
  final bool toxic;
  final Map<CareTask, int> every;
  final String light;
  final String temp;
  final String humidity;
  final String about;
  final List<String> tips;
  final Growth? growth;
  final Hydro? hydro;

  const PlantSpec({
    required this.id,
    required this.name,
    required this.sci,
    required this.emoji,
    required this.category,
    required this.tags,
    required this.toxic,
    required this.every,
    required this.light,
    required this.temp,
    required this.humidity,
    required this.about,
    required this.tips,
    this.growth,
    this.hydro,
  });

  bool get isHydro => hydro != null;
}

// ✏️ MODIFICAR: nombre e icono de cada tipo de tarea.
enum CareTask {
  water('Regar', '💧'),
  harvest('Cosechar', '🧺'),
  check('Revisar tratamiento', '🔍'),
  topUp('Rellenar depósito', '🚰'),
  ph('Medir pH y EC', '⚗️'),
  nutrients('Cambiar solución', '🧴'),
  fertilize('Abonar', '🧪'),
  mist('Pulverizar', '💦'),
  rotate('Girar', '🔄'),
  repot('Trasplantar', '🪴');

  const CareTask(this.label, this.icon);
  final String label;
  final String icon;

  /// Tareas con frecuencia configurable (no incluye revisar ni cosechar).
  static const periodic = [water, topUp, ph, nutrients, fertilize, mist, rotate, repot];
}

Map<CareTask, int> _care({
  int water = 0,
  int fert = 0,
  int mist = 0,
  int rotate = 0,
  int repot = 0,
  int ph = 0,
  int nutrients = 0,
  int topUp = 0,
}) =>
    {
      CareTask.water: water,
      CareTask.fertilize: fert,
      CareTask.mist: mist,
      CareTask.rotate: rotate,
      CareTask.repot: repot,
      CareTask.ph: ph,
      CareTask.nutrients: nutrients,
      CareTask.topUp: topUp,
    };

/// Cuidados típicos de un sistema hidropónico.
// ✏️ MODIFICAR: cuidados por defecto de hidroponía (pH cada 3 días, solución cada 14, rellenar cada 3).
final _hydroCare = _care(ph: 3, nutrients: 14, topUp: 3);

/// "21–30 días", "3–4 meses", "2–3 años".
String fmtDuration(int min, int max) {
  String num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');
  if (max < 60) return min == max ? '$min días' : '$min–$max días';
  if (max < 730) {
    final a = (min / 30).round(), b = (max / 30).round();
    return a == b ? '$a meses' : '$a–$b meses';
  }
  final a = (min / 182.5).round() / 2, b = (max / 182.5).round() / 2;
  return a == b ? '${num(a)} años' : '${num(a)}–${num(b)} años';
}

const customSpecId = 'custom';

// ✏️ MODIFICAR: valores de una planta «personalizada» (no está en la biblioteca).
final PlantSpec customBase = PlantSpec(
  id: customSpecId,
  name: 'Mi planta',
  sci: '',
  emoji: '🌱',
  category: PlantCategory.interior,
  tags: const ['Personalizada'],
  toxic: false,
  every: _care(water: 7, fert: 30, rotate: 14, repot: 365),
  light: 'Indirecta',
  temp: '16–26 °C',
  humidity: '40–60 %',
  about: 'Planta añadida manualmente. Ajusta la frecuencia de cuidados a su medida.',
  tips: const [
    'Comprueba la humedad del sustrato con el dedo antes de regar.',
    'Haz un diagnóstico con foto si notas algo raro.',
  ],
);

// ✏️ MODIFICAR: lista de plantas. Copia un PlantSpec(...) para añadir una nueva.
final List<PlantSpec> plantLibrary = [
  // ===================== INTERIOR =====================
  PlantSpec(
    id: 'monstera', name: 'Monstera', sci: 'Monstera deliciosa', emoji: '🌿', category: PlantCategory.interior,
    tags: const ['Fácil', 'Luz difusa', 'Riego medio'], toxic: true,
    every: _care(water: 7, fert: 30, mist: 3, rotate: 14, repot: 540),
    light: 'Brillante indirecta', temp: '18–27 °C', humidity: '60–80 %',
    about: 'Nativa de los bosques tropicales de México. Sus hojas grandes y perforadas la hacen ideal para interiores luminosos.',
    tips: const [
      'Riega cuando los 3–5 cm superiores del sustrato estén secos.',
      'Limpia las hojas con un paño húmedo para que hagan mejor la fotosíntesis.',
      'Dale un tutor de fibra de coco para que trepe.',
      'Hojas amarillas suelen indicar exceso de riego.',
    ],
  ),
  PlantSpec(
    id: 'sansevieria', name: 'Lengua de suegra', sci: 'Sansevieria trifasciata', emoji: '🪴', category: PlantCategory.interior,
    tags: const ['Muy fácil', 'Poca luz', 'Riego bajo'], toxic: true,
    every: _care(water: 18, fert: 60, rotate: 30, repot: 730),
    light: 'Baja a brillante', temp: '15–29 °C', humidity: '30–50 %',
    about: 'Resistente y purificadora del aire. Tolera el olvido mejor que casi cualquier planta.',
    tips: const ['Deja secar el sustrato por completo entre riegos.', 'En invierno riega una vez al mes.', 'Evita mojar el centro de la roseta: se pudre.'],
  ),
  PlantSpec(
    id: 'potus', name: 'Potus', sci: 'Epipremnum aureum', emoji: '🍃', category: PlantCategory.interior,
    tags: const ['Fácil', 'Luz difusa', 'Colgante'], toxic: true,
    every: _care(water: 7, fert: 30, mist: 4, rotate: 14, repot: 365),
    light: 'Media indirecta', temp: '17–29 °C', humidity: '40–60 %',
    about: 'Planta trepadora o colgante de crecimiento rápido, perfecta para principiantes. También crece solo en agua.',
    tips: const ['Si las hojas se caen lacias, necesita agua.', 'Poda los tallos largos para que se vea más frondoso.', 'Los esquejes enraízan fácil en agua.'],
  ),
  PlantSpec(
    id: 'espatifilo', name: 'Cuna de Moisés', sci: 'Spathiphyllum wallisii', emoji: '🌱', category: PlantCategory.interior,
    tags: const ['Media', 'Sombra', 'Riego alto'], toxic: true,
    every: _care(water: 4, fert: 45, mist: 2, rotate: 14, repot: 540),
    light: 'Media a baja', temp: '18–26 °C', humidity: '50–70 %',
    about: 'Florece con espatas blancas. Avisa cuando tiene sed dejando caer sus hojas.',
    tips: const ['Mantén el sustrato ligeramente húmedo, nunca encharcado.', 'Puntas marrones: agua con mucho cloro o ambiente seco.', 'Retira las flores marchitas desde la base.'],
  ),
  PlantSpec(
    id: 'ficus', name: 'Ficus lyrata', sci: 'Ficus lyrata', emoji: '🌳', category: PlantCategory.interior,
    tags: const ['Media', 'Mucha luz', 'Riego medio'], toxic: true,
    every: _care(water: 8, fert: 30, rotate: 7, repot: 540),
    light: 'Brillante, algo de sol', temp: '16–27 °C', humidity: '40–60 %',
    about: 'Árbol de interior con hojas en forma de violín. No le gustan los cambios de lugar.',
    tips: const ['Gírala un cuarto de vuelta cada semana para que crezca recta.', 'Evita corrientes de aire frío.', 'Manchas marrones en el centro de la hoja = exceso de agua.'],
  ),
  PlantSpec(
    id: 'calathea', name: 'Calathea', sci: 'Goeppertia orbifolia', emoji: '🍀', category: PlantCategory.interior,
    tags: const ['Difícil', 'Sombra', 'Humedad alta'], toxic: false,
    every: _care(water: 5, fert: 30, mist: 1, rotate: 14, repot: 365),
    light: 'Media indirecta', temp: '18–24 °C', humidity: '60–80 %',
    about: 'Sus hojas se mueven de día y de noche. Necesita humedad alta y agua sin cal.',
    tips: const ['Usa agua de lluvia o reposada 24 h.', 'Bordes secos = falta de humedad ambiental.', 'Agrúpala con otras plantas o usa una bandeja con piedras y agua.'],
  ),
  PlantSpec(
    id: 'helecho', name: 'Helecho de Boston', sci: 'Nephrolepis exaltata', emoji: '🌾', category: PlantCategory.interior,
    tags: const ['Media', 'Sombra', 'Humedad alta'], toxic: false,
    every: _care(water: 3, fert: 30, mist: 1, rotate: 14, repot: 365),
    light: 'Indirecta', temp: '16–24 °C', humidity: '60–80 %',
    about: 'Frondoso y elegante, ideal para baños luminosos.',
    tips: const ['Nunca dejes que el sustrato se seque del todo.', 'Pulveriza a diario en épocas secas.'],
  ),

  // ===================== HIDROPONÍA =====================
  PlantSpec(
    id: 'h_microgreens', name: 'Microgreens', sci: 'Brotes de rábano, girasol, guisante…', emoji: '🌱', category: PlantCategory.hidroponia,
    tags: const ['Muy rápida', 'Principiante'], toxic: false,
    every: _care(ph: 2, topUp: 1),
    light: '12–16 h de luz', temp: '18–24 °C', humidity: '40–60 %',
    growth: const Growth('Cosecha', 'desde siembra', 7, 14),
    hydro: const Hydro('5,5–6,5', '0,5–1,0 mS/cm', 'Bandeja con manta hidropónica'),
    about: 'Brotes jóvenes muy nutritivos. Se siembran densos, se cortan una vez y se vuelve a sembrar.',
    tips: const ['Mantén la semilla a oscuras los 2–3 primeros días.', 'Corta justo encima de la base con tijera limpia.', 'Basta con agua las primeras jornadas; nutrientes a media dosis después.'],
  ),
  PlantSpec(
    id: 'h_rucula', name: 'Rúcula', sci: 'Eruca vesicaria', emoji: '🥬', category: PlantCategory.hidroponia,
    tags: const ['Rápida', 'Hoja'], toxic: false,
    every: _hydroCare,
    light: '12–14 h de luz', temp: '15–22 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde siembra', 21, 30, repeat: 7, repeatNote: 'cortes cada semana'),
    hydro: const Hydro('6,0–7,0', '0,8–1,2 mS/cm', 'NFT o Kratky'),
    about: 'Hoja de sabor picante y crecimiento muy rápido. Con calor se espiga (florece) y amarga.',
    tips: const ['Corta las hojas exteriores y deja crecer el centro.', 'Por encima de 24 °C tiende a espigarse.'],
  ),
  PlantSpec(
    id: 'h_lechuga', name: 'Lechuga', sci: 'Lactuca sativa', emoji: '🥬', category: PlantCategory.hidroponia,
    tags: const ['Fácil', 'Hoja', 'Principiante'], toxic: false,
    every: _hydroCare,
    light: '12–16 h de luz', temp: '15–22 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde siembra', 30, 45, repeat: 7, repeatNote: 'hojas exteriores cada semana'),
    hydro: const Hydro('5,5–6,5', '0,8–1,2 mS/cm', 'NFT, DWC o Kratky'),
    about: 'La reina de la hidroponía: rápida, agradecida y perfecta para empezar.',
    tips: const ['Trasplanta al sistema cuando tenga 3–4 hojas verdaderas.', 'Agua tibia o caliente favorece la pudrición de raíz: mantén el depósito fresco.', 'Raíces blancas = sanas; marrones y viscosas = problema.'],
  ),
  PlantSpec(
    id: 'h_espinaca', name: 'Espinaca', sci: 'Spinacia oleracea', emoji: '🥬', category: PlantCategory.hidroponia,
    tags: const ['Media', 'Hoja'], toxic: false,
    every: _hydroCare,
    light: '10–14 h de luz', temp: '10–20 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde siembra', 35, 45, repeat: 10),
    hydro: const Hydro('6,0–7,0', '1,8–2,3 mS/cm', 'NFT o DWC'),
    about: 'Prefiere el fresco. Germina mejor si la semilla se remoja 12 h antes.',
    tips: const ['Evita temperaturas altas: se espiga rápido.', 'Cosecha las hojas exteriores para alargar la producción.'],
  ),
  PlantSpec(
    id: 'h_albahaca', name: 'Albahaca', sci: 'Ocimum basilicum', emoji: '🌿', category: PlantCategory.hidroponia,
    tags: const ['Fácil', 'Aromática'], toxic: false,
    every: _hydroCare,
    light: '14–16 h de luz', temp: '20–28 °C', humidity: '40–60 %',
    growth: const Growth('Cosecha', 'desde siembra', 40, 60, repeat: 7, repeatNote: 'pinzados cada semana'),
    hydro: const Hydro('5,5–6,5', '1,0–1,6 mS/cm', 'NFT, DWC o torre'),
    about: 'Una de las aromáticas más productivas en hidroponía. Le encanta el calor y la luz.',
    tips: const ['Pinza por encima de un par de hojas para que ramifique.', 'Quita las flores para que siga produciendo hojas.'],
  ),
  PlantSpec(
    id: 'h_cilantro', name: 'Cilantro', sci: 'Coriandrum sativum', emoji: '🌿', category: PlantCategory.hidroponia,
    tags: const ['Media', 'Aromática'], toxic: false,
    every: _hydroCare,
    light: '12–14 h de luz', temp: '15–24 °C', humidity: '40–60 %',
    growth: const Growth('Cosecha', 'desde siembra', 45, 70, repeat: 10),
    hydro: const Hydro('6,5–6,7', '1,2–1,8 mS/cm', 'NFT o Kratky'),
    about: 'Se espiga con facilidad con calor. Siembra escalonada cada 2–3 semanas para tener siempre.',
    tips: const ['Aplasta suavemente la semilla antes de sembrar.', 'Cosecha los tallos exteriores.'],
  ),
  PlantSpec(
    id: 'h_kale', name: 'Kale', sci: 'Brassica oleracea var. sabellica', emoji: '🥬', category: PlantCategory.hidroponia,
    tags: const ['Fácil', 'Hoja'], toxic: false,
    every: _hydroCare,
    light: '12–16 h de luz', temp: '15–24 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde siembra', 50, 65, repeat: 7),
    hydro: const Hydro('5,5–6,5', '1,2–1,5 mS/cm', 'DWC o NFT'),
    about: 'Col rizada muy resistente que produce durante meses si cosechas por fuera.',
    tips: const ['Cosecha hojas de abajo hacia arriba.', 'Vigila pulgón en el envés.'],
  ),
  PlantSpec(
    id: 'h_acelga', name: 'Acelga', sci: 'Beta vulgaris var. cicla', emoji: '🥬', category: PlantCategory.hidroponia,
    tags: const ['Fácil', 'Hoja'], toxic: false,
    every: _hydroCare,
    light: '12–14 h de luz', temp: '15–25 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde siembra', 50, 60, repeat: 10),
    hydro: const Hydro('6,0–7,0', '1,8–2,3 mS/cm', 'DWC o NFT'),
    about: 'Productiva y tolerante. Sus tallos de colores la hacen muy decorativa.',
    tips: const ['Corta las hojas exteriores a 3 cm de la base.'],
  ),
  PlantSpec(
    id: 'h_menta', name: 'Menta', sci: 'Mentha spicata', emoji: '🌿', category: PlantCategory.hidroponia,
    tags: const ['Fácil', 'Aromática'], toxic: false,
    every: _hydroCare,
    light: '12–14 h de luz', temp: '16–26 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde esqueje', 30, 45, repeat: 10),
    hydro: const Hydro('5,5–6,0', '2,0–2,4 mS/cm', 'DWC o NFT'),
    about: 'Enraíza en agua en pocos días y crece sin parar. Mejor en su propio sistema: es invasiva.',
    tips: const ['Empieza con esquejes de 10 cm.', 'Recórtala a menudo para que no se lignifique.'],
  ),
  PlantSpec(
    id: 'h_pepino', name: 'Pepino', sci: 'Cucumis sativus', emoji: '🥒', category: PlantCategory.hidroponia,
    tags: const ['Media', 'Fruto', 'Tutorado'], toxic: false,
    every: _hydroCare,
    light: '14–16 h de luz', temp: '20–30 °C', humidity: '60–70 %',
    growth: const Growth('Cosecha', 'desde siembra', 50, 70, repeat: 3, repeatNote: 'cada 2–3 días en plena producción'),
    hydro: const Hydro('5,5–6,0', '1,7–2,5 mS/cm', 'Goteo (dutch bucket) o DWC'),
    about: 'Muy productivo en hidroponía. Necesita tutor o malla para trepar.',
    tips: const ['Elige variedades partenocárpicas si cultivas en interior (no necesitan polinización).', 'Cosecha joven: más sabor y la planta produce más.'],
  ),
  PlantSpec(
    id: 'h_fresa', name: 'Fresa', sci: 'Fragaria × ananassa', emoji: '🍓', category: PlantCategory.hidroponia,
    tags: const ['Media', 'Fruto'], toxic: false,
    every: _hydroCare,
    light: '12–16 h de luz', temp: '15–26 °C', humidity: '60–75 %',
    growth: const Growth('Cosecha', 'desde plantón', 60, 90, repeat: 4, repeatNote: 'cada 3–4 días en temporada'),
    hydro: const Hydro('5,5–6,2', '1,0–1,5 mS/cm', 'Torre vertical o NFT'),
    about: 'Ideal en torres verticales. Las variedades reflorecientes dan fruta casi todo el año.',
    tips: const ['Empieza con plantones o estolones, no con semilla.', 'Poliniza a mano con un pincel si está en interior.', 'Quita los estolones para que concentre energía en la fruta.'],
  ),
  PlantSpec(
    id: 'h_pimiento', name: 'Pimiento', sci: 'Capsicum annuum', emoji: '🫑', category: PlantCategory.hidroponia,
    tags: const ['Media', 'Fruto'], toxic: false,
    every: _hydroCare,
    light: '14–16 h de luz', temp: '20–30 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde trasplante', 70, 90, repeat: 7),
    hydro: const Hydro('6,0–6,5', '1,8–2,2 mS/cm', 'Goteo (dutch bucket) o DWC'),
    about: 'Crece lento al principio pero produce durante meses.',
    tips: const ['Quita la primera flor para que la planta crezca más fuerte.', 'Necesita tutor cuando carga fruta.'],
  ),
  PlantSpec(
    id: 'h_tomate', name: 'Tomate cherry', sci: 'Solanum lycopersicum var. cerasiforme', emoji: '🍅', category: PlantCategory.hidroponia,
    tags: const ['Media', 'Fruto', 'Tutorado'], toxic: false,
    every: _hydroCare,
    light: '14–18 h de luz', temp: '18–28 °C', humidity: '60–70 %',
    growth: const Growth('Cosecha', 'desde trasplante', 60, 80, repeat: 3, repeatNote: 'cada 2–3 días en producción'),
    hydro: const Hydro('5,5–6,5', '2,0–3,5 mS/cm', 'Goteo (dutch bucket)'),
    about: 'El fruto estrella de la hidroponía. Necesita mucha luz y nutrientes altos en floración.',
    tips: const ['Quita los chupones de las axilas.', 'Agita suavemente las flores para polinizar.', 'Sube la EC cuando empiece a dar fruto.'],
  ),

  // ===================== HUERTO (tierra) =====================
  PlantSpec(
    id: 'rabano', name: 'Rábano', sci: 'Raphanus sativus', emoji: '🌱', category: PlantCategory.huerto,
    tags: const ['Muy rápida', 'Raíz', 'Principiante'], toxic: false,
    every: _care(water: 2),
    light: 'Sol directo', temp: '10–22 °C', humidity: '40–60 %',
    growth: const Growth('Cosecha', 'desde siembra', 25, 30),
    about: 'La hortaliza más rápida del huerto. Ideal para niños y para empezar.',
    tips: const ['Riego constante o se vuelven huecos y picantes.', 'Siembra cada 2 semanas para cosecha continua.'],
  ),
  PlantSpec(
    id: 'tomate', name: 'Tomatera', sci: 'Solanum lycopersicum', emoji: '🍅', category: PlantCategory.huerto,
    tags: const ['Media', 'Sol', 'Fruto'], toxic: false,
    every: _care(water: 2, fert: 15),
    light: 'Sol directo', temp: '18–30 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde trasplante', 60, 85, repeat: 4),
    about: 'Hortaliza de verano. Necesita riego constante y tutor.',
    tips: const ['Riego regular evita frutos agrietados.', 'Quita los chupones de las axilas.', 'Vigila mosca blanca y mildiu.'],
  ),
  PlantSpec(
    id: 'zanahoria', name: 'Zanahoria', sci: 'Daucus carota', emoji: '🥕', category: PlantCategory.huerto,
    tags: const ['Media', 'Raíz'], toxic: false,
    every: _care(water: 3),
    light: 'Sol directo', temp: '15–24 °C', humidity: '40–60 %',
    growth: const Growth('Cosecha', 'desde siembra', 70, 80),
    about: 'Necesita tierra suelta y profunda, sin piedras, para raíces rectas.',
    tips: const ['Aclara las plántulas a 5 cm.', 'No abones con estiércol fresco: se deforman.'],
  ),
  PlantSpec(
    id: 'papa', name: 'Papa', sci: 'Solanum tuberosum', emoji: '🥔', category: PlantCategory.huerto,
    tags: const ['Media', 'Tubérculo'], toxic: true,
    every: _care(water: 5),
    light: 'Sol directo', temp: '15–20 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde siembra del tubérculo', 90, 120),
    about: 'Se planta un trozo de papa con yemas. Se cosecha cuando la planta amarillea y se seca.',
    tips: const ['Aporca (tapa con tierra) los tallos a medida que crecen.', 'Hojas y papas verdes son tóxicas.'],
  ),
  PlantSpec(
    id: 'ajo', name: 'Ajo', sci: 'Allium sativum', emoji: '🧄', category: PlantCategory.huerto,
    tags: const ['Fácil', 'Bulbo', 'Lenta'], toxic: false,
    every: _care(water: 7),
    light: 'Sol directo', temp: '10–25 °C', humidity: '30–50 %',
    growth: const Growth('Cosecha', 'desde siembra del diente', 180, 240),
    about: 'Se planta en otoño y se cosecha a inicios del verano, cuando las hojas se secan.',
    tips: const ['Planta los dientes con la punta hacia arriba a 3 cm.', 'Deja de regar un mes antes de cosechar.'],
  ),
  PlantSpec(
    id: 'esparrago', name: 'Espárrago', sci: 'Asparagus officinalis', emoji: '🌱', category: PlantCategory.huerto,
    tags: const ['Paciencia', 'Perenne'], toxic: false,
    every: _care(water: 7, fert: 60),
    light: 'Sol directo', temp: '15–25 °C', humidity: '40–60 %',
    growth: const Growth('Cosecha', 'desde garra (raíz)', 730, 1095, repeat: 365, repeatNote: 'cada primavera durante 15–20 años'),
    about: 'Cultivo perenne: no se cosecha los primeros 2 años, pero luego produce durante décadas.',
    tips: const ['No cortes los turiones el primer año.', 'Deja crecer los helechos en verano para fortalecer la raíz.'],
  ),
  PlantSpec(
    id: 'arandano', name: 'Arándano', sci: 'Vaccinium corymbosum', emoji: '🫐', category: PlantCategory.huerto,
    tags: const ['Paciencia', 'Arbusto', 'Suelo ácido'], toxic: false,
    every: _care(water: 3, fert: 45),
    light: 'Sol o semisombra', temp: '10–25 °C', humidity: '50–70 %',
    growth: const Growth('Cosecha', 'desde plantón', 730, 1095, repeat: 365, repeatNote: 'cada verano'),
    about: 'Arbusto que necesita suelo ácido (pH 4,5–5,5). Da buena cosecha a partir del 2.º–3.er año.',
    tips: const ['Usa sustrato para plantas ácidas.', 'Riega con agua de lluvia si tu agua es calcárea.'],
  ),
  PlantSpec(
    id: 'limonero', name: 'Limonero (injertado)', sci: 'Citrus × limon', emoji: '🍋', category: PlantCategory.huerto,
    tags: const ['Paciencia', 'Árbol', 'Maceta grande'], toxic: false,
    every: _care(water: 5, fert: 30, repot: 730),
    light: 'Sol directo', temp: '15–30 °C', humidity: '40–60 %',
    growth: const Growth('Cosecha', 'desde plantón injertado', 730, 1095, repeat: 180),
    about: 'Un limonero injertado fructifica a los 2–3 años. Desde semilla puede tardar 5–7 años.',
    tips: const ['Protégelo de heladas.', 'Hojas amarillas con nervios verdes = falta de hierro.'],
  ),

  // ===================== SUCULENTAS =====================
  PlantSpec(
    id: 'echeveria', name: 'Echeveria', sci: 'Echeveria elegans', emoji: '🪷', category: PlantCategory.suculenta,
    tags: const ['Muy fácil', 'Sol', 'Riego bajo'], toxic: false,
    every: _care(water: 14, fert: 60, rotate: 14),
    light: 'Sol directo o muy brillante', temp: '10–28 °C', humidity: '20–40 %',
    growth: const Growth('Planta formada', 'desde hoja', 90, 180),
    about: 'Roseta que se reproduce fácilmente por hoja: a las 2–4 semanas salen raíces y una rosetita.',
    tips: const ['Deja secar la hoja 2–3 días antes de ponerla sobre sustrato.', 'Riega "empapa y seca": a fondo y solo cuando esté seco.'],
  ),
  PlantSpec(
    id: 'sedum', name: 'Sedum', sci: 'Sedum spp.', emoji: '🌵', category: PlantCategory.suculenta,
    tags: const ['Muy fácil', 'Sol', 'Cubresuelos'], toxic: false,
    every: _care(water: 10, fert: 90),
    light: 'Sol directo', temp: '5–30 °C', humidity: '20–40 %',
    growth: const Growth('Planta formada', 'desde esqueje', 60, 120),
    about: 'Crece rápido y cubre macetas y jardineras. Muchas especies aguantan el frío.',
    tips: const ['Basta con dejar caer esquejes sobre la tierra.', 'Si se alarga, le falta sol.'],
  ),
  PlantSpec(
    id: 'kalanchoe', name: 'Kalanchoe', sci: 'Kalanchoe blossfeldiana', emoji: '🌺', category: PlantCategory.suculenta,
    tags: const ['Fácil', 'Florece'], toxic: true,
    every: _care(water: 10, fert: 30),
    light: 'Brillante', temp: '15–25 °C', humidity: '30–50 %',
    growth: const Growth('Floración', 'desde esqueje', 120, 180, repeat: 365),
    about: 'Suculenta de flor. Para que vuelva a florecer necesita 6 semanas de noches largas (14 h de oscuridad).',
    tips: const ['Retira las flores secas.', 'En otoño, tápala por la noche para provocar la floración.'],
  ),
  PlantSpec(
    id: 'haworthia', name: 'Haworthia', sci: 'Haworthiopsis attenuata', emoji: '🌵', category: PlantCategory.suculenta,
    tags: const ['Muy fácil', 'Poca luz'], toxic: false,
    every: _care(water: 14, fert: 90),
    light: 'Brillante indirecta', temp: '10–27 °C', humidity: '20–40 %',
    growth: const Growth('Planta formada', 'desde hijuelo', 180, 365),
    about: 'Pequeña y de crecimiento lento. Una de las pocas suculentas que tolera interior con poca luz.',
    tips: const ['Separa los hijuelos al trasplantar.', 'Puntas rojizas = demasiado sol.'],
  ),
  PlantSpec(
    id: 'jade', name: 'Árbol de jade', sci: 'Crassula ovata', emoji: '🌳', category: PlantCategory.suculenta,
    tags: const ['Fácil', 'Sol', 'Lenta'], toxic: true,
    every: _care(water: 14, fert: 60, rotate: 21, repot: 730),
    light: 'Sol directo o muy brillante', temp: '10–27 °C', humidity: '30–50 %',
    growth: const Growth('Planta formada', 'desde esqueje', 365, 730),
    about: 'Suculenta arbustiva muy longeva. Con los años forma un tronco como un bonsái y puede florecer en invierno.',
    tips: const ['Los esquejes enraízan en 2–4 semanas.', 'Hojas arrugadas = necesita agua.'],
  ),
  PlantSpec(
    id: 'aloe', name: 'Aloe vera', sci: 'Aloe barbadensis', emoji: '🌵', category: PlantCategory.suculenta,
    tags: const ['Muy fácil', 'Sol', 'Riego bajo'], toxic: true,
    every: _care(water: 14, fert: 90, rotate: 14, repot: 730),
    light: 'Sol directo o muy brillante', temp: '13–27 °C', humidity: '20–40 %',
    growth: const Growth('Cosecha', 'desde hijuelo', 730, 1095, repeat: 60, repeatNote: 'hojas exteriores cada 2 meses'),
    about: 'Suculenta medicinal. Las hojas tienen su mejor gel cuando la planta es adulta (2–3 años).',
    tips: const ['Usa sustrato para cactus con buen drenaje.', 'Corta solo hojas exteriores, 3–4 por vez.', 'Hojas blandas y translúcidas = exceso de agua.'],
  ),
  PlantSpec(
    id: 'cactus', name: 'Cactus', sci: 'Mammillaria spp.', emoji: '🌵', category: PlantCategory.suculenta,
    tags: const ['Muy fácil', 'Sol', 'Riego mínimo'], toxic: false,
    every: _care(water: 21, fert: 90, rotate: 30, repot: 730),
    light: 'Sol directo', temp: '10–30 °C', humidity: '10–30 %',
    growth: const Growth('Floración', 'desde semilla', 730, 1825, repeat: 365),
    about: 'Desde semilla tarda años en florecer; comprado adulto florece cada primavera si pasa un invierno fresco y seco.',
    tips: const ['En invierno casi no riegues.', 'Base blanda y oscura = pudrición.'],
  ),

  // ===================== FLORES =====================
  PlantSpec(
    id: 'calendula', name: 'Caléndula', sci: 'Calendula officinalis', emoji: '🌼', category: PlantCategory.flor,
    tags: const ['Muy fácil', 'Sol', 'Comestible'], toxic: false,
    every: _care(water: 3, fert: 30),
    light: 'Sol directo', temp: '10–25 °C', humidity: '40–60 %',
    growth: const Growth('Floración', 'desde siembra', 45, 60, repeat: 7),
    about: 'Flor naranja comestible y medicinal. Atrae insectos beneficiosos al huerto.',
    tips: const ['Corta las flores pasadas para que siga floreciendo.'],
  ),
  PlantSpec(
    id: 'zinnia', name: 'Zinnia', sci: 'Zinnia elegans', emoji: '🌸', category: PlantCategory.flor,
    tags: const ['Fácil', 'Sol', 'Flor de corte'], toxic: false,
    every: _care(water: 3, fert: 21),
    light: 'Sol directo', temp: '18–30 °C', humidity: '40–60 %',
    growth: const Growth('Floración', 'desde siembra', 60, 70, repeat: 7),
    about: 'Flor de verano muy colorida y perfecta para ramos: cuanto más cortas, más florece.',
    tips: const ['Riega en la base para evitar oídio.'],
  ),
  PlantSpec(
    id: 'petunia', name: 'Petunia', sci: 'Petunia × hybrida', emoji: '🌺', category: PlantCategory.flor,
    tags: const ['Fácil', 'Sol', 'Colgante'], toxic: false,
    every: _care(water: 2, fert: 14),
    light: 'Sol directo', temp: '15–28 °C', humidity: '40–60 %',
    growth: const Growth('Floración', 'desde siembra', 70, 90, repeat: 7),
    about: 'Floración continua de primavera a otoño en balcones y colgantes.',
    tips: const ['Abona cada 2 semanas en floración.', 'Despunta los tallos largos para que se ponga frondosa.'],
  ),
  PlantSpec(
    id: 'girasol', name: 'Girasol', sci: 'Helianthus annuus', emoji: '🌻', category: PlantCategory.flor,
    tags: const ['Muy fácil', 'Sol', 'Niños'], toxic: false,
    every: _care(water: 3),
    light: 'Sol directo', temp: '18–30 °C', humidity: '40–60 %',
    growth: const Growth('Floración', 'desde siembra', 70, 100),
    about: 'Crece a toda velocidad y sigue al sol mientras es joven. Las variedades enanas sirven para maceta.',
    tips: const ['Siembra directa: no le gusta el trasplante.', 'Pon tutor a las variedades altas.'],
  ),
  PlantSpec(
    id: 'tulipan', name: 'Tulipán', sci: 'Tulipa spp.', emoji: '🌷', category: PlantCategory.flor,
    tags: const ['Fácil', 'Bulbo', 'Primavera'], toxic: true,
    every: _care(water: 7),
    light: 'Sol directo', temp: '5–20 °C', humidity: '40–60 %',
    growth: const Growth('Floración', 'desde plantación del bulbo', 120, 180, repeat: 365),
    about: 'Se planta en otoño y florece en primavera. Necesita frío invernal para florecer.',
    tips: const ['Planta el bulbo a una profundidad de 2–3 veces su altura.', 'Deja que las hojas se sequen solas tras florecer.'],
  ),
  PlantSpec(
    id: 'rosa', name: 'Rosal', sci: 'Rosa spp.', emoji: '🌹', category: PlantCategory.flor,
    tags: const ['Media', 'Sol', 'Exterior'], toxic: false,
    every: _care(water: 3, fert: 15),
    light: 'Sol directo 6 h', temp: '15–28 °C', humidity: '40–60 %',
    growth: const Growth('Floración', 'desde plantón', 60, 90, repeat: 45, repeatNote: 'nueva tanda cada 6–8 semanas'),
    about: 'Arbusto de exterior. Los rosales remontantes florecen en tandas de primavera a otoño. Vigila pulgones y oídio.',
    tips: const ['Riega en la base, no sobre las hojas.', 'Corta las rosas pasadas por encima de una hoja de 5 folíolos.', 'Revisa el envés de las hojas buscando pulgón.'],
  ),
  PlantSpec(
    id: 'rosa_esqueje', name: 'Rosal desde esqueje', sci: 'Rosa spp.', emoji: '🥀', category: PlantCategory.flor,
    tags: const ['Paciencia', 'Sol'], toxic: false,
    every: _care(water: 3, fert: 30),
    light: 'Brillante, sin sol fuerte al inicio', temp: '15–25 °C', humidity: '60–80 %',
    growth: const Growth('Floración', 'desde esqueje', 365, 730, repeat: 45),
    about: 'Un esqueje de rosal enraíza en 4–8 semanas, pero tarda 1–2 años en dar sus primeras rosas.',
    tips: const ['Usa esquejes de 20 cm de un tallo que ya floreció.', 'Cúbrelo con una botella cortada para mantener humedad.'],
  ),
  PlantSpec(
    id: 'lavanda', name: 'Lavanda', sci: 'Lavandula angustifolia', emoji: '💜', category: PlantCategory.flor,
    tags: const ['Fácil', 'Sol', 'Aromática'], toxic: false,
    every: _care(water: 10, fert: 90),
    light: 'Sol directo', temp: '10–30 °C', humidity: '20–40 %',
    growth: const Growth('Floración', 'desde semilla', 365, 540, repeat: 365),
    about: 'Aromática mediterránea. Desde semilla florece bien a partir del segundo año.',
    tips: const ['No la riegues de más: prefiere suelo seco.', 'Pódala tras la floración sin llegar a la madera vieja.'],
  ),
  PlantSpec(
    id: 'orquidea', name: 'Orquídea', sci: 'Phalaenopsis', emoji: '🌸', category: PlantCategory.flor,
    tags: const ['Media', 'Luz difusa', 'Interior'], toxic: false,
    every: _care(water: 8, fert: 15, mist: 3, repot: 730),
    light: 'Brillante indirecta', temp: '18–28 °C', humidity: '50–70 %',
    growth: const Growth('Floración', 'desde la última floración', 240, 365, repeat: 365),
    about: 'Epífita: sus raíces necesitan aire. Vuelve a florecer una vez al año; una bajada de temperatura nocturna en otoño ayuda.',
    tips: const ['Sumerge la maceta 10 min en agua y escurre bien.', 'Raíces verdes = hidratada; plateadas = necesita agua.', 'No cortes la vara floral si sigue verde.'],
  ),
  PlantSpec(
    id: 'peonia', name: 'Peonía', sci: 'Paeonia lactiflora', emoji: '🌺', category: PlantCategory.flor,
    tags: const ['Paciencia', 'Perenne'], toxic: true,
    every: _care(water: 7, fert: 60),
    light: 'Sol directo', temp: '5–25 °C', humidity: '40–60 %',
    growth: const Growth('Floración', 'desde raíz', 730, 1095, repeat: 365),
    about: 'Flor espectacular que tarda 2–3 años en florecer bien, pero luego vive décadas.',
    tips: const ['No entierres las yemas más de 5 cm o no florecerá.', 'Necesita frío en invierno.'],
  ),
];

// ✏️ MODIFICAR: lugares de la casa.
const rooms = ['Sala', 'Dormitorio', 'Cocina', 'Baño', 'Oficina', 'Balcón', 'Jardín', 'Sistema hidropónico'];

class Article {
  final String title, tag, emoji, body;
  const Article(this.title, this.tag, this.emoji, this.body);
}

// ✏️ MODIFICAR: guías de cuidado (título, etiqueta, emoji, texto).
const articles = [
  Article('Cómo saber si tu planta necesita agua', 'Guía', '💧',
      'Mete el dedo 3–5 cm en el sustrato: si sale seco, riega. Levanta la maceta: si pesa poco, tiene sed. Las hojas lacias o curvadas también son señal. Riega a fondo hasta que salga agua por los agujeros y vacía el plato a los 15 minutos.'),
  Article('Hidroponía para principiantes', 'Hidroponía', '💧',
      'Empieza con lechuga, albahaca o rúcula en un sistema Kratky o DWC. Mide el pH cada 2–3 días (la mayoría de plantas lo quiere entre 5,5 y 6,5) y la EC para saber la concentración de nutrientes. Rellena el depósito con agua cuando baje y cambia toda la solución cada 1–2 semanas. Mantén el agua entre 18 y 22 °C y a oscuras para evitar algas.'),
  Article('pH y EC: qué son y cómo ajustarlos', 'Hidroponía', '⚗️',
      'El pH indica si la solución es ácida o alcalina: fuera del rango, la planta no puede absorber nutrientes aunque estén en el agua. Súbelo con pH+ o bájalo con pH− poco a poco. La EC (conductividad) mide la cantidad de nutrientes: si es baja, añade nutriente; si es alta, añade agua. Las hojas jóvenes necesitan EC baja (0,8–1,2) y los frutos, alta (2,0–3,5).'),
  Article('Plagas más comunes en interior', 'Plagas', '🐛',
      'Cochinilla algodonosa (bolitas blancas), araña roja (telitas finas, puntitos amarillos), pulgón (insectos verdes en brotes), trips (rayas plateadas) y mosquita del sustrato (vuela al regar). Aísla la planta afectada y usa jabón potásico o aceite de neem cada 5–7 días.'),
  Article('Suculentas: el método "empapa y seca"', 'Suculentas', '🌵',
      'Riega a fondo hasta que salga agua por abajo y no vuelvas a regar hasta que el sustrato esté totalmente seco. Usa macetas con agujero y sustrato mineral (arena gruesa, perlita, pómez). Si se estiran y pierden color, les falta sol. Las hojas blandas y translúcidas son exceso de agua.'),
  Article('Cómo hacer que tu rosal florezca más', 'Flores', '🌹',
      'Dale al menos 6 horas de sol, abona cada 2 semanas en primavera y verano y corta las rosas pasadas por encima de la primera hoja de 5 folíolos. Poda fuerte a finales de invierno dejando 3–5 tallos sanos. Riega en la base y por la mañana para evitar hongos.'),
  Article('Hojas amarillas: causas y soluciones', 'Diagnóstico', '🍂',
      'Amarillas y blandas: exceso de riego. Amarillas y secas: falta de agua o sol directo. Solo las de abajo: envejecimiento normal o falta de nitrógeno. Con manchas: posible hongo, retira las hojas afectadas.'),
  Article('Cuándo trasplantar', 'Guía', '🪴',
      'Cuando salen raíces por los agujeros, el agua escurre sin empapar o la planta deja de crecer. Hazlo en primavera, a una maceta 2–5 cm más grande, con sustrato fresco.'),
];
