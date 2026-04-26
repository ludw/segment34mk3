# Segment34View Refactoring Plan

## Overview
Split `source/Segment34View.mc` (~3854 lines, one giant class) into focused files.
All new files go into `source/` (flat — Monkey C doesn't use subdirs in this project).
Goal: ~1800–2000 line view after all steps. No behavior changes. No large object passing.

**Reference files** (session folder):
- `files/view-global-state-analysis.md` — every function's reads/writes
- `files/view-refactoring-recommendation.md` — full rationale and design

**Build command (verify after every step):**
```
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
  -jar "/Users/ludvig.wadenstein/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.1.0-2026-03-09-6a872a80b/bin/monkeybrains.jar" \
  -o bin/Segment34mk3.prg -f monkey.jungle \
  -y /Users/ludvig.wadenstein/code/Garmin/developer_key \
  -d fenix847mm_sim -w
```

---

## Rules for every step
1. Read the relevant functions from the view *before* creating the new file.
2. Create the new file.
3. Delete the moved functions from `Segment34View.mc`.
4. Update any callers inside the view (add module prefix or pass params as needed).
5. Run the build. Fix errors. Do not proceed until clean.
6. Mark the todo done and update this plan.

---

## Steps

### Step 1 — `source/DateTimeUtils.mc` ✅ COMPLETE
**Functions to move** (all pure, no instance state):
- `dayName(day_of_week)` — reads `cachedDayOfWeek`/`cachedDayName` → move those two cache vars to module-level
- `monthName(month)` — reads `cachedMonth`/`cachedMonthName` → move those two cache vars to module-level
- `isoWeekNumber(year, month, day)` — reads `propWeekOffset` → add as parameter
- `julianDay(year, month, day)` — stateless
- `isLeapYear(year)` — stateless
- `formatHour(hour)` — stateless
- `formatDate()` — reads propDateFormat, propDateCustomFormat, propLabelVisibility, propWeekOffset → add as params
- `formatCustomDate(today)` — reads propWeekOffset → add as param
- `getDateTimeGroup()` — reads propIs24H → add as param
- `secondaryTimezone(offset, width)` — reads propIs24H, propHourFormat, propTzHourFormat → add as params

**State to move from View:**
- `cachedDayOfWeek`, `cachedDayName`, `cachedMonth`, `cachedMonthName` → module-level `var` in DateTimeUtils

**Callers to update in View:**
- `computeDisplayValues` calls `moonPhase` (stays), `getClockData` (stays)
- `formatDate`, `getDateTimeGroup`, `secondaryTimezone` called from `getValueByType` — prefix with module or just call directly (they'll be in same app scope)
- `dayName` called from `getGraphXLabel` and `formatDate`
- `isoWeekNumber` called from `formatDate`, `formatCustomDate`

**New file structure:**
```monkeyc
// Module-level cache vars
var _cachedDayOfWeek as Number = -1;
var _cachedDayName as String = "";
var _cachedMonth as Number = -1;
var _cachedMonthName as String = "";

function dayName(day_of_week as Number) as String { ... }
function monthName(month as Number) as String { ... }
function formatHour(hour as Number) as Number { ... }
function isoWeekNumber(year, month, day, weekOffset as Number) as Number { ... }
function julianDay(...) as Number { ... }
function isLeapYear(year) as Boolean { ... }
function formatDate(propDateFormat, propDateCustomFormat, propLabelVisibility, propWeekOffset) as String { ... }
function formatCustomDate(today, propWeekOffset) as String { ... }
function getDateTimeGroup(propIs24H) as String { ... }
function secondaryTimezone(offset, width, propIs24H, propHourFormat, propTzHourFormat) as String { ... }
```

**Estimated lines removed from View:** ~200
**Risk:** Low

---

### Step 2 — `source/FormatUtils.mc` (pure formatting utilities) ✅ COMPLETE
**Functions to move:**
- `formatTemperature(temp)` — reads propShowTempUnit, cachedTempUnit → add as params
- `convertTemperature(temp, unit)` — stateless
- `formatWindSpeed(mps)` — reads propWindUnit → add as param
- `formatPressure(pressureHpa, width)` — reads propPressureUnit → add as param
- `formatDistanceByWidth(distance, width)` — stateless
- `formatGraphAxisValue(val)` — stateless
- `goalPercent(val, goal)` — stateless
- `moonPhase(time)` — reads propHemisphere → add as param
- `formatLabel(short, mid, size)` — reads propFontSize → add as param
- `formatSunTime(s, width)` — stateless (calls formatHour from DateTimeUtils)
- `getCivilTwilight(lat_deg, sunrise, sunset)` — stateless (pure math)

**State to move:** none

**Callers to update in View:**
- Many callers throughout `getValueByType`, weather helpers, `computeDisplayValues`
- After moving, calls stay the same name (Monkey C resolves by name in scope)
- Only changes needed where params are added (formatTemperature, formatWindSpeed, etc.)

**Estimated lines removed from View:** ~150
**Risk:** Low

---

### Step 3 — `source/SunCalc.mc` (sun/twilight calculations) ✅ COMPLETE
**Functions to move:**
- `getNextSunEvent()` — reads `weatherCondition` → add as parameter
- `hoursToNextSunEvent()` — calls getNextSunEvent → add weatherCondition as param
- `formatSunTime(s, width)` — move here from FormatUtils if not already moved (calls formatHour)

**Note:** `getNextSunEvent` also called from `getNightModeValue` (theme) and `getValueByType`.
After move, callers pass `weatherCondition` explicitly.

**State to move:** none

**Estimated lines removed from View:** ~80
**Risk:** Low

---

### Step 4 — `source/ActivityDataHelper.mc` (activity & sensor data fetchers) ✅ COMPLETE
**Functions to move:**
- `getBarData(data_source)` — stateless (reads ActivityMonitor)
- `getStressData()` — stateless
- `getStressColor(val)` — stateless pure function
- `getBBData()` — stateless
- `goalPercent(val, goal)` — stateless (move here or FormatUtils, fits better here)
- `getStepGoalProgress()` — stateless
- `getFloorGoalProgress()` — stateless
- `getActMinGoalProgress()` — stateless
- `getMoveBar()` — stateless
- `getBattData()` — stateless (reads System.getSystemStats)
- `getRestCalories()` — stateless (reads UserProfile, Time)
- `getWeeklyDistance()` — stateless (reads ActivityMonitor.getHistory)
- `updateActivityDistCache()` — reads propIsMetricDistance; writes cachedRun/Bike/SwimDist*, lastActivityDistUpdate → move those vars here
- `getWeeklyDistanceFromComplication(isRun, convFactor, width)` — reads propIsMetricDistance → add as param

**State to move from View:**
- `cachedRunDist7Days`, `cachedBikeDist7Days`, `cachedSwimDist7Days`
- `cachedRunDistMonth`, `cachedRunDist28Days`, `lastActivityDistUpdate`

**Structure:** Module-level functions + module-level cache vars (no class needed).

**Callers to update in View:**
- `getValueByType` calls `updateActivityDistCache`, `getWeeklyDistanceFromComplication`, all goal helpers
- `drawSideBars` / `drawOneBar` calls `getBarData`, `getStressData`, `getStressColor`
- `drawBarGraph`, `drawLineGraph` call `getStressColor`

**Estimated lines removed from View:** ~220
**Risk:** Low-medium (cache var migration)

---

### Step 5 — `source/ComplicationHelper.mc` (CGM, Vo2, complication icons)
**Functions to move:**
- `getIconState(setting)` — stateless (reads System, ActivityMonitor, Complications)
- `getIconColor(setting)` — (:AMOLED) and (:MIP) variants
- `getIconCountOverlay(setting)` — stateless
- `getRecoveryTimeVal(numberFormat)` — stateless
- `getTrainingStatusVal()` — stateless
- `getCalendarEventVal(width)` — stateless
- `getPulseOxVal(numberFormat)` — stateless
- `getAltitudeValue()` — stateless
- `getCgmComplicationByLabel(targetLabel)` — stateless
- `convertCgmTrendToArrow(trend)` — stateless
- `getVo2Trend(key, currentVal)` — stateless (reads/writes Application.Storage)
- `getCgmReading()` — reads/writes `cgmComplicationId` → move var here
- `getCgmAge()` — reads/writes `cgmAgeComplicationId` → move var here
- `updateVo2History()` — writes `vo2RunTrend`, `vo2BikeTrend` → move vars here

**State to move from View:**
- `cgmComplicationId`, `cgmAgeComplicationId`, `vo2RunTrend`, `vo2BikeTrend`

**Structure:** A `ComplicationHelper` class (needs state), held as instance var on View.
```monkeyc
class ComplicationHelper {
    hidden var cgmComplicationId as Complications.Id? = null;
    hidden var cgmAgeComplicationId as Complications.Id? = null;
    var vo2RunTrend as String = "";
    var vo2BikeTrend as String = "";
    function initialize() { }
    function getCgmReading() as String { ... }
    ...
}
```
View holds: `hidden var complications as ComplicationHelper = new ComplicationHelper();`

**Callers to update in View:**
- `computeDisplayValues` calls getIconState, getIconColor, getIconCountOverlay
- `onUpdate` calls updateVo2History → becomes `complications.updateVo2History()`
- `getValueByType` calls getCgmReading, getCgmAge, getPulseOxVal, etc.

**Estimated lines removed from View:** ~200
**Risk:** Medium (introduces new class + instance var)

---

### Step 6 — `source/ThemeManager.mc` (color theme)
**Functions to move:**
- `setColorTheme(theme)` — (:MIP) and (:AMOLED) variants; reads propColorOverride, propColorOverride2; writes infoMessage
- `parseThemeString(override)` — calls setColorTheme
- `updateColorTheme()` — reads nightModeOverride, propNightTheme, nightMode, propTheme; writes themeColors, nightMode
- `getNightModeValue()` — reads propNightTheme, propNightTheme, propNightThemeActivation, weatherCondition

**State to move from View:**
- `themeColors` → becomes a field on ThemeManager, accessed as `theme.colors`
- `nightMode` → becomes a field on ThemeManager

**Structure:**
```monkeyc
class ThemeManager {
    var colors as Array<Graphics.ColorType> = [];
    hidden var _nightMode as Boolean? = null;

    function update(nightModeOverride as Number, propTheme, propNightTheme,
                    propNightThemeActivation, propColorOverride, propColorOverride2,
                    weatherCondition) as Void { ... }
    // setColorTheme, parseThemeString, getNightModeValue become private helpers
}
```
View holds: `hidden var theme as ThemeManager = new ThemeManager();`
All `themeColors[x]` reads become `theme.colors[x]`.

**Callers to update in View:**
- `updateColorTheme()` → `theme.update(nightModeOverride, propTheme, ...)`
- Every `themeColors[bg]` etc. reference in draw functions → `theme.colors[bg]`
  (this is the most widespread change — grep shows ~40 call sites)

**Estimated lines removed from View:** ~160
**Risk:** Medium-high (themeColors is referenced ~40 times in drawing code)

---

### Step 7 — `source/WeatherDisplayHelper.mc` (weather display formatting)
**Functions to move:**
- `getCityName()` — reads weatherCondition → add as param
- `getWeatherCondition()` — reads owmError, weatherCondition; writes infoMessage
- `getWeatherConditionShort()` — reads weatherCondition, owmError
- `getTemperature()` — reads weatherCondition, cachedTempUnit
- `getTempUnit()` — reads propTempUnit
- `getWind()` — reads weatherCondition; calls formatWindSpeed
- `getWindGust()` — reads weatherCondition; calls formatWindSpeed
- `getPrecipAmount()` — reads weatherCondition, propPrecipAmountUnit
- `getObservationTime()` — reads weatherCondition; calls formatHour
- `getFeelsLike()` — reads weatherCondition, cachedTempUnit
- `getHumidity()` — reads weatherCondition
- `getUVIndex()` — reads weatherCondition
- `getHighLow()` — reads weatherCondition, cachedTempUnit
- `getPrecip()` — reads weatherCondition
- `getWeatherByFormat(format)` — calls all of the above

**State:** weatherCondition + owmError stay on View (updated by updateWeather). Pass as params.

**Structure:** Module-level functions, each taking explicit params. `getWeatherByFormat` takes a small struct or explicit params for the weather values it might show.

Alternative (simpler): a `WeatherDisplayHelper` class initialized with the weather data once per update:
```monkeyc
class WeatherDisplayHelper {
    hidden var _w as StoredWeather or Null;
    hidden var _tempUnit as String;
    hidden var _propWindUnit as Number;
    hidden var _propPrecipAmountUnit as Number;
    hidden var _propShowTempUnit as Boolean;
    function initialize(w, tempUnit, windUnit, precipUnit, showTempUnit) { ... }
    function getTemperature() as String { ... }
    ...
}
```
Instantiated once in `computeDisplayValues` (stack, not heap — will be GC'd). No persistent memory cost.

**Callers to update in View:**
- `computeDisplayValues` creates a WeatherDisplayHelper, passes to `getValueByType` (or calls directly)
- `getNightModeValue` calls `getNextSunEvent` (already in SunCalc.mc by this point)

**Estimated lines removed from View:** ~300
**Risk:** Medium

---

### Step 8 — `source/GraphRenderer.mc` (graph subsystem)
**Functions to move:**
- `drawGraph(dc, data, data2, x, y, h)` — reads graph layout vars, propGraphData, propGraphStyle, etc.
- `drawBarGraph(dc, data, data2, ...)` — reads graphGoalLine, themeColors, propGraphData
- `drawLineGraph(dc, data, ...)` — reads cachedGraphYMax/Min, propGraphData, themeColors
- `formatGraphAxisValue(val)` — stateless (already in FormatUtils by Step 2)
- `getGraphXLabel(isLeft)` — reads propGraphData, propIs24H; calls dayName
- `getDataArrayByType(dataSource)` — reads propGraphData, propSmallFontVariant; writes cachedGraphYMin/Max, cachedGraphData2
- `getDailyDataArray(dataSource)` — reads propGraphData, propIsMetricDistance; writes graphGoalLine, cachedGraphYMin/Max, cachedGraphData2
- `getHistoryDayValue(dayInfo, dataSource)` — stateless
- `getTodayActivityValue(todayInfo, dataSource)` — stateless
- `downsampleGraph(data)` — reads graphTargetWidth → add as param

**State to move from View:**
- `graphGoalLine`, `cachedGraphYMin`, `cachedGraphYMax`
- `cachedGraphData2` (cachedGraphData stays on View as it's populated in computeDisplayValues)

**Structure:** `GraphRenderer` class; View holds it as `hidden var graphRenderer as GraphRenderer`.
Graph layout params (graphBarWidth, graphHeight, etc.) passed to `configure()` in `reloadSettings()`.

**Callers to update in View:**
- `computeDisplayValues` calls `getDataArrayByType` → `graphRenderer.getDataArrayByType(...)`
- `drawWatchface` calls `drawGraph` → `graphRenderer.drawGraph(...)`

**Estimated lines removed from View:** ~420
**Risk:** Medium (graph cache state migration)

---

### Step 9 — Internal refactor of `getValueByType` (prerequisite for Step 10)
**No new file.** This step makes Step 10 feasible by breaking `getValueByType` (344 lines)
into logical private sub-functions within the class:

Split into:
- `getActivityValue(typeCode, width)` — steps, floors, HR, activity, distance, calories types
- `getWeatherValue(typeCode, width)` — weather/sun/pressure types
- `getComplicationValue(typeCode, width)` — Garmin complication types (recovery, training status, etc.)
- `getClockValue(typeCode, width)` — time, date, timezone types

`getValueByType` becomes a dispatcher calling these four.

**Also:** Extract `getValueByTypeWithUnit`, `getUnitByType`, `getLabelByType`, `updateActiveLabels` — these are conceptually part of value resolution and should move with Step 10.

**Estimated lines changed:** 0 net (internal restructure only)
**Risk:** Medium (large function, many branches — test each type category)

---

### Step 10 — `source/ValueResolver.mc` (value + label dispatch)
**Functions to move** (after Step 9 splits them):
- `getValueByType(typeCode, width)` — the dispatcher
- `getActivityValue(typeCode, width)` — new sub-function from Step 9
- `getWeatherValue(typeCode, width)` — new sub-function from Step 9
- `getComplicationValue(typeCode, width)` — new sub-function from Step 9
- `getClockValue(typeCode, width)` — new sub-function from Step 9
- `getValueByTypeWithUnit(typeCode, width)` — thin wrapper
- `getUnitByType(typeCode)` — reads propTempUnit
- `getLabelByType(typeCode, labelSize)` — reads propTzName1/2, propIsMetricDistance
- `updateActiveLabels()` — reads all prop*Shows; writes strLabel* vars

**State to move from View:**
- `strLabelTopLeft`, `strLabelTopRight`, `strLabelBottomLeft`, `strLabelBottomMiddle`,
  `strLabelBottomRight`, `strLabelBottomFourth`
- `infoMessage` (written by getValueByType, read by computeDisplayValues)

**Structure:** `ValueResolver` class. Needs access to weather, complications, activity helpers.
Initialized in `reloadSettings()`, re-configured in `updateProperties()`.

**Callers to update in View:**
- `computeDisplayValues` calls getValueByType → `resolver.getValueByType(...)`
- `computeDisplayValues` reads strLabel* → `resolver.strLabel*`
- `onUpdate` checks `infoMessage` (if applicable) → `resolver.infoMessage`

**Estimated lines removed from View:** ~750
**Risk:** High (largest, most coupled function — do last, test thoroughly)

---

## Summary Table

| # | Todo ID | New File | ~Lines Removed | Risk |
|---|---|---|---|---|
| 1 | `refactor-datetime-utils` | `DateTimeUtils.mc` | 200 | Low |
| 2 | `refactor-format-utils` | `FormatUtils.mc` | 150 | Low | ✅ |
| 3 | `refactor-sun-calc` | `SunCalc.mc` | 80 | Low | ✅ |
| 4 | `refactor-activity-data` | `ActivityDataHelper.mc` | 220 | Low-med | ✅ |
| 5 | `refactor-complication-helper` | `ComplicationHelper.mc` | 200 | Medium |
| 6 | `refactor-theme-manager` | `ThemeManager.mc` | 160 | Med-high |
| 7 | `refactor-weather-display` | `WeatherDisplayHelper.mc` | 300 | Medium |
| 8 | `refactor-graph-renderer` | `GraphRenderer.mc` | 420 | Medium |
| 9 | `refactor-split-getvaluebtype` | (in-place) | 0 net | Medium |
| 10 | `refactor-value-resolver` | `ValueResolver.mc` | 750 | High |

**Total estimated reduction: ~2280 lines → view ends up ~1570 lines**
