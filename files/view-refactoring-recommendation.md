# Segment34View Refactoring Recommendation

## Problem Statement

`Segment34View.mc` is ~3854 lines and a single class handling: lifecycle, layout, rendering, theme management, weather data, graph subsystem, value resolution (700+ lines in `getValueByType` alone), date/time utilities, and activity data. Finding anything requires knowing where it lives, and adding features risks unintended interactions.

**Goals:** better structure, easier navigation, no large object passing (memory-safe), no behavioral changes.

**Constraint:** Monkey C does not support splitting a class across files, so the main `Segment34View` class must stay in one file. Helpers must be standalone functions or separate classes.

---

## Core Insight: Most State Is View-Private

The bulk of instance variables (`prop*`, layout vars, fonts) are read-only after `reloadSettings()` completes and are never passed across the system — they're only accessed locally within the view. This means we can't easily partition the state object, but we *can* move the functions that use it into helper files, accepting that they'll need key values passed as parameters when extracted.

For most helpers this is only 1–3 parameters, so no big objects are needed.

---

## Proposed File Structure

```
source/
  Segment34App.mc                 (unchanged)
  Segment34View.mc                (trimmed orchestrator — keep lifecycle, layout, rendering core)
  Segment34ServiceDelegate.mc     (unchanged)
  OpenWeatherService.mc           (unchanged)
  OpenWeatherServiceTest.mc       (unchanged)

  -- NEW FILES --
  theme/
    ThemeManager.mc               (color theme logic)

  weather/
    WeatherDisplay.mc             (weather formatting helpers)
    SunCalc.mc                    (sun event calculations)

  data/
    ValueResolver.mc              (getValueByType + getLabelByType dispatch)
    ActivityDataHelper.mc         (activity/sensor data fetchers)
    ComplicationHelper.mc         (icon state, CGM, Vo2, complications)

  graph/
    GraphRenderer.mc              (graph draw functions + data array fetchers)

  utils/
    DateTimeUtils.mc              (date/time formatting, dayName, monthName, etc.)
    FormatUtils.mc                (formatTemperature, formatWindSpeed, formatPressure, etc.)
```

---

## Extraction Plan (by module)

### 1. `utils/DateTimeUtils.mc` — Pure, no instance state

**Move:** `dayName`, `monthName`, `isoWeekNumber`, `julianDay`, `isLeapYear`, `formatHour`, `formatDate`, `formatCustomDate`, `getDateTimeGroup`, `secondaryTimezone`

**How:** Convert to module-level functions (no class). Pass the handful of prop values they need as parameters.

| Function | Parameters needed |
|---|---|
| `dayName(dow)` | none (already cached internally — move cache to module-level `var`) |
| `monthName(month)` | none (same) |
| `formatHour(hour)` | already stateless |
| `formatDate()` | propDateFormat, propDateCustomFormat, propLabelVisibility, propWeekOffset |
| `formatCustomDate(today)` | propWeekOffset |
| `getDateTimeGroup()` | propIs24H |
| `secondaryTimezone(offset, width)` | propIs24H, propHourFormat, propTzHourFormat |
| `isoWeekNumber(y,m,d)` | propWeekOffset |

**Memory impact:** Negligible — no new heap allocations, just moves bytecode. The module-level day/month cache variables replace two pairs of instance vars on `Segment34View`.

---

### 2. `utils/FormatUtils.mc` — Pure formatting, no instance state

**Move:** `formatTemperature`, `convertTemperature`, `formatWindSpeed`, `formatPressure`, `formatDistanceByWidth`, `formatGraphAxisValue`, `formatLabel`, `formatSunTime`, `moonPhase`, `goalPercent`

**How:** Module-level functions. Pass the 1–2 prop values each one needs.

| Function | Parameters needed |
|---|---|
| `formatTemperature(val)` | propShowTempUnit, cachedTempUnit |
| `convertTemperature(val, unit)` | already stateless |
| `formatWindSpeed(mps)` | propWindUnit |
| `formatPressure(hpa, width)` | propPressureUnit |
| `formatLabel(short, mid, size)` | propFontSize |
| `moonPhase(time)` | propHemisphere |

---

### 3. `weather/WeatherDisplay.mc` — Weather formatting helpers

**Move:** `getCityName`, `getWeatherCondition`, `getWeatherConditionShort`, `getTemperature`, `getTempUnit`, `getWind`, `getWindGust`, `getPrecipAmount`, `getObservationTime`, `getFeelsLike`, `getHumidity`, `getUVIndex`, `getHighLow`, `getPrecip`, `getWeatherByFormat`

**How:** A small class `WeatherDisplay` that holds a reference (not a copy) to the `StoredWeather` struct and the few prop values it needs (`propTempUnit`, `propWindUnit`, `propPrecipAmountUnit`, `propShowTempUnit`). Instantiated once per call to `computeDisplayValues` or kept as a view instance variable and refreshed in `updateWeather`.

**Memory impact:** One object with ~5 fields (all references or numbers). Acceptable. Because `weatherCondition` is already a reference type (`StoredWeather or Null`), no copying happens.

```monkeyc
class WeatherDisplay {
    hidden var _weather as StoredWeather or Null;
    hidden var _tempUnit as String;
    hidden var _propWindUnit as Number;
    // ... a few more props
    
    function initialize(weather, tempUnit, propWindUnit, ...) { ... }
    function getTemperature() as String { ... }
    // etc.
}
```

---

### 4. `weather/SunCalc.mc` — Sun / twilight calculations

**Move:** `getNextSunEvent`, `hoursToNextSunEvent`, `getCivilTwilight`, `formatSunTime`

**How:** Module-level functions. `getNextSunEvent` takes `weatherCondition` as a parameter (it already only reads from it). `hoursToNextSunEvent` becomes a thin wrapper. `getCivilTwilight` and `formatSunTime` are already stateless.

---

### 5. `theme/ThemeManager.mc` — Color/theme management

**Move:** `setColorTheme` (×2 annotated), `parseThemeString`, `updateColorTheme`, `getNightModeValue`, `getStressColor`

**How:** A `ThemeManager` class held as an instance var on the view. It owns `themeColors` and `nightMode`. It needs a reference to the view only for `getNightModeValue` (reads `weatherCondition` + several props). Consider making `getNightModeValue` take its needed values as parameters to break the back-reference.

```monkeyc
class ThemeManager {
    var colors as Array<Graphics.ColorType> = [];
    hidden var _nightMode as Boolean? = null;
    
    function update(nightModeOverride, propTheme, propNightTheme, ..., sunriseTime, sunsetTime) { ... }
    function getColors() as Array<Graphics.ColorType> { return colors; }
}
```

`drawWatchface` and all drawing functions currently read `themeColors` directly. With `ThemeManager`, they'd read `themeManager.colors` — essentially the same cost.

---

### 6. `graph/GraphRenderer.mc` — Graph drawing + data

**Move:** `drawGraph`, `drawBarGraph`, `drawLineGraph`, `formatGraphAxisValue`, `getGraphXLabel`, `getDataArrayByType`, `getDailyDataArray`, `getHistoryDayValue`, `getTodayActivityValue`, `downsampleGraph`

**Move cache vars:** `graphGoalLine`, `cachedGraphYMin`, `cachedGraphYMax` (become class fields on GraphRenderer)

**How:** A `GraphRenderer` class. It needs graph layout params (`graphBarWidth`, `graphBarSpacing`, `graphHeight`, `graphTargetWidth`, `graphHalfWidth`, `propGraphData`, `propGraphSize`, `propGraphStyle`, `propGraphAxisLabels`). These can be set once in `reloadSettings()`. The `cachedGraphData/cachedGraphData2` can stay on the view (they're populated in `computeDisplayValues` which already handles the minute-cache logic) or move to the renderer.

```monkeyc
class GraphRenderer {
    hidden var _graphHeight as Number;
    hidden var _propGraphData as Number;
    // ... other layout/prop params set at init

    var goalLine as Number? = null;  // written by getDailyDataArray
    var yMin as Float = 0.0;
    var yMax as Float = 100.0;

    function configure(graphHeight, propGraphData, ...) { ... }
    function drawGraph(dc, data, data2, x, y, h) { ... }
    function getDataArrayByType(source) { ... }
    function getDailyDataArray(source) { ... }
}
```

---

### 7. `data/ValueResolver.mc` — Value and label dispatch

`getValueByType` is 344 lines. It's the hardest to move because it touches ~20 instance variables and calls ~20 helpers. However, it's also the most valuable to isolate for readability.

**Approach:** Move `getValueByType`, `getValueByTypeWithUnit`, `getUnitByType`, `getLabelByType`, `updateActiveLabels` to a `ValueResolver` class. The class holds references to the helpers it needs (`WeatherDisplay`, `GraphRenderer`, etc.) plus the prop values it reads, all set once after `updateProperties()`.

Because `getValueByType` also writes `lastActivityDistUpdate` and `infoMessage`, those would need to either:
- Stay on the view and be passed by reference (not supported in Monkey C for scalars)
- Become fields on the ValueResolver

**Recommended:** Move `lastActivityDistUpdate`, `infoMessage`, and the `cached*Dist*` vars to `ValueResolver`. The view accesses `infoMessage` only through `computeDisplayValues`, which already builds the full values dictionary — clean handoff.

---

### 8. `data/ActivityDataHelper.mc` — Activity/sensor data

**Move:** `getBarData`, `getStressData`, `getBBData`, `goalPercent`, `getStepGoalProgress`, `getFloorGoalProgress`, `getActMinGoalProgress`, `getMoveBar`, `getWeeklyDistance`, `updateActivityDistCache`, `getWeeklyDistanceFromComplication`, `getBattData`, `getRestCalories`

**How:** Module-level functions or a lightweight static class. All are essentially stateless except `updateActivityDistCache` (writes the cached*Dist* vars). Those cache vars move here.

---

### 9. `data/ComplicationHelper.mc` — CGM, Vo2, complications

**Move:** `getIconState`, `getIconColor` (×2), `getIconCountOverlay`, `getCgmReading`, `getCgmAge`, `getCgmComplicationByLabel`, `convertCgmTrendToArrow`, `getVo2Trend`, `updateVo2History`, `getAltitudeValue`, `getRecoveryTimeVal`, `getTrainingStatusVal`, `getCalendarEventVal`, `getPulseOxVal`

**Move state vars:** `cgmComplicationId`, `cgmAgeComplicationId`, `vo2RunTrend`, `vo2BikeTrend`

**How:** A `ComplicationHelper` class. Holds the CGM/Vo2 state. Replaces 4 instance vars on the view.

---

## What Stays in `Segment34View.mc`

After extraction, the view file would contain:

1. **All `prop*` instance variables** (they are tightly coupled to the update cycle and too numerous to split cleanly)
2. **All layout/geometry instance variables** (same reason)
3. **Font instance variables** (device-specific, referenced throughout drawing)
4. **Lifecycle functions:** `initialize`, `onLayout`, `onShow`, `onHide`, `onUpdate`, `onExitSleep`, `onEnterSleep`, `onSettingsChanged`, `forceDataRefresh`, `onPartialUpdate`, `reloadSettings`
5. **Settings loading:** `updateProperties`, `loadBottomField2Property` (×2)
6. **Resource loading:** `loadResources` (×6), `loadFontVariant`, `loadAODGraphics`
7. **Layout calculation:** `calculateLayout`, `calculateBarLimits`, `calculateFieldXCoords`, `calculateSquareLayout` (×2)
8. **Core rendering:** `drawWatchface`, `drawAOD` (×2), `drawPattern`, `drawDataField`, `drawSideBars`, `drawOneBar`, `drawMoveBarTicks`, `drawBatteryIcon` (×2), `drawBottomFieldsWithIcons` (×2), `drawIconWithOverlay`, `computeDisplayValues`

Estimated size after extraction: **~1800–2000 lines** (down from 3854).

---

## What Does NOT Move

- `Segment34InputDelegate` — already at the bottom of the file, a separate class; leave it there or split to its own file as a cosmetic improvement
- The `colorNames` enum — referenced everywhere, keep in view or in a shared constants file
- `barWidth` constants — annotation-based, keep in view

---

## Recommended Extraction Order

Do these in sequence to minimize risk:

1. **`utils/DateTimeUtils.mc`** — pure functions, no risk, immediate line-count win (~200 lines)
2. **`utils/FormatUtils.mc`** — pure functions (~100 lines)
3. **`weather/SunCalc.mc`** — stateless (~130 lines)
4. **`data/ActivityDataHelper.mc`** — mostly stateless (~200 lines)
5. **`data/ComplicationHelper.mc`** — moves 4 state vars (~150 lines)
6. **`theme/ThemeManager.mc`** — moves `themeColors` + `nightMode` (~150 lines)
7. **`weather/WeatherDisplay.mc`** — moves weather formatting (~300 lines)
8. **`graph/GraphRenderer.mc`** — moves graph cache vars (~400 lines)
9. **`data/ValueResolver.mc`** — largest and most coupled, do last (~700 lines)

Build-check after each step to catch any missed references.

---

## Memory Impact Assessment

| Change | Memory delta |
|---|---|
| Module-level functions (utils) | Neutral — bytecode moves but total size same |
| Helper classes (WeatherDisplay, ThemeManager, etc.) | +1 object header per class instance (~8–16 bytes each) |
| Removing 4 CGM/Vo2 vars from view | Neutral (move to ComplicationHelper) |
| Removing graph cache vars from view | Neutral (move to GraphRenderer) |
| Removing cached*Dist* vars from view | Neutral (move to ActivityDataHelper) |

**Net memory change: effectively zero.** No data is duplicated, only reorganized. References to shared objects (like `weatherCondition`) stay as references. The extra class-instance headers are negligible (<100 bytes total).

---

## Additional Observations

- **`getValueByType` (344 lines)** is the single biggest readability problem. Even just adding section comments and splitting its `switch` into logical `getActivityValue()`, `getWeatherValue()`, `getComplicationValue()` sub-functions within the same class would help enormously before a full extraction.
- **Annotations (`(:Round390)` etc.)** must be preserved on any moved function that has per-device variants. Check carefully for `loadResources`, `drawBatteryIcon`, `setColorTheme`, `getIconColor`, `drawAOD`, `drawBottomFieldsWithIcons`, and the Square-only bottom-field functions.
- **`monkey.jungle`** does not need changes — annotations, not file paths, control compilation.
- The `(:background_excluded)` annotation on the whole `Segment34View` class applies at the class level; new helper classes default to being included everywhere unless annotated otherwise.
