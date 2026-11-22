# 🧭 Guía del código de LeaFiore

Esta guía sirve para cambiar cosas de la app sin tener que leer todo el código.

- **Si quieres cambiar algo concreto**, búscalo en la [sección 1](#1-índice-dónde-cambio).
- **Si quieres entender cómo funciona la app**, lee las secciones [2](#2-mapa-de-la-app-qué-archivo-es-cada-pantalla) y [3](#3-qué-hace-cada-archivo).

> **Truco:** en el código hay comentarios `✏️ MODIFICAR` justo encima de lo que se puede cambiar. Busca `✏️` en VS Code (Cmd+Shift+F) y verás todos.
> Además, cada archivo empieza con un comentario que explica qué hace.
>
> Todas las rutas son relativas a `app/lib/`. Los números de línea son aproximados: si cambias el código se desplazan, así que mejor busca por el **nombre** que aparece en la columna «Qué buscar».

---

## 1. Índice: ¿dónde cambio…?

### Aspecto visual

| Quiero cambiar… | Archivo | Qué buscar |
|---|---|---|
| Los colores de toda la app | `theme.dart:9` | `class C` (green600 es el verde principal) |
| La fuente (tipo de letra) | `theme.dart` | `GoogleFonts.interTextTheme` y `serif()` |
| El estilo de las tarjetas de cristal | `widgets/ui.dart` | `class Glass` |
| El fondo verde con hojas | `widgets/ui.dart` | `class LeafBackground` |
| Los botones | `widgets/ui.dart` | `class Btn` y `class CircleBtn` |
| El logo | `widgets/leaf_logo.dart` | `_LogoPainter` |
| La altura de las tarjetas en «Mi jardín» | `screens/garden.dart:68` | `childAspectRatio` |

### Textos

| Quiero cambiar… | Archivo | Qué buscar |
|---|---|---|
| Los textos de la intro (las 3 diapositivas) | `screens/intro.dart:26` | `_slides` |
| El saludo («Buenos días»…) | `screens/home.dart:38` | `greet` |
| Los títulos de las secciones del inicio | `screens/home.dart` | `SectionHead(` |
| Los nombres e iconos de la barra inferior | `screens/shell.dart:58` | `_tabBtn(` |
| Los nombres de las tareas (Regar, Abonar…) | `data/library.dart:84` | `enum CareTask` |
| Los nombres de las categorías | `data/library.dart:14` | `enum PlantCategory` |
| Los modos del escáner (planta, hoja, insecto) | `models.dart:165` | `enum ScanMode` |
| Los textos de gravedad del diagnóstico | `screens/result.dart:32` | `sev` |
| El estado de cada planta («Tiene sed»…) | `state/app_state.dart:208` | `health(` |
| «Hoy», «Mañana», «En 3 días» | `state/app_state.dart` | `dueLabel` |
| Los nombres de los días (lun, mar…) | `widgets/ui.dart` | `weekdays` |

### Plantas y datos

| Quiero cambiar… | Archivo | Qué buscar |
|---|---|---|
| **Añadir o editar una planta** | `data/library.dart:164` | `plantLibrary` (ver la [sección 4](#4-cómo-añadir-una-planta-nueva)) |
| Cada cuántos días se riega o abona una planta | `data/library.dart` | `every: _care(water: 7, …)` dentro de esa planta |
| El tiempo de cosecha o floración | `data/library.dart` | `growth: const Growth(…)` dentro de esa planta |
| pH, EC y sistema de hidroponía | `data/library.dart` | `hydro: const Hydro(…)` dentro de esa planta |
| Los cuidados por defecto de la hidroponía | `data/library.dart:127` | `_hydroCare` |
| Los lugares de la casa (Sala, Baño…) | `data/library.dart:593` | `rooms` |
| Las guías y artículos | `data/library.dart:601` | `articles` |
| Los valores de una planta «personalizada» | `data/library.dart:144` | `customBase` |
| Los grupos de «Tiempos de cultivo» | `screens/timeline.dart:31` | `_buckets` |

### Recordatorios

| Quiero cambiar… | Archivo | Qué buscar |
|---|---|---|
| La hora del aviso diario (ahora a las 9:00) | `services/notifications.dart:25` | `_hour` |
| La hora a partir de la cual no se avisa de noche | `services/notifications.dart:25` | `_quietAfter` |
| Cuántos días a futuro se programan | `services/notifications.dart:25` | `_daysAhead` |
| El texto de la notificación | `services/notifications.dart:105` | `parts` y `title:` |
| Las opciones para posponer (1 o 2 días) | `widgets/sheets.dart` | `showTaskSheet` |
| El cálculo de cuándo toca cada tarea | `state/app_state.dart:138` | `dueIn(` |

### Diagnóstico con IA

| Quiero cambiar… | Archivo | Qué buscar |
|---|---|---|
| Las instrucciones que recibe la IA | `services/diagnosis.dart:17` | `_system` |
| El modelo de Claude | `services/diagnosis.dart` | `_model` |
| Los campos que devuelve la IA | `services/diagnosis.dart` | `_schema` (y añade el campo en `models.dart` → `Diagnosis`) |
| La longitud máxima de la respuesta | `services/diagnosis.dart:65` | `max_tokens` |
| Los resultados del modo demo | `services/diagnosis.dart:119` | `demo(` |
| El tamaño y la calidad de la foto enviada | `screens/scan.dart:52` | `pickImage(` |
| La información de la planta que se envía a la IA | `screens/scan.dart` | `_describe(` |

### Nombre e identidad de la app

| Quiero cambiar… | Archivo | Qué buscar |
|---|---|---|
| El nombre bajo el icono en Android | `android/app/src/main/AndroidManifest.xml` | `android:label` |
| El nombre bajo el icono en iOS | `ios/Runner/Info.plist` | `CFBundleDisplayName` |
| El identificador de la app (para publicarla) | `android/app/build.gradle.kts` | `applicationId` |
| Los textos de permiso de cámara y fotos (iOS) | `ios/Runner/Info.plist` | `NSCameraUsageDescription` |
| El icono de la app | `android/app/src/main/res/mipmap-*` y `ios/Runner/Assets.xcassets/AppIcon.appiconset` | Reemplaza las imágenes |
| Las librerías que usa | `pubspec.yaml` | `dependencies:` |

---

## 2. Mapa de la app: qué archivo es cada pantalla

```
Intro (solo la 1ª vez) ─────────────── screens/intro.dart
   │
   ▼
Shell: barra inferior ──────────────── screens/shell.dart
   ├── 🏠 Inicio ───────────────────── screens/home.dart
   ├── 🌿 Mi jardín ────────────────── screens/garden.dart
   ├── 📷 Escanear (botón central) ─── screens/scan.dart
   │        └── Resultado ──────────── screens/result.dart
   ├── 💧 Cuidados ─────────────────── screens/care.dart
   └── 👤 Perfil ───────────────────── screens/profile.dart

Pantallas que se abren desde otras:
   Ficha de una planta tuya ────────── screens/plant_detail.dart
   Biblioteca de plantas ───────────── screens/library.dart  (LibraryScreen)
   Ficha de una especie ────────────── screens/library.dart  (showSpecDetail)
   Añadir planta ───────────────────── screens/library.dart  (AddPlantScreen)
   Tiempos de cultivo ──────────────── screens/timeline.dart
   Hojas emergentes (tarea, guías) ─── widgets/sheets.dart
```

---

## 3. Qué hace cada archivo

### Raíz (`lib/`)

| Archivo | Qué hace |
|---|---|
| `main.dart` | Arranca la app: carga los datos, prepara las notificaciones y abre la intro o la app. |
| `theme.dart` | Define los colores (`C`) y las fuentes. |
| `models.dart` | Define la forma de los datos: `Plant`, `Scan`, `Diagnosis`, `HistoryEntry`, `ScanMode`. |

### `data/`: información fija

| Archivo | Qué hace |
|---|---|
| `library.dart` | Contiene las 47 plantas (cuidados, tiempos de cosecha, hidroponía, consejos), las categorías, los tipos de tarea, los lugares y las guías. **Es el archivo que más vas a tocar.** |

### `state/`: el «cerebro»

| Archivo | Qué hace |
|---|---|
| `app_state.dart` | Guarda y carga todo en el teléfono. Calcula cuándo toca cada tarea, el estado de salud de cada planta y el progreso de la cosecha. Cualquier pantalla accede a él con `AppScope.of(context)`. |

### `services/`: conexión con el exterior

| Archivo | Qué hace |
|---|---|
| `diagnosis.dart` | Envía la foto a la API de Claude y convierte la respuesta en un diagnóstico. Sin clave de API usa resultados de ejemplo. |
| `notifications.dart` | Programa los recordatorios diarios del teléfono. |

### `screens/`: pantallas

| Archivo | Qué hace |
|---|---|
| `intro.dart` | Bienvenida con 3 diapositivas y el nombre del usuario. |
| `shell.dart` | Las 4 pestañas y la barra inferior flotante con el botón de escanear. |
| `home.dart` | Inicio: saludo, carrusel de plantas, tareas de hoy, cosechas próximas, categorías y diagnósticos. Incluye `PlantCard`. |
| `garden.dart` | Mi jardín: cuadrícula de plantas o vista por lugar. |
| `care.dart` | Cuidados: tareas de hoy, próximas y hechas, con la semana. |
| `scan.dart` | Escáner: elegir el modo, tomar la foto y analizarla. |
| `result.dart` | Resultado del diagnóstico. |
| `plant_detail.dart` | Ficha completa de una planta tuya: progreso, cuidados, recordatorios e historial. |
| `library.dart` | Biblioteca de especies, ficha de una especie y formulario para añadir una planta. |
| `timeline.dart` | Tiempos de cosecha y floración ordenados del más corto al más largo. |
| `profile.dart` | Perfil: nombre, clave de API, estadísticas y borrar datos. |

### `widgets/`: piezas reutilizables

| Archivo | Qué hace |
|---|---|
| `ui.dart` | Componentes comunes: `Glass` (tarjeta de cristal), `Btn`, `Pill`, `TopBar`, `Segment`, `toast`, `confirm`, formato de fechas… |
| `sheets.dart` | Hojas que suben desde abajo: acciones de una tarea y guías. |
| `leaf_logo.dart` | El logo, dibujado con código. |

### Otras carpetas

| Carpeta | Qué hay |
|---|---|
| `app/test/` | Pruebas automáticas. `widget_test.dart` prueba la lógica y `screens_test.dart` dibuja cada pantalla para detectar errores de diseño. |
| `app/test/goldens/` | Capturas de cada pantalla que generan las pruebas. |
| `app/android/` y `app/ios/` | Configuración nativa (permisos, nombre, icono). Rara vez hay que tocarla. |

---

## 4. Cómo añadir una planta nueva

1. Abre `app/lib/data/library.dart` y busca `plantLibrary`.
2. Copia una planta parecida (por ejemplo `h_lechuga` para hidroponía o `rosa` para flores), pégala debajo y cambia los valores:

```dart
PlantSpec(
  id: 'mi_planta',                 // único, sin espacios ni tildes
  name: 'Mi planta', sci: 'Nombre científico', emoji: '🌱',
  category: PlantCategory.huerto,  // interior, hidroponia, huerto, suculenta o flor
  tags: const ['Fácil', 'Sol'], toxic: false,
  every: _care(water: 3, fert: 15),   // días entre tareas (0 o sin poner = no aplica)
  //   opciones: water, fert, mist, rotate, repot, ph, nutrients, topUp
  //   para hidroponía usa:  every: _hydroCare,
  light: 'Sol directo', temp: '15–25 °C', humidity: '50–70 %',
  growth: const Growth('Cosecha', 'desde siembra', 60, 90, repeat: 7, repeatNote: 'cada semana'),
  //   'Cosecha' o 'Floración' · mínimo y máximo de días · repeat = días hasta la siguiente (0 = una vez)
  hydro: const Hydro('5,5–6,5', '1,0–1,5 mS/cm', 'DWC'),   // solo para hidroponía; si no, bórrala
  about: 'Descripción corta.',
  tips: const ['Consejo 1', 'Consejo 2'],
),
```

3. Guarda y ejecuta la app. La planta aparece sola en la biblioteca, en su categoría y en «Tiempos de cultivo».

---

## 5. Cómo funciona por dentro (resumen)

1. Al abrir la app, **`main.dart`** carga los datos guardados con `AppState.load()`.
2. Las pantallas leen esos datos con `AppScope.of(context)`.
3. Cuando haces algo (regar, añadir una planta, diagnosticar), la pantalla llama a `AppState` (`complete`, `addPlant`, `addScan`…). `AppState` lo guarda con `save()`, y eso hace tres cosas:
   - guarda los datos en el teléfono,
   - redibuja las pantallas,
   - reprograma las notificaciones.
4. **Cuándo toca una tarea:** fecha de la última vez + cada cuántos días (de `library.dart`, o el valor que hayas puesto en la planta). Si la pospones, se usa esa fecha.
5. **Las fotos** se guardan en la carpeta de la app. En los datos solo se guarda el nombre del archivo.

---

## 6. Después de cambiar algo

```bash
cd app
flutter analyze                 # busca errores en el código
flutter test                    # ejecuta las pruebas
flutter run                     # abre la app
```

Si cambias el diseño de una pantalla, las pruebas de capturas pueden fallar porque la imagen ya no es igual. En ese caso, actualiza las capturas con:

```bash
flutter test --update-goldens
```
