## Plan: Bottom Field Mini Graph

### Overview
Add graph data source options (values 100–110) to the `bottomFieldShows` and `bottomField2Shows` settings. When a graph code is selected, render a mini bar graph in place of the 5-digit text field, using a second `GraphRenderer` instance configured for 1px bars, no axis lines/labels, and dimensions matching the 5-digit field.

### Key finding: GraphRenderer is already reusable
`GraphRenderer` is a standalone class configured via `configure()`. A second instance with different params works without modification. The only refactoring needed is moving the per-minute data caching **into** GraphRenderer (currently duplicated as view-level vars), which eliminates caching duplication for both the top and bottom graphs.

### Changes by file

**1. `GraphRenderer.mc` — Add internal caching (refactoring)**
- Add `_cachedData`, `_cachedDataSource`, `_cachedMinute` instance vars
- Add `getCachedDataArray(dataSource, currentMinute)` — fetches data once per minute, returns cached array otherwise
- Add `clearCache()` — resets cache (called on settings change)

**2. `Segment34View.mc` — Core integration**

*New instances & helpers:*
- `bottomGraphRenderer as GraphRenderer` (all devices)
- `(:Square) bottomGraphRenderer2 as GraphRenderer` (Square only, for second field)
- Module-level `isGraphCode(code)` → true if 100 ≤ code ≤ 110
- Module-level `graphCodeToDataSource(code)` → `code - 100` (maps 100→0, 101→1, … 110→10)

*Remove old caching vars:* `cachedGraphData`, `cachedGraphDataSource`, `lastGraphMinute` — replaced by `graphRenderer.getCachedDataArray()`

*`reloadSettings()` (after `loadResources()`):*
- Configure `bottomGraphRenderer` with: barWidth=1, barSpacing=1, targetWidth = `bottomDataWidth * 5 / 2`, halfWidth = `bottomDataWidth * 5 / 2`, style=0 (bars), no axis labels, data source from `propBottomFieldShows` if graph code
- Same for `bottomGraphRenderer2` (Square) with `propBottomField2Shows`
- Call `clearCache()` on all renderers instead of `cachedGraphData = null`

*`computeDisplayValues()`:*
- If `isGraphCode(propBottomFieldShows)`: fetch graph data via `bottomGraphRenderer.getCachedDataArray()`, store in `values[:dataBottomGraph]` / `values[:dataBottomGraph2b]`; set `values[:dataBottom] = ""`
- Else: existing behavior (text value)
- `computeBottomField2Values()` (Square): same logic for second field

*`drawBottomFieldsWithIcons()` (both Round & Square variants):*
- If field is a graph code: call `bottomGraphRenderer.drawGraph(dc, data, data2, fieldCenterX, bottomFiveY, largeDataHeight, theme.colors)` instead of `drawDataField()`
- Set `step_width = bottomDataWidth * 5` for icon positioning (same as text field)
- Icons still drawn flanking the graph
- Skip labels for graph fields (Square dual mode)
- Skip data background (`propShowDataBg`) for graph fields

*`calculateSquareLayout()` (Square):*
- Only shift `bottomFiveY` down for labels if at least one field is a non-graph field

**3. `settings.xml` — Add graph options to both dropdowns**
Add 11 entries (values 100–110) to `bottomFieldShows` and `bottomField2Shows`, reusing existing string resources:
- 100: `settings_body_battery_history`
- 101: `settings_elevation_history`
- 102: `settings_heart_rate_history`
- 103: `settings_oxygen_saturation_history`
- 104: `settings_pressure_history`
- 105: `settings_stress_history`
- 106: `settings_temperature_sensor_history`
- 107: `settings_stress_rest_orange_blue`
- 108: `settings_daily_distance_7d`
- 109: `settings_daily_steps_7d`
- 110: `settings_daily_active_minutes_7d`

**4. No localization changes needed** — all graph strings already exist in all 7 language files.

### TDD approach
1. Write tests for `isGraphCode()` and `graphCodeToDataSource()` in `OpenWeatherServiceTest.mc` (or a new test file)
2. Verify they fail
3. Implement the two helper functions
4. Verify tests pass
5. Implement the rest (integration code — not easily unit-testable due to Graphics/SensorHistory dependencies)
6. Build with the monkeyc command to type-check

### Edge cases handled
- **Daily data (7 bars):** GraphRenderer's existing `_propGraphData >= 8` logic overrides bar width to fill the field — wider bars, not 1px. Works correctly.
- **Both top and bottom graphs same data:** Each renderer has independent cache. Double SensorHistory iteration once per minute — minimal CPU impact.
- **Square dual mode with both fields as graphs:** Two mini graphs side by side, each with own renderer.
- **Goal line:** Kept for step data (useful, not an axis line).
- **AOD mode (`propAodStyle == 2`):** Graph drawn in full watchface AOD — 1px bars are burn-in-safe.
