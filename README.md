# 🌿 LeaFiore

App de jardín para **Android e iOS**, hecha en Flutter. Te dice qué cuidados necesita cada planta y cuándo hacerlos, y diagnostica problemas a partir de una foto de la planta, de sus hojas o de los insectos que tenga.

> 📘 **¿Quieres modificar algo?** Lee la [Guía del código](GUIA.md): explica qué hace cada archivo y tiene un índice de dónde cambiar cada cosa.

## Funciones

- **Mi jardín**: tus plantas en cuadrícula o agrupadas por lugar (sala, baño, balcón, sistema hidropónico…).
- **Cuidados y recordatorios**: riego, abono, pulverizado, rotación y trasplante, con una frecuencia propia para cada planta. Las tareas se pueden completar o posponer, y tienen una vista de semana.
- **Notificaciones locales**: un aviso diario a las 9:00 con las tareas del día. Funcionan aunque la app esté cerrada.
- **Diagnóstico por foto**: modos *planta*, *hoja* e *insecto*, analizados con Claude. Muestra el problema, su gravedad, el tratamiento y la prevención, y permite programar una revisión a los 7 días.
- **Hidroponía**: control de pH, EC (nutrientes) y relleno del depósito, con los valores recomendados para cada cultivo.
- **Tiempos de cosecha y floración**: ordenados del más corto al más largo (de días a años), con una barra de progreso desde la fecha de siembra.
- **Biblioteca**: 47 plantas en 5 categorías (interior, hidroponía, huerto, suculentas y flores/rosas), además de guías de cuidado.

## Requisitos

- Flutter 3.47 o superior (Dart 3.13)
- Xcode para iOS y Android Studio o el SDK de Android (API 37) para Android

## Cómo ejecutarla

```bash
cd app
flutter pub get
flutter run
```

Compilar:

```bash
flutter build apk          # Android
flutter build ios          # iOS (requiere firma)
```

## Diagnóstico con IA

El diagnóstico usa la API de Claude (`claude-opus-5-5`). Para activarlo, pega tu clave de API en **Perfil → Clave de API**. Sin clave, la app funciona en **modo demo** con resultados de ejemplo.

> La clave se guarda en el dispositivo sin cifrar (`shared_preferences`). Úsala solo en tus propios dispositivos.

## Estructura

```
app/lib/
├── main.dart              # arranque, intro o app principal
├── theme.dart             # colores y tipografía (estilo glassmorphism)
├── models.dart            # Plant, Scan, Diagnosis…
├── data/library.dart      # biblioteca de plantas, tiempos de cultivo y guías
├── state/app_state.dart   # estado, persistencia y cálculo de tareas
├── services/
│   ├── diagnosis.dart     # llamada a la API de Claude
│   └── notifications.dart # recordatorios locales
├── screens/               # intro, inicio, jardín, cuidados, escáner, ficha, biblioteca…
└── widgets/               # componentes reutilizables
```

## Pruebas

```bash
cd app
flutter test                    # pruebas de lógica y de pantallas
flutter test --update-goldens   # regenera las capturas en test/goldens
```
