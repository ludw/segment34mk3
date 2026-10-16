# Segment34 Mk3 — Agent Instructions

A Garmin Connect IQ watchface written in **Monkey C** (`.mc` files), targeting ~64 Garmin devices across multiple screen sizes and display technologies.

## Build & Test

The commands below use two shell variables; set them for your machine first:
```bash
# Connect IQ SDK root (the folder containing bin/monkeybrains.jar), e.g. on macOS:
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/<sdk-version>"
# Your Connect IQ developer signing key:
DEV_KEY="/path/to/developer_key"
```
`monkeyc` is usually not on PATH, so the commands call the SDK jar directly.

**Build (type-check, no simulator):**
```bash
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "$SDK/bin/monkeybrains.jar" \
  -o bin/Segment34mk3.prg -f monkey.jungle \
  -y "$DEV_KEY" \
  -d fenix847mm_sim -w
```
Omit `-r` to skip launching the simulator. Change `-d` to target a different device.

**Run unit tests** (requires the Connect IQ simulator):
```bash
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "$SDK/bin/monkeybrains.jar" \
  -o bin/test.prg -f monkey.jungle -y "$DEV_KEY" \
  -d fenix7 -t
open "$SDK/bin/ConnectIQ.app"   # start the simulator if it isn't running (macOS)
"$SDK/bin/monkeydo" bin/test.prg fenix7 -t
```
Tests live in `source/*Test.mc` (e.g. `OpenWeatherServiceTest.mc`, `CelestialCalcTest.mc`) and are annotated with `(:test)`. Each test is a standalone function returning `Boolean`.

Note: Most of the code doesn't have tests; a lot of it is hard to test as mocking every Garmin API is not feasible. Use tests when writing complex logic that can be easily isolated.

## Development Workflow

Use red-green TDD: write a failing test first, verify it fails, then implement code to make it pass.

## Architecture

```
Segment34App.mc             – AppBase entry; schedules background temporal events (OWM polling)
Segment34View.mc            – Core watchface rendering (~1600 lines): update cycle, draw chain, layout, settings
Segment34WatchFaceDelegate.mc – Handles touch/press input; routes actions to the view
Segment34ServiceDelegate.mc – Background service; fires OWM fetch on temporal event
OpenWeatherService.mc       – HTTP requests to OpenWeatherMap API; runs in background context
OpenWeatherServiceTest.mc   – Unit tests for OWM code→Garmin condition mapping
CelestialCalcTest.mc        – Unit tests for Julian day and moon phase/illumination
DataHelper.mc               – Activity data and complications: steps, calories, heart rate, battery, etc.
ValueResolver.mc            – Resolves configurable field type codes to display strings and labels
WeatherDisplayHelper.mc     – Formats weather data for display (conditions, temperature, wind)
WeatherStorage.mc           – Reads/writes weather cache to Application.Storage
StoredWeather.mc            – Data class representing a weather snapshot
ThemeManager.mc             – Computes the active color theme based on settings and time of day
GraphRenderer.mc            – Histogram and line graph rendering (steps, calories, heart rate, etc.)
SunCalc.mc                  – Sunrise, sunset, dawn, and dusk calculations
DateTimeUtils.mc            – Date and time utility functions
FormatUtils.mc              – Number and string formatting helpers
resources/                  – English strings, settings schema (properties.xml/settings.xml), fonts, drawables
resources-{deu,fre,ita,pol,spa,swe}/ – Translated strings (6 languages, must stay in sync with English)
```

**Data flow:**
- Background service (`Segment34ServiceDelegate`) wakes hourly via `Background.registerForTemporalEvent`, calls `OpenWeatherService.fetchWeather()`, and writes results to `Application.Storage`.
- The foreground `Segment34View` reads from `Application.Storage` in `updateWeather()` to pick up new weather data without any direct cross-context communication.
- All user settings are read from `Application.Properties` once in `updateProperties()` and cached in `prop*` instance variables on the view.

**Update cycle in `onUpdate()`:**
- Full `computeDisplayValues()` runs every `propUpdateFreq` seconds (default 5 s).
- Slow path (once per minute): `updateColorTheme()` + `updateWeather()`.
- Sub-second seconds via `onPartialUpdate()` using `dc.setClip()` to redraw only the seconds area.
- Histogram data cached per-minute (`cachedHistogramData` / `lastHistogramMinute`) to avoid expensive `SensorHistory` iteration on every redraw.

## Key Conventions

### Device annotations & `monkey.jungle`
Each device is assigned to exactly one screen-size family. `monkey.jungle` specifies `excludeAnnotations` per device to compile only the correct variant. The annotation families are:

| Annotation | Screen size | Display |
|---|---|---|
| `Round260` | 260×260 | MIP |
| `Round280` | 280×280 | MIP |
| `Round390` | 390×390 | AMOLED |
| `Round416` | 416×416 | AMOLED |
| `Round454` | 454×454 | AMOLED |
| `Square`   | 448×486 | AMOLED (Venu X1) |

Additionally `MIP` and `AMOLED` annotations gate display-technology-specific code (e.g., burn-in protection, color depth). `background_excluded` marks code that must not be compiled into the background context; `background` marks code that runs only in the background.

Many methods—especially `loadResources()`—have one implementation per screen family, each annotated with the appropriate tag. When adding a new per-device variant, add the annotation to every overloaded method and the matching `excludeAnnotations` entry in `monkey.jungle`.

Annotations allow us to keep the memory footprint low by only including what we need for each device.

### Configurable field system
Every displayable field is controlled by a `*Shows` property (a `Number`). The numeric value is a type code passed to `getValueByType(typeCode, width)` which returns the formatted string to display. The relevant properties are:

- **Short fields** (space-constrained): `sunriseFieldShows`, `sunsetFieldShows`, `notificationCountShows`, `secondsShows`, `leftValueShows`, `middleValueShows`, `rightValueShows`, `fourthValueShows`, `bottomFieldShows`, `bottomField2Shows`, `aodRightFieldShows`
- **Shortest fields** (same as above but excluding `bottomFieldShows` and `bottomField2Shows`, the dedicated 5-digit slots)
- **Long fields** `weatherLine1Shows`, `weatherLine2Shows`, `dateFieldShows`, `aodFieldShows`

Labels for fields are resolved by `getLabelByType()` and cached in `strLabel*` vars; they are refreshed in `updateActiveLabels()` which is called from `updateProperties()`.

### Localization
When adding or changing user-visible strings, always update all seven files:
- `resources/strings/strings.xml` (English, source of truth)
- `resources-deu/`, `resources-fre/`, `resources-ita/`, `resources-pol/`, `resources-spa/`, `resources-swe/`

### Memory constraints
Memory is extremely limited, especially on older MIP devices. The `isLowMem` flag is set at runtime when free memory drops below 15 KB; when set, hourly forecast data is dropped from `Application.Storage` and not re-fetched until memory recovers. Apart from allocated variables, the bytecode itself also takes up memory. Extracting code used multiple times is one way to save memory.

### CPU constraints
CPU usage directly impacts battery life. Avoid unnecessary CPU cycles. Balance CPU and memory optimization carefully.

### Color theme system
`themeColors` is an array indexed by the `colorNames` enum (`bg`, `clock`, `clockBg`, `outline`, `dataVal`, `fieldBg`, `fieldLbl`, `date`, `dateDim`, `notif`, `stress`, `bodybatt`, `moon`, `lowBatt`). Always use these named indices rather than raw integers when reading or writing colors.

### Settings properties vs. runtime storage
- `Application.Properties` — user-visible settings defined in `resources/settings/properties.xml`. Read-only at runtime; loaded into `prop*` vars.
- `Application.Storage` — runtime key/value store used for OWM weather cache (`current_conditions`, `hourly_forecast`, `owm_last_update`, `owm_error`) and persistent counters (`dailyCounter`, etc.). This is the only channel between background and foreground contexts.

### Build performance & Monkey C type checker (`as Dictionary`)
Always annotate local dictionary literals with `as Dictionary` when keys are added conditionally or mutated across branches (e.g., `var cc_data = {} as Dictionary;`, `var values = {} as Dictionary;`).

Without `as Dictionary`, the Monkey C compiler (`FunctionTypeChecker` / `ControlFlowProcessor`) infers a structural `DictionaryType` and clones it on every `dict["key"] = val` assignment. Across $N$ sequential `if (...) { dict["k"] = v; }` statements, the control-flow join merges both branches into a `PolyType` union of $2^N$ distinct `DictionaryType` shapes and calls `DictionaryType.equals()` $O(4^N)$ times. Even a single untyped dictionary with ~12 conditional key assignments adds 3–5+ seconds per device build (and 15+ minutes when exporting all ~82 device variants).
