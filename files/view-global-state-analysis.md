# Segment34View.mc — Global State Analysis

Generated 2026-04-26. Source file: `source/Segment34View.mc` (3854 lines).

---

## Instance Variables (Global State)

### Screen geometry & layout (set in initialize / loadResources / calculateLayout)
| Variable | Type | Set by | Read by (summarized) |
|---|---|---|---|
| `screenHeight` | Number | initialize | drawing, loadResources, calculateBarLimits, drawBatteryIcon |
| `screenWidth` | Number | initialize | loadResources, calculateBarLimits, drawPattern, drawBottomFieldsWithIcons |
| `centerX` | Number | initialize | loadResources, calculateBarLimits, drawSideBars, drawBottomFieldsWithIcons |
| `centerY` | Number | initialize | loadResources, calculateBarLimits, calculateLayout |
| `marginX` | Number | initialize | drawWatchface, drawBottomFieldsWithIcons |
| `marginY` | Number | loadResources | calculateLayout, onPartialUpdate, drawWatchface, drawAOD |
| `halfMarginY` | Number | reloadSettings | calculateLayout, drawWatchface |
| `clockHeight` | Number | loadResources | reloadSettings, calculateLayout, calculateBarLimits, drawWatchface, drawAOD |
| `clockWidth` | Number | loadResources | reloadSettings, calculateBarLimits, drawSideBars, drawAOD |
| `halfClockHeight` | Number | reloadSettings | calculateBarLimits, onPartialUpdate, drawWatchface, drawOneBar, drawMoveBarTicks |
| `halfClockWidth` | Number | reloadSettings | calculateBarLimits, drawSideBars, drawAOD, onPartialUpdate |
| `labelHeight` | Number | loadResources | calculateLayout, drawWatchface, drawDataField, calculateSquareLayout |
| `labelMargin` | Number | loadResources | calculateLayout, drawDataField, calculateSquareLayout |
| `tinyDataHeight` | Number | loadResources | calculateLayout, drawWatchface |
| `smallDataHeight` | Number | loadResources | calculateLayout, onPartialUpdate, drawWatchface |
| `largeDataHeight` | Number | loadResources | calculateLayout, drawWatchface, drawBottomFieldsWithIcons |
| `largeDataWidth` | Number | loadResources | calculateLayout |
| `bottomDataWidth` | Number | loadResources | calculateLayout, calculateSquareLayout |
| `baseX` | Number | loadResources | drawWatchface, drawAOD |
| `baseY` | Number | loadResources | calculateLayout, calculateBarLimits, onPartialUpdate, drawWatchface, drawOneBar, drawMoveBarTicks |
| `aboveLine2Adjustment` | Number | loadResources | drawWatchface |
| `barBottomAdj` | Number | loadResources | calculateBarLimits, drawOneBar, drawMoveBarTicks |
| `bottomFiveAdj` | Number | loadResources | calculateLayout |
| `fieldSpaceingAdj` | Number | loadResources | calculateLayout |
| `textSideAdj` | Number | loadResources | onPartialUpdate, drawWatchface, drawAOD |
| `secondsClipWidth` | Number | loadResources | onPartialUpdate |
| `iconYAdj` | Number | (initialized) | drawBottomFieldsWithIcons |
| `fieldXCoords` | Array<Number> | calculateFieldXCoords | drawWatchface |
| `fieldY` | Number | calculateLayout | drawWatchface |
| `bottomFiveY` | Number | calculateLayout | drawWatchface, drawBottomFieldsWithIcons, calculateSquareLayout |
| `bottomFive1X` | Number (Square) | calculateSquareLayout | drawBottomFieldsWithIcons |
| `bottomFive2X` | Number (Square) | calculateSquareLayout | drawBottomFieldsWithIcons |
| `dualBottomFieldActive` | Boolean (Square) | calculateSquareLayout | drawBottomFieldsWithIcons |
| `bottomFiveYOriginal` | Number (Square) | calculateSquareLayout | drawBottomFieldsWithIcons |
| `actualBarWidth` | Number | calculateBarLimits | drawSideBars, drawOneBar, drawMoveBarTicks |
| `maxSideBarHeight` | Number | calculateBarLimits | drawOneBar, drawMoveBarTicks, drawWatchface |
| `bottomFieldWidths` | Array<Number> | loadResources | getFieldWidths |

### Fonts (set in loadResources)
| Variable | Set by | Read by |
|---|---|---|
| `fontMoon` | reloadSettings (if propTopPartShows==0) | drawWatchface |
| `fontIcons` | initialize | drawPattern, drawBatteryIcon |
| `fontClock` | loadResources | drawWatchface, drawAOD |
| `fontClockOutline` | loadResources (AMOLED only) | drawWatchface, drawAOD |
| `fontLabel` | loadResources | drawWatchface, drawBatteryIcon, drawBottomFieldsWithIcons, drawDataField |
| `fontTinyData` | loadResources | drawWatchface |
| `fontSmallData` | loadResources | drawWatchface, onPartialUpdate |
| `fontAODData` | loadResources | drawAOD |
| `fontBottomData` | loadResources | drawWatchface, drawBottomFieldsWithIcons |
| `fontBattery` | loadResources | drawBatteryIcon |

### Resources/graphics
| Variable | Set by | Read by |
|---|---|---|
| `drawGradient` | loadAODGraphics | drawWatchface |
| `drawAODPattern` | loadAODGraphics | drawWatchface, drawAOD |

### Graph cache
| Variable | Set by | Read by |
|---|---|---|
| `cachedGraphData` | computeDisplayValues, updateProperties | computeDisplayValues, drawGraph (via values dict) |
| `cachedGraphData2` | computeDisplayValues, getDataArrayByType | computeDisplayValues, drawGraph |
| `cachedGraphDataSource` | computeDisplayValues | computeDisplayValues |
| `lastGraphMinute` | computeDisplayValues | computeDisplayValues |
| `graphBarWidth` | loadResources | drawGraph |
| `graphBarSpacing` | loadResources | drawGraph |
| `graphHeight` | loadResources | drawWatchface, drawGraph |
| `graphTargetWidth` | loadResources | drawGraph, downsampleGraph |
| `graphHalfWidth` | loadResources | drawGraph |
| `graphGoalLine` | getDailyDataArray | drawBarGraph |
| `cachedGraphYMin` | getDataArrayByType, getDailyDataArray | drawLineGraph |
| `cachedGraphYMax` | getDataArrayByType, getDailyDataArray | drawLineGraph |

### Theme & color
| Variable | Set by | Read by |
|---|---|---|
| `themeColors` | updateColorTheme | drawWatchface, drawAOD, drawDataField, drawOneBar, drawMoveBarTicks, drawBarGraph, drawLineGraph, drawBatteryIcon, drawBottomFieldsWithIcons, drawIconWithOverlay, onPartialUpdate |
| `nightMode` | updateColorTheme, updateProperties | updateColorTheme |
| `nightModeOverride` | handlePress | updateColorTheme |

### Weather state
| Variable | Set by | Read by |
|---|---|---|
| `weatherCondition` | updateWeather | getNightModeValue, getCityName, getWeatherCondition, getWeatherConditionShort, getTemperature, getWind, getWindGust, getPrecipAmount, getObservationTime, getFeelsLike, getHumidity, getUVIndex, getHighLow, getPrecip, getNextSunEvent |
| `owmError` | updateWeather | getWeatherCondition, getWeatherConditionShort |
| `cachedTempUnit` | updateWeather (via getTempUnit) | getTemperature, formatTemperature, getFeelsLike, getHighLow, getValueByType |
| `lastHfTime` | storeWeatherData | storeWeatherData |
| `lastCcHash` | storeWeatherData | storeWeatherData |
| `isLowMem` | storeWeatherData | storeWeatherData |

### Activity distance cache
| Variable | Set by | Read by |
|---|---|---|
| `cachedRunDist7Days` | updateActivityDistCache | getValueByType |
| `cachedBikeDist7Days` | updateActivityDistCache | getValueByType |
| `cachedSwimDist7Days` | updateActivityDistCache | getValueByType |
| `cachedRunDistMonth` | updateActivityDistCache | getValueByType |
| `cachedRunDist28Days` | updateActivityDistCache | getValueByType |
| `lastActivityDistUpdate` | updateActivityDistCache, getValueByType | updateActivityDistCache, getValueByType |

### Update cycle / sleep state
| Variable | Set by | Read by |
|---|---|---|
| `visible` | onShow, onHide | onUpdate |
| `isSleeping` | onEnterSleep, onExitSleep | onUpdate, getValueForSeconds |
| `canBurnIn` | initialize | onPartialUpdate, onUpdate, getValueForSeconds |
| `doesPartialUpdate` | onUpdate, onPartialUpdate | onUpdate |
| `lastUpdate` | onShow, onExitSleep, onEnterSleep, onSettingsChanged, forceDataRefresh | onUpdate |
| `lastSlowUpdate` | onShow, onExitSleep, onEnterSleep, onSettingsChanged, onUpdate | onUpdate |
| `cachedValues` | onUpdate | onUpdate (passed to draw functions) |

### CGM / Vo2
| Variable | Set by | Read by |
|---|---|---|
| `cgmComplicationId` | getCgmReading | getCgmReading |
| `cgmAgeComplicationId` | getCgmAge | getCgmAge |
| `vo2RunTrend` | updateVo2History | getVo2Trend (via updateVo2History) |
| `vo2BikeTrend` | updateVo2History | getVo2Trend (via updateVo2History) |

### Day/month name cache
| Variable | Set by | Read by |
|---|---|---|
| `cachedDayOfWeek` | dayName | dayName |
| `cachedDayName` | dayName | dayName |
| `cachedMonth` | monthName | monthName |
| `cachedMonthName` | monthName | monthName |

### Misc public/shared state
| Variable | Set by | Read by |
|---|---|---|
| `infoMessage` | computeDisplayValues, setColorTheme, getWeatherCondition, getValueByType, handlePress | computeDisplayValues |
| `clockBgText` | updateProperties | reloadSettings, drawWatchface |
| `hrHistoryData` | (declared, usage unclear) | — |

### Cached labels
All set by `updateActiveLabels`, read by `computeDisplayValues`:
`strLabelTopLeft`, `strLabelTopRight`, `strLabelBottomLeft`, `strLabelBottomMiddle`, `strLabelBottomRight`, `strLabelBottomFourth`

---

## Function Summary Table

| Function | Annotation | Lines | Writes (vars) | Reads (vars) | Ext APIs | Calls |
|---|---|---|---|---|---|---|
| `initialize` | | 231–244 | canBurnIn, screenHeight, screenWidth, fontIcons, centerX, centerY, marginY, marginX | — | System.getDeviceSettings, Application.loadResource | reloadSettings |
| `reloadSettings` | hidden | 246–267 | fontMoon, halfClockHeight, halfClockWidth, halfMarginY | propTopPartShows, clockHeight, clockWidth, clockBgText | Application.loadResource | updateProperties, loadResources, calculateLayout, calculateBarLimits, updateWeather |
| `updateActiveLabels` | hidden | 269–284 | strLabelTopLeft..Fourth | prop*Shows, propFontSize | — | getLabelByType, getFieldWidths |
| `loadFontVariant` | hidden | 286–294 | — | variant param | Application.loadResource | — |
| `loadAODGraphics` | hidden | 296–310 | drawGradient, drawAODPattern | propClockGradientOverlay | Application.loadResource | — |
| `loadResources` | :Round260 | 312–372 | fonts, layout vars | propClockFont, propFontSize, propGraphSize, centerX/Y, screenWidth | Application.loadResource | loadFontVariant |
| `loadResources` | :Round280 | 374–430 | fonts, layout vars | propClockFont, propFontSize, propGraphSize, centerX/Y, screenWidth | Application.loadResource | loadFontVariant |
| `loadResources` | :Round390 | 432–488 | fonts, layout vars | propClockFont, propFontSize, propGraphSize, centerX/Y, screenWidth | Application.loadResource | loadFontVariant, loadAODGraphics |
| `loadResources` | :Round416 | 490–546 | fonts, layout vars | propClockFont, propFontSize, propGraphSize, centerX/Y, screenWidth | Application.loadResource | loadFontVariant, loadAODGraphics |
| `loadResources` | :Round454 | 548–606 | fonts, layout vars | propClockFont, propFontSize, propGraphSize, centerX/Y, screenWidth | Application.loadResource | loadFontVariant, loadAODGraphics |
| `loadResources` | :Square | 608–666 | fonts, layout vars | propClockFont, propFontSize, propGraphSize, centerX/Y, screenWidth | Application.loadResource | loadFontVariant, loadAODGraphics |
| `computeDisplayValues` | hidden | 668–732 | cachedGraphData, cachedGraphData2, cachedGraphDataSource, lastGraphMinute, infoMessage | all prop*Shows, prop*BarShows, all strLabel*, isSleeping | — | getClockData, moonPhase, getDataArrayByType, getFieldWidths, getValueByType, getIconState, getIconCountOverlay, getIconColor, getBattData, getValueForSeconds, computeBottomField2Values |
| `onLayout` | | 735–736 | — | — | — | — |
| `onShow` | | 741–745 | visible, lastUpdate, lastSlowUpdate | — | — | — |
| `onUpdate` | | 748–780 | doesPartialUpdate, lastSlowUpdate, lastUpdate, cachedValues | visible, propUpdateFreq, isSleeping, canBurnIn, doesPartialUpdate | Time.now/Gregorian.info | updateColorTheme, updateWeather, updateVo2History, computeDisplayValues, drawAOD, drawWatchface |
| `onHide` | | 785–787 | visible | — | — | — |
| `onExitSleep` | | 790–795 | lastUpdate, lastSlowUpdate, isSleeping | — | WatchUi.requestUpdate | — |
| `onEnterSleep` | | 798–803 | lastUpdate, lastSlowUpdate, isSleeping | — | WatchUi.requestUpdate | — |
| `onSettingsChanged` | | 805–810 | lastUpdate, lastSlowUpdate | — | WatchUi.requestUpdate | reloadSettings |
| `forceDataRefresh` | public | 812–814 | lastUpdate | — | — | — |
| `onPartialUpdate` | | 816–832 | doesPartialUpdate | canBurnIn, propAlwaysShowSeconds, baseY, halfClockHeight, marginY, halfClockWidth, textSideAdj, secondsClipWidth, smallDataHeight, themeColors, fontSmallData | Time.now/Gregorian.info | — |
| `calculateBarLimits` | hidden | 834–856 | maxSideBarHeight, actualBarWidth | propSideBarWidth, screenWidth, screenHeight, halfClockWidth, baseY, halfClockHeight, barBottomAdj, centerY | — | — |
| `calculateLayout` | hidden | 858–873 | fieldY, bottomFiveY | baseY, halfClockHeight, marginY, smallDataHeight, labelHeight, largeDataHeight, centerY, screenWidth, fieldSpaceingAdj, bottomFiveAdj, propLabelVisibility | — | calculateFieldXCoords, calculateSquareLayout |
| `calculateFieldXCoords` | hidden | 875–892 | fieldXCoords | (param) | — | getFieldWidths |
| `drawWatchface` | hidden | 894–1036 | — (reads only, writes via dc) | themeColors, fonts, layout vars, prop* | Graphics dc | drawGraph, getFieldWidths, drawDataField, drawBottomFieldsWithIcons, drawSideBars, drawBatteryIcon |
| `drawAOD` | :MIP | 1038–1039 | — | — | — | — |
| `drawAOD` | :AMOLED | 1042–1086 | — | propAodStyle, propClockOutlineStyle, baseX, themeColors, fonts, layout vars, propAodAlignment | Graphics dc | drawPattern |
| `drawPattern` | :AMOLED | 1089–1104 | — | screenWidth, screenHeight, propClockGradientOverlay, fontIcons | Graphics dc | — |
| `getFieldWidths` | hidden | 1106–1142 | — | propFieldLayout | — | — |
| `drawDataField` | hidden | 1144–1185 | — | screenHeight, propLabelVisibility, propBottomFieldLabelAlignment, propShowDataBg, propBottomFieldAlignment, themeColors, labelHeight, labelMargin | Graphics dc | — |
| `drawSideBars` | hidden | 1187–1204 | — | actualBarWidth, centerX, halfClockWidth, barWidth, propLeftBarShows, propStressDynamicColor, propRightBarShows | — | drawOneBar |
| `drawOneBar` | hidden | 1213–1235 | — | actualBarWidth, baseY, halfClockHeight, barBottomAdj, maxSideBarHeight, propLimitBarHeight, themeColors | Graphics dc | getStressColor, drawMoveBarTicks |
| `drawMoveBarTicks` | hidden | 1237–1252 | — | actualBarWidth, baseY, halfClockHeight, barBottomAdj, maxSideBarHeight, themeColors | Graphics dc | — |
| `drawGraph` | hidden | 1254–1281 | — | propGraphAxisLabels, propGraphData, graphHalfWidth, propGraphStyle, graphBarWidth, graphBarSpacing, graphHeight, graphTargetWidth | — | downsampleGraph, drawLineGraph, drawBarGraph |
| `drawBarGraph` | hidden | 1283–1320 | — | graphGoalLine, themeColors, propGraphData | Graphics dc | getStressColor |
| `drawLineGraph` | hidden | 1322–1372 | — | propGraphAxisLabels, cachedGraphYMax, cachedGraphYMin, propGraphStyle, propGraphData, themeColors | Graphics dc | formatGraphAxisValue, getGraphXLabel, getStressColor |
| `formatGraphAxisValue` | hidden | 1375–1384 | — | — | — | — |
| `getGraphXLabel` | hidden | 1388–1408 | — | propGraphData, propIs24H | Time.now/Gregorian.info | dayName |
| `drawBatteryIcon` | :AMOLED | 1411–1444 | — | propBatteryVariant, propFontSize, propBottomFieldShows, propBottomField2Shows, screenHeight, fontIcons, themeColors | System.getSystemStats, Graphics dc | getBattData |
| `drawBatteryIcon` | :MIP | 1446–1473 | — | propBatteryVariant, propFontSize, propBottomFieldShows, propBottomField2Shows, screenHeight, fontLabel, themeColors | System.getSystemStats, Graphics dc | getBattData |
| `setColorTheme` | :MIP | 1485–1515 | infoMessage | propColorOverride, propColorOverride2 | — | parseThemeString |
| `setColorTheme` | :AMOLED | 1518–1548 | infoMessage | propColorOverride, propColorOverride2 | — | parseThemeString |
| `parseThemeString` | hidden | 1550–1573 | — | — | — | setColorTheme |
| `updateColorTheme` | hidden | 1575–1588 | themeColors, nightMode | nightModeOverride, propNightTheme, nightMode, propTheme | — | getNightModeValue, setColorTheme |
| `getNightModeValue` | hidden | 1590–1630 | — | propNightTheme, propTheme, propNightThemeActivation, weatherCondition | Time.now, Time.today, UserProfile.getProfile | getNextSunEvent |
| `updateProperties` | hidden | 1632–1730 | all prop*, nightMode, clockBgText | — | Application.Properties.getValue, System.getDeviceSettings | loadBottomField2Property, updateColorTheme, updateActiveLabels |
| `getAltitudeValue` | hidden | 1732–1738 | — | — | Complications.getComplication | — |
| `getValueForSeconds` | hidden | 1740–1750 | — | propSecondsShows, isSleeping, propAlwaysShowSeconds, canBurnIn | — | getValueByType |
| `getClockData` | hidden | 1752–1767 | — | propTimeSeparator, propZeropadHour, propIs24H | — | formatHour |
| `getIconState` | hidden | 1769–1821 | — | — | System.getDeviceSettings, ActivityMonitor.getInfo, Complications.getComplication | — |
| `getIconColor` | :AMOLED | 1824–1857 | — | — | Complications.getComplication | — |
| `getIconColor` | :MIP | 1859–1860 | — | — | — | — |
| `getIconCountOverlay` | hidden | 1862–1896 | — | — | System.getDeviceSettings, Complications.getComplication, Application.Storage.getValue | — |
| `getBarData` | hidden | 1879–1893 | — | — | ActivityMonitor.getInfo | — |
| `getStressData` | hidden | 1896–1906 | — | — | ActivityMonitor.getInfo | — |
| `getStressColor` | hidden | 1906–1913 | — | — | — | — |
| `getBBData` | hidden | 1913–1921 | — | — | ActivityMonitor.getInfo | — |
| `goalPercent` | hidden | 1921–1926 | — | — | — | — |
| `getStepGoalProgress` | hidden | 1926–1934 | — | — | ActivityMonitor.getInfo | — |
| `getFloorGoalProgress` | hidden | 1934–1942 | — | — | ActivityMonitor.getInfo | — |
| `getActMinGoalProgress` | hidden | 1942–1950 | — | — | ActivityMonitor.getInfo | — |
| `getMoveBar` | hidden | 1950–1958 | — | — | ActivityMonitor.getInfo | — |
| `getBattData` | hidden | 1958–2003 | — | — | System.getSystemStats | — |
| `formatHour` | hidden | 2003–2011 | — | — | — | — |
| `updateWeather` | hidden | 2011–2026 | weatherCondition, owmError, cachedTempUnit | propWeatherProvider | Weather.getCurrentConditions, Application.Storage.getValue | storeWeatherData, readWeatherData, getTempUnit |
| `updateVo2History` | hidden | 2028–2036 | vo2RunTrend, vo2BikeTrend | — | UserProfile.getProfile | getVo2Trend |
| `computeCcHash` | hidden | 2038–2051 | — | — | — | — |
| `storeWeatherData` | hidden | 2053–2121 | isLowMem, lastHfTime, lastCcHash | isLowMem, lastHfTime, lastCcHash | System.getSystemStats, Weather.getCurrentConditions, Application.Storage.setValue, Weather.getHourlyForecast, Time.now | computeCcHash |
| `readWeatherData` | hidden | 2123–2217 | — | — | Application.Storage.getValue, Time.now, Position.Location | — |
| `getRecoveryTimeVal` | hidden | 2219–2227 | — | — | Complications.getComplication | — |
| `getTrainingStatusVal` | hidden | 2229–2235 | — | — | Complications.getComplication | — |
| `getCalendarEventVal` | hidden | 2237–2250 | — | — | Complications.getComplication | — |
| `getPulseOxVal` | hidden | 2252–2256 | — | — | Complications.getComplication | — |
| `getValueByTypeWithUnit` | hidden | 2258–2264 | — | — | — | getValueByType, getUnitByType |
| `getUnitByType` | hidden | 2266–2284 | — | propTempUnit | Application.loadResource | — |
| `getValueByType` | hidden | 2286–2630 | lastActivityDistUpdate, infoMessage | propIsMetricDistance, propTempUnit, propShowTempUnit, propDistanceUnit, cachedTempUnit, cached*Dist*, lastActivityDistUpdate, propPrecipAmountUnit, propPressureUnit, propIs24H, weatherCondition, propWeatherFormat* | ActivityMonitor.getInfo, Activity.getActivityInfo, UserProfile.getProfile, Complications.getComplication, Weather.getSunrise/Sunset, Application.loadResource, Application.Storage.getValue/setValue, Time.now/Gregorian.info | ~20 helper functions |
| `getDataArrayByType` | hidden | 2632–2721 | cachedGraphYMin, cachedGraphYMax, cachedGraphData2 | propGraphData, propSmallFontVariant | SensorHistory.*, UserProfile.getProfile, Time.now | downsampleGraph |
| `getDailyDataArray` | hidden | 2724–2777 | graphGoalLine, cachedGraphYMin, cachedGraphYMax, cachedGraphData2 | propGraphData, propIsMetricDistance | ActivityMonitor.getHistory/getInfo | getHistoryDayValue, getTodayActivityValue |
| `getHistoryDayValue` | hidden | 2779–2784 | — | — | — | — |
| `getTodayActivityValue` | hidden | 2786–2791 | — | — | — | — |
| `downsampleGraph` | hidden | 2793–2803 | — | graphTargetWidth | Math functions | — |
| `getLabelByType` | hidden | 2805–2887 | — | propTzName1, propTzName2, propIsMetricDistance | Application.loadResource | formatLabel |
| `formatLabel` | hidden | 2887–2892 | — | propFontSize | Application.loadResource | — |
| `formatDate` | hidden | 2892–2907 | — | propDateFormat, propDateCustomFormat, propLabelVisibility, propWeekOffset | Time.now/Gregorian.info, Application.loadResource | formatLabel, dayName, monthName, isoWeekNumber |
| `formatCustomDate` | hidden | 2907–2925 | — | propWeekOffset | Time.now/Gregorian.info | isoWeekNumber |
| `getWeatherByFormat` | hidden | 2925–2949 | — | — | — | getCityName, getWeatherConditionShort, getTemperature, getWind, getWindGust, getPrecip, getHighLow, getPrecipAmount, getObservationTime, getUVIndex, getHumidity |
| `getDateTimeGroup` | hidden | 2949–2959 | — | propIs24H | Time.now/Gregorian.info | — |
| `formatPressure` | hidden | 2959–2978 | — | propPressureUnit | — | — |
| `moonPhase` | hidden | 2978–3020 | — | propHemisphere | Time.now/Gregorian.info, Math | — |
| `formatDistanceByWidth` | hidden | 3020–3030 | — | — | — | — |
| `getCityName` | hidden | 3030–3035 | — | weatherCondition | — | — |
| `getWeatherCondition` | hidden | 3035–3063 | infoMessage | owmError, weatherCondition | Application.loadResource | — |
| `getWeatherConditionShort` | hidden | 3063–3084 | — | weatherCondition, owmError | — | — |
| `getTemperature` | hidden | 3084–3092 | — | weatherCondition, cachedTempUnit | — | convertTemperature, formatTemperature |
| `getTempUnit` | hidden | 3092–3101 | — | propTempUnit | System.getDeviceSettings | — |
| `formatTemperature` | hidden | 3101–3108 | — | propShowTempUnit, cachedTempUnit | — | — |
| `convertTemperature` | hidden | 3108–3117 | — | — | — | — |
| `getWind` | hidden | 3117–3129 | — | weatherCondition | — | formatWindSpeed |
| `getWindGust` | hidden | 3129–3136 | — | weatherCondition | — | formatWindSpeed |
| `formatWindSpeed` | hidden | 3136–3162 | — | propWindUnit | — | — |
| `getPrecipAmount` | hidden | 3162–3175 | — | weatherCondition, propPrecipAmountUnit | System.getDeviceSettings | — |
| `getObservationTime` | hidden | 3175–3184 | — | weatherCondition | Time.now/Gregorian.info | formatHour |
| `getFeelsLike` | hidden | 3184–3191 | — | weatherCondition, cachedTempUnit | — | convertTemperature, formatTemperature |
| `getHumidity` | hidden | 3191–3199 | — | weatherCondition | — | — |
| `getUVIndex` | hidden | 3199–3207 | — | weatherCondition | — | — |
| `getHighLow` | hidden | 3207–3219 | — | weatherCondition, cachedTempUnit | — | convertTemperature, formatTemperature |
| `getPrecip` | hidden | 3219–3227 | — | weatherCondition | — | — |
| `hoursToNextSunEvent` | hidden | 3227–3242 | — | — | Time.now | getNextSunEvent |
| `formatSunTime` | hidden | 3242–3252 | — | — | Time.Gregorian.info, Application.loadResource | formatHour |
| `getNextSunEvent` | hidden | 3252–3289 | — | weatherCondition | Time.now, Weather.getSunrise/Sunset, Time.today | — |
| `getCivilTwilight` | hidden | 3289–3321 | — | — | Math | — |
| `getRestCalories` | hidden | 3321–3344 | — | — | Time.now, UserProfile.getProfile, Math | — |
| `getWeeklyDistance` | hidden | 3344–3363 | — | — | ActivityMonitor.getHistory/getInfo | — |
| `updateActivityDistCache` | hidden | 3363–3398 | cachedRunDist7Days, cachedBikeDist7Days, cachedSwimDist7Days, cachedRunDist28Days, cachedRunDistMonth, lastActivityDistUpdate | propIsMetricDistance | Time.now, UserProfile.getUserActivityHistory | — |
| `getWeeklyDistanceFromComplication` | hidden | 3398–3409 | — | propIsMetricDistance | Complications.getComplication | formatDistanceByWidth |
| `getCgmComplicationByLabel` | hidden | 3409–3427 | — | — | Complications.getComplications | — |
| `convertCgmTrendToArrow` | hidden | 3427–3439 | — | — | — | — |
| `getVo2Trend` | hidden | 3439–3475 | — | — | Time.now, Application.Storage.getValue/setValue | — |
| `getCgmReading` | hidden | 3475–3498 | cgmComplicationId | cgmComplicationId | Complications.getComplication, Time.now | getCgmComplicationByLabel, convertCgmTrendToArrow |
| `getCgmAge` | hidden | 3498–3514 | cgmAgeComplicationId | cgmAgeComplicationId | Complications.getComplication, Time.now | getCgmComplicationByLabel |
| `secondaryTimezone` | hidden | 3514–3558 | — | propIs24H, propHourFormat, propTzHourFormat | Time.now, Time.Gregorian.utcInfo | — |
| `dayName` | hidden | 3558–3568 | cachedDayOfWeek, cachedDayName | cachedDayOfWeek | Application.loadResource | — |
| `monthName` | hidden | 3568–3579 | cachedMonth, cachedMonthName | cachedMonth | Application.loadResource | — |
| `isoWeekNumber` | hidden | 3579–3606 | — | propWeekOffset | — | julianDay, isLeapYear |
| `julianDay` | hidden | 3606–3613 | — | — | — | — |
| `isLeapYear` | hidden | 3613–3626 | — | — | — | — |
| `loadBottomField2Property` | :Square | 3626–3630 | propBottomField2Shows | — | Application.Properties.getValue | — |
| `computeBottomField2Values` | :Square | 3631–3639 | — | propBottomFieldShows, propBottomField2Shows | — | getValueByType, getLabelByType |
| `calculateSquareLayout` | :Square | 3640–3661 | dualBottomFieldActive, bottomFiveYOriginal, bottomFive1X, bottomFive2X, bottomFiveY | propBottomFieldShows, propBottomField2Shows, centerX, bottomDataWidth, labelHeight, labelMargin, propLabelVisibility, bottomFiveY | — | — |
| `loadBottomField2Property` | :Round | 3670–3672 | — | — | — | — |
| `calculateSquareLayout` | :Round | 3665–3667 | — | — | — | — |
| `computeBottomField2Values` | :Round | 3675–3677 | — | — | — | — |
| `drawBottomFieldsWithIcons` | :Square | 3691–3742 | — | dualBottomFieldActive, bottomDataWidth, bottomFive1X/2X, bottomFiveY/Original, propLabelVisibility, themeColors, fontLabel, fontBottomData, propFontSize, screenWidth/Height, centerX, marginX, largeDataHeight, iconYAdj | Graphics dc | drawDataField, drawIconWithOverlay |
| `drawBottomFieldsWithIcons` | :Round | 3745–3764 | — | centerX, fontBottomData, largeDataHeight, iconYAdj, bottomFiveY, marginX, screenWidth/Height, propFontSize | Graphics dc | drawDataField, drawIconWithOverlay |
| `drawIconWithOverlay` | hidden | 3679–3688 | — | themeColors | Graphics dc | — |

### Segment34InputDelegate (inner class, lines 3774–3834)
| Function | Lines | Notes |
|---|---|---|
| `initialize` | 3774–3779 | Stores reference to view, screen dims |
| `onPress` | 3781–3799 | Routes tap zones to handlePress |
| `handlePress` | 3801–3834 | Writes view.infoMessage, view.nightModeOverride; reads/writes Application.Storage; calls view.forceDataRefresh, view.onSettingsChanged |

---

## Logical Groupings

Based on the analysis above, functions naturally cluster into these concern areas:

### 1. Lifecycle / Orchestration (~100 lines)
`initialize`, `onLayout`, `onShow`, `onHide`, `onUpdate`, `onExitSleep`, `onEnterSleep`, `onSettingsChanged`, `forceDataRefresh`, `onPartialUpdate`, `reloadSettings`

### 2. Settings Loading (~100 lines)
`updateProperties`, `loadBottomField2Property`

### 3. Resource & Font Loading (~350 lines)
`loadResources` (×6 annotated variants), `loadFontVariant`, `loadAODGraphics`

### 4. Layout Calculation (~80 lines)
`calculateLayout`, `calculateBarLimits`, `calculateFieldXCoords`, `calculateSquareLayout` (×2)

### 5. Theme / Color (~150 lines)
`updateColorTheme`, `setColorTheme` (×2), `parseThemeString`, `getNightModeValue`, `getStressColor`

### 6. Rendering (~550 lines)
`drawWatchface`, `drawAOD` (×2), `drawPattern`, `drawDataField`, `drawSideBars`, `drawOneBar`, `drawMoveBarTicks`, `drawBatteryIcon` (×2), `drawBottomFieldsWithIcons` (×2), `drawIconWithOverlay`, `computeDisplayValues`

### 7. Graph Subsystem (~400 lines)
`drawGraph`, `drawBarGraph`, `drawLineGraph`, `formatGraphAxisValue`, `getGraphXLabel`, `getDataArrayByType`, `getDailyDataArray`, `getHistoryDayValue`, `getTodayActivityValue`, `downsampleGraph`

### 8. Value / Label Resolution (~700 lines)
`getValueByType`, `getValueByTypeWithUnit`, `getUnitByType`, `getLabelByType`, `formatLabel`, `getValueForSeconds`, `getClockData`, `getFieldWidths`, `updateActiveLabels`

### 9. Activity Data Helpers (~200 lines)
`getBarData`, `getStressData`, `getBBData`, `goalPercent`, `getStepGoalProgress`, `getFloorGoalProgress`, `getActMinGoalProgress`, `getMoveBar`, `getWeeklyDistance`, `updateActivityDistCache`, `getWeeklyDistanceFromComplication`, `getRecoveryTimeVal`, `getTrainingStatusVal`, `getCalendarEventVal`, `getPulseOxVal`, `getAltitudeValue`, `getBattData`

### 10. Icon / Complication Helpers (~150 lines)
`getIconState`, `getIconColor` (×2), `getIconCountOverlay`, `getCgmReading`, `getCgmAge`, `getCgmComplicationByLabel`, `convertCgmTrendToArrow`, `getVo2Trend`, `updateVo2History`

### 11. Weather Data (~250 lines)
`updateWeather`, `storeWeatherData`, `readWeatherData`, `computeCcHash`

### 12. Weather Display Helpers (~300 lines)
`getCityName`, `getWeatherCondition`, `getWeatherConditionShort`, `getTemperature`, `getTempUnit`, `formatTemperature`, `convertTemperature`, `getWind`, `getWindGust`, `formatWindSpeed`, `getPrecipAmount`, `getObservationTime`, `getFeelsLike`, `getHumidity`, `getUVIndex`, `getHighLow`, `getPrecip`, `getWeatherByFormat`, `getNextSunEvent`, `hoursToNextSunEvent`, `getCivilTwilight`, `formatSunTime`

### 13. Date / Time Utilities (~200 lines)
`formatDate`, `formatCustomDate`, `getDateTimeGroup`, `secondaryTimezone`, `dayName`, `monthName`, `isoWeekNumber`, `julianDay`, `isLeapYear`, `moonPhase`, `formatHour`

### 14. Formatting Utilities (~100 lines)
`formatDistanceByWidth`, `formatPressure`, `computeBottomField2Values` (×2)

### 15. Input Handling (~60 lines)
`Segment34InputDelegate` (all three functions)
