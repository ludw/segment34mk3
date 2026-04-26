import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Complications;
using Toybox.Position;

// Color theme index constants — module-level so all helper classes can reference them.
enum colorNames {
    bg = 0,
    clock,
    clockBg,
    outline,
    dataVal,
    fieldBg,
    fieldLbl,
    date,
    dateDim,
    notif,
    stress,
    bodybatt,
    moon,
    lowBatt
}

(:background_excluded)
class Segment34View extends WatchUi.WatchFace {

    hidden var visible as Boolean = true;
    hidden var screenHeight as Number;
    hidden var screenWidth as Number;
    (:initialized) hidden var clockHeight as Number;
    (:initialized) hidden var clockWidth as Number;
    (:initialized) hidden var labelHeight as Number;
    (:initialized) hidden var labelMargin as Number;
    (:initialized) hidden var tinyDataHeight as Number;
    (:initialized) hidden var smallDataHeight as Number;
    (:initialized) hidden var largeDataHeight as Number;
    (:initialized) hidden var largeDataWidth as Number;
    (:initialized) hidden var bottomDataWidth as Number;
    (:initialized) hidden var baseX as Number;
    (:initialized) hidden var baseY as Number;
    hidden var centerX as Number;
    hidden var centerY as Number;
    hidden var marginX as Number;
    hidden var marginY as Number;
    hidden var halfMarginY as Number = 0;
    hidden var halfClockHeight as Number = 0;
    hidden var halfClockWidth as Number = 0;
    hidden var aboveLine2Adjustment as Number = 0;
    hidden var barBottomAdj as Number = 0;
    hidden var bottomFiveAdj as Number = 0;
    hidden var fieldSpaceingAdj as Number = 0;
    hidden var textSideAdj as Number = 0;
    hidden var secondsClipWidth as Number = 24;
    hidden var iconYAdj as Number = 3;
    hidden var graphBarWidth as Number = 2;
    hidden var graphBarSpacing as Number = 2;
    hidden var graphHeight as Number = 20;
    hidden var graphTargetWidth as Number = 40;
    hidden var graphHalfWidth as Number = 0;  // max half-width of graph area; set per device in loadResources()
    hidden var propGraphSize as Number = 0;
    hidden var propGraphStyle as Number = 0;
    hidden var propGraphAxisLabels as Boolean = false;
    hidden var bottomFieldWidths as Array<Number> = [3, 3, 3, 0];

    // Cached graph data — sensor history only changes once per minute,
    // so we skip the expensive SensorHistory iteration on sub-minute updates.
    hidden var cachedGraphData as Array<Number>? = null;
    // cachedGraphData2 lives in graphRenderer
    hidden var cachedGraphDataSource as Number = -1;
    hidden var lastGraphMinute as Number = -1;

    hidden var fontMoon as WatchUi.FontResource?;
    hidden var fontIcons as WatchUi.FontResource;
    hidden var fontClock as WatchUi.FontResource?;
    hidden var fontClockOutline as WatchUi.FontResource?;
    hidden var fontLabel as WatchUi.FontResource?;
    hidden var fontTinyData as WatchUi.FontResource?;
    hidden var fontSmallData as WatchUi.FontResource?;
    hidden var fontAODData as WatchUi.FontResource?;
    hidden var fontBottomData as WatchUi.FontResource?;
    hidden var fontBattery as WatchUi.FontResource?;


    // Layout Caching
    hidden var fieldXCoords as Array<Number> = [0, 0, 0, 0];
    hidden var fieldY as Number = 0;
    hidden var bottomFiveY as Number = 0;
    (:Square) hidden var bottomFive1X as Number = 0;
    (:Square) hidden var bottomFive2X as Number = 0;
    (:Square) hidden var dualBottomFieldActive as Boolean = false;
    (:Square) hidden var bottomFiveYOriginal as Number = 0;

    hidden var drawGradient as BitmapResource?;
    hidden var drawAODPattern as BitmapResource?;
    
    public var infoMessage as String = "";
    public var nightModeOverride as Number = -1;
    hidden var theme as ThemeManager = new ThemeManager();
    hidden var weatherCondition as StoredWeather or Null;
    hidden var propWeatherProvider as Number = 0;
    hidden var owmError as String or Null = null;
    hidden var hrHistoryData as Array<Number>?;
    hidden var canBurnIn as Boolean = false;
    hidden var isSleeping as Boolean = false;
    hidden var lastUpdate as Number? = null;
    hidden var lastSlowUpdate as Number? = null;
    hidden var cachedValues as Dictionary = {};
    hidden var cachedTempUnit as String = "C";

    // graphGoalLine, cachedGraphYMin, cachedGraphYMax live in graphRenderer
    hidden var lastHfTime as Number? = null;
    hidden var lastCcHash as Number? = null;
    hidden var isLowMem as Boolean = false;

    hidden var doesPartialUpdate as Boolean = false;
    hidden var complications as ComplicationHelper = new ComplicationHelper();
    hidden var weatherHelper as WeatherDisplayHelper = new WeatherDisplayHelper();
    hidden var graphRenderer as GraphRenderer = new GraphRenderer();
    
    hidden var propIs24H as Boolean = false;
    hidden var propTheme as Integer = 0;
    hidden var propNightTheme as Integer = -1;
    hidden var propNightThemeActivation as Number = 0;
    hidden var propColorOverride as String = "";
    hidden var propColorOverride2 as String = "";
    hidden var propClockOutlineStyle as Number = 0;
    hidden var propClockGradientOverlay as Number = 0;
    hidden var propClockFont as Number = 0;
    hidden var propFontSize as Number = 0;
    hidden var propBatteryVariant as Number = 3;
    hidden var propShowSeconds as Boolean = true;
    hidden var propFieldLayout as Number = 0;
    hidden var propLeftValueShows as Number = 6;
    hidden var propMiddleValueShows as Number = 10;
    hidden var propRightValueShows as Number = 0;
    hidden var propFourthValueShows as Number = 0;
    hidden var propAlwaysShowSeconds as Boolean = false;
    hidden var propUpdateFreq as Number = 5;
    hidden var propShowClockBg as Boolean = true;
    hidden var propShowDataBg as Boolean = false;
    hidden var propAodStyle as Number = 1;
    hidden var propAodFieldShows as Number = -1;
    hidden var propAodRightFieldShows as Number = -2;
    hidden var propDateFieldShows as Number = -1;
    hidden var propBottomFieldShows as Number = 17;
    hidden var propBottomField2Shows as Number = -2;
    hidden var propAodAlignment as Number = 0;
    hidden var propDateAlignment as Number = 0;
    hidden var propBottomFieldAlignment as Number = 2;
    hidden var propBottomFieldLabelAlignment as Number = 0;
    hidden var propLeftBarShows as Number = 1;
    hidden var propRightBarShows as Number = 2;
    hidden var propSideBarWidth as Number = 0;
    hidden var propLimitBarHeight as Boolean = false;
    hidden var actualBarWidth as Number = 0;
    hidden var maxSideBarHeight as Number = 0;
    hidden var propIcon1 as Number = 1;
    hidden var propIcon2 as Number = 2;
    hidden var propHemisphere as Number = 0;
    hidden var propHourFormat as Number = 0;
    hidden var propZeropadHour as Boolean = true;
    hidden var propTimeSeparator as Number = 0;
    hidden var propTempUnit as Number = 0;
    hidden var propShowTempUnit as Boolean = true;
    hidden var propDistanceUnit as Number = 0;
    hidden var propIsMetricDistance as Boolean = true;
    hidden var propWindUnit as Number = 0;
    hidden var propPrecipAmountUnit as Number = 0;
    hidden var propPressureUnit as Number = 0;
    hidden var propTopPartShows as Number = 0;
    hidden var propGraphData as Number = 0;
    hidden var propSunriseFieldShows as Number = 39;
    hidden var propSunsetFieldShows as Number = 40;
    hidden var propWeatherLine1Shows as Number = 79;
    hidden var propWeatherLine2Shows as Number = 80;
    hidden var propWeatherFormat1 as String = "t w p";
    hidden var propWeatherFormat2 as String = "c";
    hidden var propDateFormat as Number = 0;
    hidden var propDateCustomFormat as String = "DDD, DD MMMM";
    hidden var propNotificationCountShows as Number = 36;
    hidden var propSecondsShows as Number = -3;
    hidden var propTzOffset1 as Number = 0;
    hidden var propTzOffset2 as Number = 0;
    hidden var propTzName1 as String = "";
    hidden var propTzName2 as String = "";
    hidden var propTzHourFormat as Number = 0;
    hidden var propWeekOffset as Number = 0;
    hidden var propLabelVisibility as Number = 0;
    hidden var propSmallFontVariant as Number = 0;
    hidden var propBottomFontVariant as Number = 2;
    hidden var propStressDynamicColor as Boolean = false;

    // Cached Labels
    hidden var strLabelTopLeft as String = "";
    hidden var strLabelTopRight as String = "";
    hidden var strLabelBottomLeft as String = "";
    hidden var strLabelBottomMiddle as String = "";
    hidden var strLabelBottomRight as String = "";
    hidden var strLabelBottomFourth as String = "";


    var clockBgText = "";

    (:Round260) const barWidth = 3;
    (:Round280) const barWidth = 3;
    (:Round390) const barWidth = 4;
    (:Round416) const barWidth = 4;
    (:Round454) const barWidth = 4;
    (:Square) const barWidth = 4;

    function initialize() {
        WatchFace.initialize();

        canBurnIn = System.getDeviceSettings().requiresBurnInProtection;

        screenHeight = Toybox.System.getDeviceSettings().screenHeight;
        screenWidth = Toybox.System.getDeviceSettings().screenWidth;
        fontIcons = Application.loadResource(Rez.Fonts.icons);
        centerX = Math.round(screenWidth / 2);
        centerY = Math.round(screenHeight / 2);
        marginY = Math.round(screenHeight / 30);
        marginX = Math.round(screenWidth / 20);
        reloadSettings();
    }

    hidden function reloadSettings() as Void {
        updateProperties();

        loadResources();
        if(propTopPartShows == 0) {
            fontMoon = Application.loadResource(Rez.Fonts.moon);
        }

        halfClockHeight = Math.round(clockHeight / 2);
        if(clockBgText.length() == 4) {
            halfClockWidth = Math.round((clockWidth / 5 * 4.2) / 2);
        } else {
            halfClockWidth = Math.round(clockWidth / 2);
        }

        halfMarginY = Math.round(marginY / 2);

        graphRenderer.configure(
            graphBarWidth, graphBarSpacing, graphTargetWidth, graphHalfWidth, halfMarginY,
            fontLabel, labelHeight, propGraphData, propGraphStyle, propGraphAxisLabels,
            propIs24H, propIsMetricDistance
        );

        calculateLayout();
        calculateBarLimits();

        updateWeather();
    }

    hidden function updateActiveLabels() as Void {
        var fieldWidths = getFieldWidths();
        strLabelTopLeft = getLabelByType(propSunriseFieldShows, 1);
        strLabelTopRight = getLabelByType(propSunsetFieldShows, 1);
        if(propFontSize == 0) {
            strLabelBottomLeft = getLabelByType(propLeftValueShows, fieldWidths[0] - 1);
            strLabelBottomMiddle = getLabelByType(propMiddleValueShows, fieldWidths[1] - 1);
            strLabelBottomRight = getLabelByType(propRightValueShows, fieldWidths[2] - 1);
            strLabelBottomFourth = getLabelByType(propFourthValueShows, fieldWidths[3] - 1);
        } else { // Large text
            strLabelBottomLeft = getLabelByType(propLeftValueShows, 1);
            strLabelBottomMiddle = getLabelByType(propMiddleValueShows, 1);
            strLabelBottomRight = getLabelByType(propRightValueShows, 1);
            strLabelBottomFourth = getLabelByType(propFourthValueShows, 1);
        }
    }

    hidden function loadFontVariant(resDefault, resReadable, resLines, variant as Number) as FontResource {
        var selectedRes = resLines;
        if (variant == 0) {
            selectedRes = resDefault;
        } else if (variant == 1) {
            selectedRes = resReadable;
        }
        return Application.loadResource(selectedRes) as FontResource;
    }

    hidden function loadAODGraphics() as Void {
        if(propClockGradientOverlay == 0 or propClockGradientOverlay == 2 or propClockGradientOverlay == 4) {
            drawGradient = Application.loadResource(Rez.Drawables.gradient) as BitmapResource;
        } else {
            drawGradient = null;
        }

        if(propClockGradientOverlay == 0 or propClockGradientOverlay == 1) {
            drawAODPattern = Application.loadResource(Rez.Drawables.aod) as BitmapResource;
        } else if(propClockGradientOverlay == 4 or propClockGradientOverlay == 5) {
            drawAODPattern = Application.loadResource(Rez.Drawables.aod3) as BitmapResource;
        } else {
            drawAODPattern = Application.loadResource(Rez.Drawables.aod2) as BitmapResource;
        }
    }

    (:Round260)
    hidden function loadResources() as Void {
        switch(propClockFont) {
            case 1:  fontClock = Application.loadResource(Rez.Fonts.segments80_2); break;
            case 2:  fontClock = Application.loadResource(Rez.Fonts.segments80_3); break;
            case 3:  fontClock = Application.loadResource(Rez.Fonts.segments80_4); break;
            case 4:  fontClock = Application.loadResource(Rez.Fonts.segments80_2r); break;
            default: fontClock = Application.loadResource(Rez.Fonts.segments80); break;
        }

        if(propFontSize == 0) {
            fontTinyData = Application.loadResource(Rez.Fonts.storre);
            fontSmallData = loadFontVariant(Rez.Fonts.led_small, Rez.Fonts.led_small_readable, Rez.Fonts.led_small_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propBottomFontVariant);
            fontLabel = Application.loadResource(Rez.Fonts.smol);
            fontBattery = fontLabel;

            marginY = 5;
            labelHeight = 8;
            tinyDataHeight = 10;
            smallDataHeight = 13;
            secondsClipWidth = 24;
            bottomFiveAdj = 2;
            baseY = centerY - smallDataHeight;
            aboveLine2Adjustment = 5;
            bottomFieldWidths = [3, 3, 3, 0];
        } else {
            fontTinyData = Application.loadResource(Rez.Fonts.storre);
            fontSmallData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propBottomFontVariant);
            fontLabel = fontTinyData;
            fontAODData = Application.loadResource(Rez.Fonts.led);
            fontBattery = Application.loadResource(Rez.Fonts.led_small_lines);

            marginY = 4;
            labelHeight = 10;
            tinyDataHeight = 10;
            smallDataHeight = 20;
            secondsClipWidth = 36;
            bottomFiveAdj = 2;
            baseY = centerY - 6;
            aboveLine2Adjustment = 3;
            bottomFieldWidths = [4, 4, 0, 0];
        }

        clockHeight = 80;
        clockWidth = 230;
        labelMargin = 6;
        largeDataHeight = 20;
        largeDataWidth = 18;
        bottomDataWidth = 18;

        baseX = centerX + 1;
        fieldSpaceingAdj = 5;
        barBottomAdj = 1;
        graphBarWidth = (propGraphSize == 1) ? 2 : 1;
        graphBarSpacing = (propGraphSize == 1) ? 2 : 1;
        graphHeight = (propGraphSize == 1) ? 25 : 18;
        graphTargetWidth = (propGraphSize == 1) ? 25 : 40;
        graphHalfWidth = screenWidth / 6;
    }

    (:Round280)
    hidden function loadResources() as Void {
        switch(propClockFont) {
            case 1:  fontClock = Application.loadResource(Rez.Fonts.segments80wide_2); break;
            case 2:  fontClock = Application.loadResource(Rez.Fonts.segments80wide_3); break;
            case 3:  fontClock = Application.loadResource(Rez.Fonts.segments80wide_4); break;
            case 4:  fontClock = Application.loadResource(Rez.Fonts.segments80wide_2r); break;
            default: fontClock = Application.loadResource(Rez.Fonts.segments80wide); break;
        }
        if(propFontSize == 0) {
            fontTinyData = Application.loadResource(Rez.Fonts.storre);
            fontSmallData = loadFontVariant(Rez.Fonts.led_small, Rez.Fonts.led_small_readable, Rez.Fonts.led_small_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propBottomFontVariant);
            fontLabel = Application.loadResource(Rez.Fonts.smol);
            fontBattery = fontLabel;

            marginY = 8;
            labelHeight = 8;
            smallDataHeight = 13;
            secondsClipWidth = 24;
            bottomFiveAdj = 5;
            baseY = centerY - smallDataHeight - 4;
            aboveLine2Adjustment = 2;
            bottomFieldWidths = [4, 3, 4, 0];
        } else {
            fontTinyData = Application.loadResource(Rez.Fonts.storre);
            fontSmallData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propBottomFontVariant);
            fontLabel = fontTinyData;
            fontAODData = Application.loadResource(Rez.Fonts.led);
            fontBattery = Application.loadResource(Rez.Fonts.led_small_lines);

            marginY = 6;
            labelHeight = 10;
            smallDataHeight = 20;
            secondsClipWidth = 36;
            bottomFiveAdj = 5;
            baseY = centerY - 5;
            aboveLine2Adjustment = 2;
            bottomFieldWidths = [3, 3, 3, 0];
        }

        clockHeight = 80;
        clockWidth = 240;
        labelMargin = 6;
        tinyDataHeight = 10;
        largeDataHeight = 20;
        largeDataWidth = 18;
        bottomDataWidth = 18;
        baseX = centerX;
        barBottomAdj = 1;
        graphBarWidth = (propGraphSize == 1) ? 2 : 1;
        graphBarSpacing = (propGraphSize == 1) ? 2 : 1;
        graphHeight = (propGraphSize == 1) ? 28 : 20;
        graphTargetWidth = (propGraphSize == 1) ? 25 : 40;
        graphHalfWidth = screenWidth / 6;
    }

    (:Round390)
    hidden function loadResources() as Void {
        switch(propClockFont) {
            case 1:  fontClock = Application.loadResource(Rez.Fonts.segments125_2); fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_2); break;
            case 2:  fontClock = Application.loadResource(Rez.Fonts.segments125_3); fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_3); break;
            case 3:  fontClock = Application.loadResource(Rez.Fonts.segments125_4); fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_4); break;
            case 4:  fontClock = Application.loadResource(Rez.Fonts.segments125_2r); fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_2r); break;
            default: fontClock = Application.loadResource(Rez.Fonts.segments125);   fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline); break;
        }

        if(propFontSize == 0) {
            fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
            fontSmallData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propBottomFontVariant);
            fontLabel = Application.loadResource(Rez.Fonts.storre);
            fontAODData = Application.loadResource(Rez.Fonts.led);
            fontBattery = fontTinyData;

            clockWidth = 360;
            textSideAdj = 2;
            marginY = 10;
            labelHeight = 10;
            smallDataHeight = 20;
            bottomFiveAdj = 6;
            baseY = centerY - smallDataHeight - 3;
            bottomFieldWidths = [4, 3, 4, 0];
        } else {
            fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
            fontSmallData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propBottomFontVariant);
            fontLabel = fontTinyData;
            fontAODData = Application.loadResource(Rez.Fonts.led_big);
            fontBattery = Application.loadResource(Rez.Fonts.led_lines);

            clockWidth = 360 - 4;
            textSideAdj = 10;
            marginY = 8;
            labelHeight = 13;
            smallDataHeight = 27;
            bottomFiveAdj = 4;
            baseY = centerY - 6;
            bottomFieldWidths = [3, 3, 3, 0];
        }

        loadAODGraphics();

        clockHeight = 125;
        labelMargin = 8;
        tinyDataHeight = 13;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;
        baseX = centerX;
        barBottomAdj = 2;
        graphHeight = (propGraphSize == 1) ? 35 : 25;
        graphHalfWidth = screenWidth / 6;
    }

    (:Round416)
    hidden function loadResources() as Void {
        switch(propClockFont) {
            case 1:  fontClock = Application.loadResource(Rez.Fonts.segments125_2); fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_2); break;
            case 2:  fontClock = Application.loadResource(Rez.Fonts.segments125_3); fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_3); break;
            case 3:  fontClock = Application.loadResource(Rez.Fonts.segments125_4); fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_4); break;
            case 4:  fontClock = Application.loadResource(Rez.Fonts.segments125_2r); fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline_2r); break;
            default: fontClock = Application.loadResource(Rez.Fonts.segments125);   fontClockOutline = Application.loadResource(Rez.Fonts.segments125outline); break;
        }

        if(propFontSize == 0) {
            fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
            fontSmallData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propBottomFontVariant);
            fontLabel = Application.loadResource(Rez.Fonts.storre);
            fontAODData = Application.loadResource(Rez.Fonts.led);
            fontBattery = fontTinyData;

            textSideAdj = 4;
            marginY = 13;
            labelHeight = 10;
            smallDataHeight = 20;
            bottomFiveAdj = 4;
            baseY = centerY - smallDataHeight - 4;
            bottomFieldWidths = [4, 4, 4, 0];
        } else {
            fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
            fontSmallData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propBottomFontVariant);
            fontLabel = fontTinyData;
            fontAODData = Application.loadResource(Rez.Fonts.led_big);
            fontBattery = Application.loadResource(Rez.Fonts.led_lines);

            textSideAdj = 2;
            marginY = 12;
            labelHeight = 13;
            smallDataHeight = 27;
            bottomFiveAdj = 6;
            baseY = centerY - 5;
            bottomFieldWidths = [4, 3, 4, 0];
        }

        loadAODGraphics();

        clockHeight = 125;
        clockWidth = 360;
        labelMargin = 8;
        tinyDataHeight = 13;
        largeDataHeight = 27;
        largeDataWidth = 24;
        bottomDataWidth = 24;
        baseX = centerX;
        barBottomAdj = 2;
        bottomFiveAdj = 8;
        graphHeight = (propGraphSize == 1) ? 35 : 25;
        graphHalfWidth = screenWidth / 6;
    }

    (:Round454)
    hidden function loadResources() as Void {
        switch(propClockFont) {
            case 1:  fontClock = Application.loadResource(Rez.Fonts.segments145_2); fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_2); break;
            case 2:  fontClock = Application.loadResource(Rez.Fonts.segments145_3); fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_3); break;
            case 3:  fontClock = Application.loadResource(Rez.Fonts.segments145_4); fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_4); break;
            case 4:  fontClock = Application.loadResource(Rez.Fonts.segments145_2r); fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_2r); break;
            default: fontClock = Application.loadResource(Rez.Fonts.segments145);   fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline); break;
        }

        if(propFontSize == 0) {
            fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
            fontSmallData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propBottomFontVariant);
            fontLabel = Application.loadResource(Rez.Fonts.storre);
            fontAODData = Application.loadResource(Rez.Fonts.led);
            fontBattery = fontTinyData;

            textSideAdj = 1;
            marginY = 15;
            labelHeight = 10;
            smallDataHeight = 20;
            bottomFiveAdj = 8;
            baseY = centerY - smallDataHeight;
            bottomFieldWidths = [4, 4, 4, 0];

        } else {
            fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
            fontSmallData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propBottomFontVariant);
            fontLabel = fontTinyData;
            fontAODData = Application.loadResource(Rez.Fonts.led_big);
            fontBattery = Application.loadResource(Rez.Fonts.led_lines);

            textSideAdj = 6;
            marginY = 14;
            labelHeight = 13;
            smallDataHeight = 27;
            bottomFiveAdj = 6;
            baseY = centerY - 5;
            bottomFieldWidths = [3, 3, 3, 0];
        }

        clockHeight = 145;
        clockWidth = 415;
        loadAODGraphics();

        labelMargin = 8;
        tinyDataHeight = 13;
        largeDataHeight = 27;
        baseX = centerX + 3;
        fieldSpaceingAdj = 20;
        largeDataWidth = 24;
        bottomDataWidth = 24;
        barBottomAdj = 2;
        graphHeight = (propGraphSize == 1) ? 40 : 30;
        graphTargetWidth = 45;
        graphHalfWidth = screenWidth / 6;
    }

    (:Square)
    hidden function loadResources() as Void {
        switch(propClockFont) {
            case 1:  fontClock = Application.loadResource(Rez.Fonts.segments145_2); fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_2); break;
            case 2:  fontClock = Application.loadResource(Rez.Fonts.segments145_3); fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_3); break;
            case 3:  fontClock = Application.loadResource(Rez.Fonts.segments145_4); fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_4); break;
            case 4:  fontClock = Application.loadResource(Rez.Fonts.segments145_2r); fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline_2r); break;
            default: fontClock = Application.loadResource(Rez.Fonts.segments145);   fontClockOutline = Application.loadResource(Rez.Fonts.segments145outline); break;
        }

        if(propFontSize == 0) {
            fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
            fontSmallData = loadFontVariant(Rez.Fonts.led, Rez.Fonts.led_inbetween, Rez.Fonts.led_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propBottomFontVariant);
            fontLabel = Application.loadResource(Rez.Fonts.storre);
            fontAODData = Application.loadResource(Rez.Fonts.led);
            fontBattery = fontTinyData;

            textSideAdj = 1;
            marginY = 18;
            labelHeight = 10;
            smallDataHeight = 20;
            bottomFiveAdj = 8;
            baseY = centerY - smallDataHeight - 10;
            bottomFieldWidths = [4, 4, 4, 0];

        } else {
            fontTinyData = Application.loadResource(Rez.Fonts.led_small_lines);
            fontSmallData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propSmallFontVariant);
            fontBottomData = loadFontVariant(Rez.Fonts.led_big, Rez.Fonts.led_big_readable, Rez.Fonts.led_big_lines, propBottomFontVariant);
            fontLabel = fontTinyData;
            fontAODData = Application.loadResource(Rez.Fonts.led_big);
            fontBattery = Application.loadResource(Rez.Fonts.led_lines);

            textSideAdj = 6;
            marginY = 14;
            labelHeight = 13;
            smallDataHeight = 27;
            bottomFiveAdj = 6;
            baseY = centerY - 35;
            bottomFieldWidths = [4, 4, 4, 0];
        }
        
        clockHeight = 145;
        clockWidth = 415;
        loadAODGraphics();

        labelMargin = 8;
        tinyDataHeight = 13;
        largeDataHeight = 27;
        baseX = centerX + 3;
        fieldSpaceingAdj = 20;
        largeDataWidth = 24;
        bottomDataWidth = 24;
        barBottomAdj = 2;
        graphHeight = (propGraphSize == 1) ? 40 : 30;
        graphTargetWidth = 45;
        graphHalfWidth = screenWidth / 4;
    }

    hidden function computeDisplayValues(now as Gregorian.Info) as Dictionary {
        var values = {};
        
        // From updateSlowData logic
        values[:dataClock] = getClockData(now);
        values[:dataMoon] = (propTopPartShows == 0) ? moonPhase(now, propHemisphere) : "";
        if(propTopPartShows == 2) {
            var currentMinute = now.hour * 60 + now.min;
            // Only re-fetch sensor history when the minute changes or the data source changed.
            // SensorHistory updates at most once per minute, so more frequent reads are wasted.
            if(cachedGraphData == null
                    or currentMinute != lastGraphMinute
                    or propGraphData != cachedGraphDataSource) {
                cachedGraphData = graphRenderer.getDataArrayByType(propGraphData);
                cachedGraphDataSource = propGraphData;
                lastGraphMinute = currentMinute;
            }
            values[:dataGraph1] = cachedGraphData;
            values[:dataGraph1b] = (propGraphData == 10) ? graphRenderer.cachedGraphData2 : null;
        } else {
            values[:dataGraph1] = null;
        }

        values[:dataLabelTopLeft] = strLabelTopLeft;
        values[:dataLabelTopRight] = strLabelTopRight;
        values[:dataLabelBottomLeft] = strLabelBottomLeft;
        values[:dataLabelBottomMiddle] = strLabelBottomMiddle;
        values[:dataLabelBottomRight] = strLabelBottomRight;
        values[:dataLabelBottomFourth] = strLabelBottomFourth;

        // From updateData logic
        var fieldWidths = getFieldWidths();
        values[:dataTopLeft] = getValueByType(propSunriseFieldShows, 5);
        values[:dataTopRight] = getValueByType(propSunsetFieldShows, 5);
        values[:dataAboveLine1] = getValueByTypeWithUnit(propWeatherLine1Shows, 10);
        values[:dataAboveLine2] = getValueByTypeWithUnit(propWeatherLine2Shows, 10);
        values[:dataBelow] = getValueByTypeWithUnit(propDateFieldShows, 10);
        values[:dataNotifications] = getValueByType(propNotificationCountShows, 2);
        values[:dataBottomLeft] = getValueByType(propLeftValueShows, fieldWidths[0]);
        values[:dataBottomMiddle] = getValueByType(propMiddleValueShows, fieldWidths[1]);
        values[:dataBottomRight] = getValueByType(propRightValueShows, fieldWidths[2]);
        values[:dataBottomFourth] = getValueByType(propFourthValueShows, fieldWidths[3]);
        values[:dataBottom] = getValueByType(propBottomFieldShows, 5);
        computeBottomField2Values(values);
        values[:dataIcon1] = complications.getIconState(propIcon1);
        values[:dataIcon2] = complications.getIconState(propIcon2);
        values[:dataIcon1Count] = complications.getIconCountOverlay(propIcon1);
        values[:dataIcon2Count] = complications.getIconCountOverlay(propIcon2);
        values[:dataIcon1Color] = complications.getIconColor(propIcon1);
        values[:dataIcon2Color] = complications.getIconColor(propIcon2);
        values[:dataBattery] = getBattData(propBatteryVariant, screenHeight, propFontSize);
        values[:dataAODLeft] = getValueByType(propAodFieldShows, 10);
        values[:dataAODRight] = getValueByType(propAodRightFieldShows, 5);
        values[:dataLeftBar] = getBarData(propLeftBarShows);
        values[:dataRightBar] = getBarData(propRightBarShows);

        if(!infoMessage.length() == 0) {
            values[:dataBelow] = infoMessage;
            infoMessage = ""; 
        }
        
        values[:dataSeconds] = getValueForSeconds(now);
        
        return values;
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    }

    // Called when this View is brought to the foreground.
    // Restore the state of this View and prepare it to be shown.
    // This includes loading resources into memory.
    function onShow() as Void {
        visible = true;
        lastUpdate = null;
        lastSlowUpdate = null;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        if(!visible) { return; }

        var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var unix_timestamp = Time.now().value();

        if(doesPartialUpdate) {
            dc.clearClip();
            doesPartialUpdate = false;
        }

        if(now.sec % 60 == 0 or lastSlowUpdate == null or unix_timestamp - lastSlowUpdate >= 60) {
            lastSlowUpdate = unix_timestamp;
            updateColorTheme();
            updateWeather();
            complications.updateVo2History();
        }

        if(lastUpdate == null or unix_timestamp - lastUpdate >= propUpdateFreq) {
            lastUpdate = unix_timestamp;
            cachedValues = computeDisplayValues(now);
        } else {
            // Only update time-sensitive values
            cachedValues[:dataClock] = getClockData(now);
            cachedValues[:dataSeconds] = getValueForSeconds(now);
        }

        if(isSleeping and canBurnIn) {
            drawAOD(dc, now, cachedValues);
        } else {
            drawWatchface(dc, now, false, cachedValues);
        }
    }

    // Called when this View is removed from the screen.
    // Save the state of this View here.
    // This includes freeing resources from memory.
    function onHide() as Void {
        visible = false;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        lastUpdate = null;
        lastSlowUpdate = null;
        isSleeping = false;
        WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        lastUpdate = null;
        lastSlowUpdate = null;
        isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onSettingsChanged() as Void {
        reloadSettings();
        lastUpdate = null;
        lastSlowUpdate = null;
        WatchUi.requestUpdate();
    }

    public function forceDataRefresh() as Void {
        lastUpdate = null;
    }

    function onPartialUpdate(dc) {
        if(canBurnIn) { return; }
        if(!propAlwaysShowSeconds) { return; }
        doesPartialUpdate = true;

        var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var y1 = baseY + halfClockHeight + marginY;

        var seconds = now.sec.format("%02d");

        dc.setClip(baseX + halfClockWidth - textSideAdj - secondsClipWidth, y1, secondsClipWidth, smallDataHeight+1);
        dc.setColor(theme.colors[bg], theme.colors[bg]);
        dc.clear();

        dc.setColor(theme.colors[date], Graphics.COLOR_TRANSPARENT);
        dc.drawText(baseX + halfClockWidth - textSideAdj, y1, fontSmallData, seconds, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    hidden function calculateBarLimits() as Void {
        actualBarWidth = barWidth * (propSideBarWidth == 1 ? 2 : 1);

        if (!propLimitBarHeight || screenWidth != screenHeight) {
            maxSideBarHeight = clockHeight;
            return;
        }

        var r = screenWidth / 2.0;
        // Distance from screen centre to the bar's outer edge.
        // The gap between clock face and bar is always barWidth; the bar itself is actualBarWidth wide.
        var dx = halfClockWidth + barWidth + actualBarWidth;
        if (dx >= r) {
            maxSideBarHeight = 0;
            return;
        }

        var maxHalfHeight = Math.sqrt(r * r - dx * dx);
        var barBottom = baseY + halfClockHeight + barBottomAdj;
        var maxHeight = barBottom - (centerY - maxHalfHeight);
        maxSideBarHeight = maxHeight < 0 ? 0 : maxHeight.toNumber();
        if (maxSideBarHeight > clockHeight) { maxSideBarHeight = clockHeight; }
    }

    hidden function calculateLayout() as Void {
        var y1 = baseY + halfClockHeight + marginY;
        var y2 = y1 + smallDataHeight + marginY;
        var y3 = y2 + labelHeight + labelMargin + largeDataHeight;
        
        fieldY = y2;
        
        var data_width = Math.sqrt(centerY*centerY - (y3 - centerY)*(y3 - centerY)) * 2 + fieldSpaceingAdj;
        var left_edge = Math.round((screenWidth - data_width) / 2);
        
        calculateFieldXCoords(data_width, left_edge);

        bottomFiveY = y3 + halfMarginY + bottomFiveAdj;
        if((propLabelVisibility == 1 or propLabelVisibility == 3)) { bottomFiveY = bottomFiveY - labelHeight; }
        calculateSquareLayout();
    }

    hidden function calculateFieldXCoords(data_width as Float, left_edge as Number) as Void {
        var digits = getFieldWidths();
        var tot_digits = digits[0] + digits[1] + digits[2] + digits[3];
        if (tot_digits == 0) { return; }

        // Compute each field center in a single expression to avoid accumulated rounding errors.
        // This keeps symmetric layouts (e.g. 3-5-3) perfectly centered relative to data_width.
        var d0 = digits[0].toFloat();
        var d1 = digits[1].toFloat();
        var d2 = digits[2].toFloat();
        var d3 = digits[3].toFloat();
        var tot = tot_digits.toFloat();

        fieldXCoords[0] = left_edge + Math.round((d0 / 2.0) * data_width / tot);
        fieldXCoords[1] = left_edge + Math.round((d0 + d1 / 2.0) * data_width / tot);
        fieldXCoords[2] = left_edge + Math.round((d0 + d1 + d2 / 2.0) * data_width / tot);
        fieldXCoords[3] = left_edge + Math.round((d0 + d1 + d2 + d3 / 2.0) * data_width / tot);
    }

    hidden function drawWatchface(dc as Dc, now as Gregorian.Info, aod as Boolean, values as Dictionary) as Void {
        // Clear
        dc.setColor(theme.colors[bg], theme.colors[bg]);
        dc.clear();
        var yn1 = baseY - halfClockHeight - marginY - smallDataHeight;
        var yn2 = yn1 - marginY - smallDataHeight;
        var yn3 = yn2 - marginY - labelHeight - tinyDataHeight - halfMarginY - aboveLine2Adjustment;

        // Draw Top data fields or graph
        if(propTopPartShows == 2) {
            var xLabelSpace = (propGraphStyle > 0 && propGraphAxisLabels) ? labelHeight + 2 : 0;
            yn3 = yn2 - marginY - graphHeight - xLabelSpace;
            graphRenderer.drawGraph(dc, values[:dataGraph1], values[:dataGraph1b], centerX, yn3, graphHeight, theme.colors);
        } else {
            var top_data_height = marginY;
            var top_field_font = fontTinyData;
            var top_field_center_offset = 20;
            if(propTopPartShows == 1) { top_field_center_offset = labelHeight; }
            if(propLabelVisibility == 0 or propLabelVisibility == 3) {
                // Top 2 fields: Labels
                dc.setColor(theme.colors[fieldLbl], Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX - top_field_center_offset, yn3, fontLabel, values[:dataLabelTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
                dc.drawText(centerX + top_field_center_offset, yn3, fontLabel, values[:dataLabelTopRight], Graphics.TEXT_JUSTIFY_LEFT);

                top_data_height = labelHeight + halfMarginY;
            }

            dc.setColor(theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
            if(propTopPartShows == 0) {
                // Top 2 fields: Values
                dc.drawText(centerX - top_field_center_offset, yn3 + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
                dc.drawText(centerX + top_field_center_offset, yn3 + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);

                // Draw Moon
                dc.setColor(theme.colors[moon], Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, yn3 + ((top_data_height + tinyDataHeight) / 2) + 2, fontMoon, values[:dataMoon], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                // Top 2 fields: Just values (larger)
                if(top_data_height == marginY) { top_field_font = fontSmallData; }
                dc.drawText(centerX - top_field_center_offset, yn3 + top_data_height, top_field_font, values[:dataTopLeft], Graphics.TEXT_JUSTIFY_RIGHT);
                dc.drawText(centerX + top_field_center_offset, yn3 + top_data_height, top_field_font, values[:dataTopRight], Graphics.TEXT_JUSTIFY_LEFT);
            }
        }

        // Draw Lines above clock
        dc.setColor(theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, yn2, fontSmallData, values[:dataAboveLine1], Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, yn1, fontSmallData, values[:dataAboveLine2], Graphics.TEXT_JUSTIFY_CENTER);        

        if(!aod) {
            // Draw Clock
            if(propClockOutlineStyle != 5) {
                dc.setColor(theme.colors[clockBg], Graphics.COLOR_TRANSPARENT);
                if(propShowClockBg and !aod) {
                    dc.drawText(baseX, baseY, fontClock, clockBgText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
                dc.setColor(theme.colors[clock], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

                // Draw clock gradient
                if(drawGradient != null and theme.colors[bg] == 0x000000 and !aod) {
                    dc.drawBitmap(centerX - halfClockWidth, baseY - halfClockHeight, drawGradient);
                }
            }

            if(propClockOutlineStyle == 2 or propClockOutlineStyle == 3 or propClockOutlineStyle == 5) {
                if(fontClockOutline != null) { // Someone has only bothered to draw this font for AMOLED sizes
                    // Draw outline
                    dc.setColor(theme.colors[outline], Graphics.COLOR_TRANSPARENT);
                    dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                }
            }
        } else { // AOD
            if(propClockOutlineStyle == 0 or propClockOutlineStyle == 2) {
                // Draw Clock
                dc.setColor(theme.colors[clock], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if(propClockOutlineStyle == 1 or propClockOutlineStyle == 2 or propClockOutlineStyle == 3 or propClockOutlineStyle == 5) {
                // Draw Outline
                dc.setColor(theme.colors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if(propClockOutlineStyle == 4) {
                // Filled clock but outline color
                dc.setColor(theme.colors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Draw stress and body battery bars
        drawSideBars(dc, values);

        // Draw Line below clock
        var y1 = baseY + halfClockHeight + marginY;
        dc.setColor(theme.colors[date], Graphics.COLOR_TRANSPARENT);
        if(propDateAlignment == 0) {
            dc.drawText(baseX - halfClockWidth + textSideAdj, y1, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(baseX, y1, fontSmallData, values[:dataBelow], Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw seconds
        if(propShowSeconds) {
            dc.drawText(baseX + halfClockWidth - textSideAdj, y1, fontSmallData, values[:dataSeconds], Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Draw Notification count
        dc.setColor(theme.colors[notif], Graphics.COLOR_TRANSPARENT);
        if(propDateAlignment == 0) {
            if(!propShowSeconds) { // No seconds, notification on right side
                dc.drawText(baseX + halfClockWidth - textSideAdj, y1, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_RIGHT);
            } else {
                var date_width = dc.getTextWidthInPixels(values[:dataBelow], fontSmallData);
                var sec_width = dc.getTextWidthInPixels(values[:dataSeconds], fontSmallData); 
                var date_right_edge = baseX - halfClockWidth + textSideAdj + date_width;
                var sec_left = baseX + halfClockWidth - textSideAdj - sec_width;
                var pos = sec_left - marginX;
                if((sec_left - date_right_edge) < 3 * marginX) {
                    pos = (date_right_edge + sec_left) / 2;
                }
                dc.drawText(pos, y1, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else { // Date is centered, notification on left side
            dc.drawText(baseX - halfClockWidth, y1, fontSmallData, values[:dataNotifications], Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Draw the three bottom data fields
        var digits = getFieldWidths();

        drawDataField(dc, fieldXCoords[0], fieldY, 3, values[:dataLabelBottomLeft], values[:dataBottomLeft], digits[0], fontBottomData, largeDataWidth * digits[0]);
        drawDataField(dc, fieldXCoords[1], fieldY, 3, values[:dataLabelBottomMiddle], values[:dataBottomMiddle], digits[1], fontBottomData, largeDataWidth * digits[1]);
        drawDataField(dc, fieldXCoords[2], fieldY, 3, values[:dataLabelBottomRight], values[:dataBottomRight], digits[2], fontBottomData, largeDataWidth * digits[2]);
        drawDataField(dc, fieldXCoords[3], fieldY, 3, values[:dataLabelBottomFourth], values[:dataBottomFourth], digits[3], fontBottomData, largeDataWidth * digits[3]);

        // Draw the 5 digit bottom field(s) and icons
        drawBottomFieldsWithIcons(dc, values);

        // Draw battery icon
        drawBatteryIcon(dc, values);
    }

    (:MIP)
    hidden function drawAOD(dc as Dc, now as Gregorian.Info, values as Dictionary) as Void { }

    (:AMOLED)
    hidden function drawAOD(dc as Dc, now as Gregorian.Info, values as Dictionary) as Void {
        dc.setColor(0x000000, 0x000000);
        dc.clear();

        if(propAodStyle == 2) {
            drawWatchface(dc, now, true, values);
            drawPattern(dc, 0x000000, (now.min % 3));
        } else if (propAodStyle == 1) {
            if(propClockOutlineStyle == 0 or propClockOutlineStyle == 2) {
                // Draw Clock
                dc.setColor(theme.colors[clock], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if(propClockOutlineStyle == 1 or propClockOutlineStyle == 2 or propClockOutlineStyle == 3 or propClockOutlineStyle == 5) {
                // Draw Outline
                dc.setColor(theme.colors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClockOutline, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            if(propClockOutlineStyle == 4) {
                // Filled clock but outline color
                dc.setColor(theme.colors[outline], Graphics.COLOR_TRANSPARENT);
                dc.drawText(baseX, baseY, fontClock, values[:dataClock], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            // Draw clock gradient
            if(propClockGradientOverlay == 4 or propClockGradientOverlay == 5) {
                dc.drawBitmap(centerX - halfClockWidth, baseY - halfClockHeight - (now.min % 2), drawAODPattern);
            } else {
                dc.drawBitmap(centerX - halfClockWidth - (now.min % 2), baseY - halfClockHeight, drawAODPattern);
            }
            

            // Draw Line below clock
            var y1 = baseY + halfClockHeight + marginY;
            dc.setColor(theme.colors[dateDim], Graphics.COLOR_TRANSPARENT);
            if(propAodAlignment == 0) {
                dc.drawText(baseX - halfClockWidth + textSideAdj - (now.min % 3), y1, fontAODData, values[:dataAODLeft], Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(baseX - (now.min % 3), y1, fontAODData, values[:dataAODLeft], Graphics.TEXT_JUSTIFY_CENTER);
            }
            dc.drawText(baseX + halfClockWidth - textSideAdj - 2 - (now.min % 3), y1, fontAODData, values[:dataAODRight], Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    (:AMOLED)
    hidden function drawPattern(dc as Dc, color as ColorType, offset as Number) as Void {
        var text = "";
        var pattern = "S"; // Checkerboard
        if(propClockGradientOverlay == 4 or propClockGradientOverlay == 5) { pattern = "U"; } // Scanlines

        for(var i = 0; i < Math.ceil(screenWidth / 20) + 1; i++) {
                text += pattern;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var i = 0;
        while(i < Math.ceil(screenHeight / 20) + 1) {
            dc.drawText(0, i*20 + offset, fontIcons, text, Graphics.TEXT_JUSTIFY_LEFT);
            i++;
        }
    }

    hidden function getFieldWidths() as Array<Number> {
        if(propFieldLayout == 0) { // Auto
            return bottomFieldWidths;
        } else if(propFieldLayout == 1) {
            return [3, 3, 3, 0];
        } else if(propFieldLayout == 2) {
            return [3, 4, 3, 0];
        } else if(propFieldLayout == 3) {
            return [3, 3, 4, 0];
        } else if(propFieldLayout == 4) {
            return [4, 3, 3, 0];
        } else if(propFieldLayout == 5) {
            return [4, 3, 4, 0];
        } else if(propFieldLayout == 6) {
            return [3, 4, 4, 0];
        } else if(propFieldLayout == 7) {
            return [4, 4, 3, 0];
        } else if(propFieldLayout == 8) {
            return [4, 4, 4, 0];
        } else if(propFieldLayout == 9) {
            return [3, 3, 3, 3];
        } else if(propFieldLayout == 10) {
            return [3, 3, 3, 4];
        } else if(propFieldLayout == 11) {
            return [4, 3, 3, 3];
        } else if(propFieldLayout == 12) {
            return [4, 4, 0, 0];
        } else if(propFieldLayout == 13) {
            return [5, 3, 3, 0];
        } else if(propFieldLayout == 14) {
            return [5, 0, 0, 0];
        } else if(propFieldLayout == 15) {
            return [5, 5, 0, 0];
        } else {
            return [3, 5, 3, 0];
        }
    }

    hidden function drawDataField(dc as Dc, x as Number, y as Number, adjX as Number, label as String?, value as String, width as Number, font as FontResource, bgwidth as Number) as Number {
        if(value.length() == 0 and (label == null or label.length() == 0)) { return 0; }
        if(width == 0) { return 0; }
        var valueBg = "";
        var bgChar = "#";
        if(screenHeight == 360 and width == 5 and label == null) { bgChar = "$"; }
        for(var i=0; i<width; i++) { valueBg += bgChar; }

        var value_bg_width = bgwidth;//dc.getTextWidthInPixels(valueBg, font);
        var half_bg_width = Math.round(value_bg_width / 2);
        var data_y = y;

        if((propLabelVisibility == 0 or propLabelVisibility == 2) and !(label == null)) {
            dc.setColor(theme.colors[fieldLbl], Graphics.COLOR_TRANSPARENT);
            if(propBottomFieldLabelAlignment == 0) {
                dc.drawText(x - half_bg_width + adjX, y, fontLabel, label, Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(x, y, fontLabel, label, Graphics.TEXT_JUSTIFY_CENTER);
            }
            data_y += labelHeight + labelMargin;
        }

        if(propShowDataBg) {
            dc.setColor(theme.colors[fieldBg], Graphics.COLOR_TRANSPARENT);
            dc.drawText(x - half_bg_width + adjX, data_y, font, valueBg, Graphics.TEXT_JUSTIFY_LEFT);
        }

        dc.setColor(theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
        if(propBottomFieldAlignment == 0) {
            dc.drawText(x - half_bg_width + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
        } else if (propBottomFieldAlignment == 1) {
            dc.drawText(x + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (propBottomFieldAlignment == 2) {
            dc.drawText(x + half_bg_width - 1 + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_RIGHT);
        } else if (propBottomFieldAlignment == 3 and width != 5) {
            dc.drawText(x - half_bg_width + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
        } else if (propBottomFieldAlignment == 3 and width == 5) {
            dc.drawText(x + adjX, data_y, font, value, Graphics.TEXT_JUSTIFY_CENTER);
        }

        return value_bg_width;
    }

    hidden function drawSideBars(dc as Dc, values as Dictionary) as Void {
        var abw = actualBarWidth;
        // The gap between the clock face and the bar is always barWidth (the base/narrow width),
        // so wider bars grow outward only — the inner edge stays fixed.
        var leftBarX  = centerX - halfClockWidth - barWidth - abw;
        var rightBarX = centerX + halfClockWidth + barWidth;

        if (values[:dataLeftBar] != null) {
            var useDynamic = (propLeftBarShows == 1 && propStressDynamicColor);
            drawOneBar(dc, leftBarX, centerX - halfClockWidth,
                values[:dataLeftBar], stress, propLeftBarShows, useDynamic);
        }
        if (values[:dataRightBar] != null) {
            var useDynamic = (propRightBarShows == 1 && propStressDynamicColor);
            drawOneBar(dc, rightBarX, centerX + halfClockWidth,
                values[:dataRightBar], bodybatt, propRightBarShows, useDynamic);
        }
    }

    // Draw one side bar.
    //   barX       - left X of the bar rectangle
    //   clockEdgeX - the clock-face edge nearest to this bar (used for movebar tick extent)
    //   barVal     - current value as a percentage (0–100)
    //   baseColor  - default color index from theme.colors
    //   showsType  - what the bar is configured to show (6 = movebar)
    //   useDynamic - true when stress dynamic color should be applied
    hidden function drawOneBar(dc as Dc, barX as Number, clockEdgeX as Number,
                               barVal as Number, baseColor as Number,
                               showsType as Number, useDynamic as Boolean) as Void {
        var abw = actualBarWidth;
        // Scale bar height proportionally within the effective bar range.
        // maxSideBarHeight equals clockHeight when limitBarHeight is off, so
        // this formula is correct in both cases.
        var barHeight = Math.round(barVal * (maxSideBarHeight / 100.0));
        var barBottom = baseY + halfClockHeight + barBottomAdj;

        var barColor = useDynamic ? getStressColor(barVal) : theme.colors[baseColor];
        dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barBottom - barHeight, abw, barHeight);

        if (propLimitBarHeight && showsType != 6) {
            // Show a 1px line at the top of the usable bar range (not for movebar, which has its own ticks)
            dc.drawLine(barX, barBottom - maxSideBarHeight, barX + abw - 1, barBottom - maxSideBarHeight);
        }

        if (showsType == 6) {
            drawMoveBarTicks(dc, barX, clockEdgeX);
        }
    }

    hidden function drawMoveBarTicks(dc as Dc, barX as Number, clockEdgeX as Number) as Void {
        // Ticks span from the bar's outer edge to the clock face edge.
        // Works for both left (barX < clockEdgeX) and right (barX > clockEdgeX) bars.
        var x1 = barX < clockEdgeX ? barX : clockEdgeX;
        var x2 = barX < clockEdgeX ? clockEdgeX : barX + actualBarWidth;
        var barBottom = baseY + halfClockHeight + barBottomAdj;
        var scale = maxSideBarHeight / 100.0;

        dc.setColor(theme.colors[bg], Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x1, barBottom - (40 * scale), x2, barBottom - (40 * scale));
        dc.drawLine(x1, barBottom - (55 * scale), x2, barBottom - (55 * scale));
        dc.drawLine(x1, barBottom - (70 * scale), x2, barBottom - (70 * scale));
        dc.drawLine(x1, barBottom - (85 * scale), x2, barBottom - (85 * scale));
        dc.setPenWidth(1);
    }

    (:AMOLED)
    hidden function drawBatteryIcon(dc as Dc, values as Dictionary) {
        if(propBatteryVariant == 2) { return; }
        if(propBatteryVariant == -1 and propFontSize == 1 and (propBottomFieldShows != -2 or propBottomField2Shows != -2)) { return; } // Auto - hide if large font and bottom field is shown
        var x = centerX;
        var y =  screenHeight - 25;
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);

        if(propFontSize == 0) {
            dc.drawText(x, y, fontIcons, "C", Graphics.TEXT_JUSTIFY_CENTER);
            if(System.getSystemStats().battery <= 15) {
                dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
            }
            if(propBatteryVariant == 3 or propBatteryVariant == -1) {
                dc.drawText(x - 19, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_LEFT);
            } else { // centered when not a bar
                dc.drawText(x - 1, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else {
            y = screenHeight - 33;
            dc.drawText(x, y, fontIcons, "T", Graphics.TEXT_JUSTIFY_CENTER);
            if(System.getSystemStats().battery <= 15) {
                dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
            }
            if(propBatteryVariant == 3 or propBatteryVariant == -1) {
                dc.drawText(x - 26, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_LEFT);
            } else { // centered when not a bar
                dc.drawText(x - 1, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
        
        
    }

    (:MIP)
    hidden function drawBatteryIcon(dc as Dc, values as Dictionary) {
        if(propBatteryVariant == 2) { return; }
        if(propBatteryVariant == -1 and propFontSize == 1 and (propBottomFieldShows != -2 or propBottomField2Shows != -2)) { return; } // Auto - hide if large font and bottom field is shown
        var x = centerX;
        var y =  screenHeight - 20;
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);

        if(propFontSize == 0) {
            dc.drawText(x, y, fontIcons, "B", Graphics.TEXT_JUSTIFY_CENTER);
            if(System.getSystemStats().battery <= 15) {
                dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
            }
            if(propBatteryVariant == 3 or propBatteryVariant == -1) {
                dc.drawText(x - 11, y + 3, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(x - 1, y + 3, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_CENTER);
            }
        } else {
            y = screenHeight - 28;
            dc.drawText(x, y, fontIcons, "C", Graphics.TEXT_JUSTIFY_CENTER);
            if(System.getSystemStats().battery <= 15) {
                dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
            }
            if(propBatteryVariant == 3 or propBatteryVariant == -1) {
                dc.drawText(x - 19, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(x - 1, y + 4, fontBattery, values[:dataBattery], Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }

    hidden function updateColorTheme() {
        theme.update(nightModeOverride, propTheme, propNightTheme, propNightThemeActivation, propColorOverride, propColorOverride2, weatherCondition);
        if(theme.infoMessage.length() > 0) {
            infoMessage = theme.infoMessage;
            theme.infoMessage = "";
        }
    }

    hidden function updateProperties() as Void {
        var p = Application.Properties;
        propTheme = p.getValue("colorTheme") as Number;
        propNightTheme = p.getValue("nightColorTheme") as Number;
        propNightThemeActivation = p.getValue("nightThemeActivation") as Number;
        propColorOverride = p.getValue("colorOverride") as String;
        propColorOverride2 = p.getValue("colorOverride2") as String;
        propClockOutlineStyle = p.getValue("clockOutlineStyle") as Number;
        propClockGradientOverlay = p.getValue("clockGradientOverlay") as Number;
        propClockFont = p.getValue("clockFont") as Number;
        propFontSize = p.getValue("fontSize") as Number;
        propTopPartShows = p.getValue("topPartShows") as Number;
        propGraphData = p.getValue("histogramData") as Number;
        propGraphSize = p.getValue("histogramSize") as Number;
        propGraphStyle = p.getValue("graphStyle") as Number;
        propGraphAxisLabels = p.getValue("graphAxisLabels") as Boolean;
        cachedGraphData = null; // force graph data refresh when properties change
        propSunriseFieldShows = p.getValue("sunriseFieldShows") as Number;
        propSunsetFieldShows = p.getValue("sunsetFieldShows") as Number;
        propWeatherLine1Shows = p.getValue("weatherLine1Shows") as Number;
        propWeatherLine2Shows = p.getValue("weatherLine2Shows") as Number;
        propWeatherFormat1 = p.getValue("weatherFormat1") as String;
        propWeatherFormat2 = p.getValue("weatherFormat2") as String;
        propDateFieldShows = p.getValue("dateFieldShows") as Number;
        propShowSeconds = p.getValue("showSeconds") as Boolean;
        propAlwaysShowSeconds = p.getValue("alwaysShowSeconds") as Boolean;
        propFieldLayout = p.getValue("fieldLayout") as Number;
        propLeftValueShows = p.getValue("leftValueShows") as Number;
        propMiddleValueShows = p.getValue("middleValueShows") as Number;
        propRightValueShows = p.getValue("rightValueShows") as Number;
        propFourthValueShows = p.getValue("fourthValueShows") as Number;
        propBottomFieldShows = p.getValue("bottomFieldShows") as Number;
        loadBottomField2Property();
        propLeftBarShows = p.getValue("leftBarShows") as Number;
        propRightBarShows = p.getValue("rightBarShows") as Number;
        propSideBarWidth = p.getValue("sideBarWidth") as Number;
        propLimitBarHeight = p.getValue("limitBarHeight") as Boolean;
        propIcon1 = p.getValue("icon1") as Number;
        propIcon2 = p.getValue("icon2") as Number;
        propBatteryVariant = p.getValue("batteryVariant") as Number;

        propUpdateFreq = p.getValue("updateFreq") as Number;
        propShowClockBg = p.getValue("showClockBg") as Boolean;
        propShowDataBg = p.getValue("showDataBg") as Boolean;
        propAodStyle = p.getValue("aodStyle") as Number;
        propAodFieldShows = p.getValue("aodFieldShows") as Number;
        propAodRightFieldShows = p.getValue("aodRightFieldShows") as Number;
        propAodAlignment = p.getValue("aodAlignment") as Number;
        propDateAlignment = p.getValue("dateAlignment") as Number;
        propBottomFieldAlignment = p.getValue("bottomFieldAlignment") as Number;
        propBottomFieldLabelAlignment = p.getValue("bottomFieldLabelAlignment") as Number;
        propHemisphere = p.getValue("hemisphere") as Number;
        propHourFormat = p.getValue("hourFormat") as Number;
        propZeropadHour = p.getValue("zeropadHour") as Boolean;
        propIs24H = System.getDeviceSettings().is24Hour;
        propTimeSeparator = p.getValue("timeSeparator") as Number;
        // propTimeSeparator Auto (4): if 12h time use AM/PM (3), if 24h time use : (4)
        if (propTimeSeparator == 4) {
            if ((!propIs24H and propHourFormat == 0) or propHourFormat == 2) { propTimeSeparator = 3; } else { propTimeSeparator = 0; }
        }
        propTempUnit = p.getValue("tempUnit") as Number;
        propShowTempUnit = p.getValue("showTempUnit") as Boolean;
        propDistanceUnit = p.getValue("distanceUnit") as Number;
        propIsMetricDistance = (System.getDeviceSettings().distanceUnits == System.UNIT_METRIC and propDistanceUnit == 0) or propDistanceUnit == 1;
        propWindUnit = p.getValue("windUnit") as Number;
        propPrecipAmountUnit = p.getValue("precipAmountUnit") as Number;
        propPressureUnit = p.getValue("pressureUnit") as Number;
        propLabelVisibility = p.getValue("labelVisibility") as Number;
        propDateFormat = p.getValue("dateFormat") as Number;
        propDateCustomFormat = p.getValue("dateCustomFormat") as String;
        propNotificationCountShows = p.getValue("notificationCountShows") as Number;
        propSecondsShows = p.getValue("secondsShows") as Number;
        propTzOffset1 = p.getValue("tzOffset1") as Number;
        propTzOffset2 = p.getValue("tzOffset2") as Number;
        propTzName1 = p.getValue("tzName1") as String;
        propTzName2 = p.getValue("tzName2") as String;
        propTzHourFormat = p.getValue("tzHourFormat") as Number;
        propWeekOffset = p.getValue("weekOffset") as Number;
        propSmallFontVariant = p.getValue("smallFontVariant") as Number;
        propBottomFontVariant = p.getValue("bottomFontVariant") as Number;
        propStressDynamicColor = p.getValue("stressDynamicColor") as Boolean;
        propWeatherProvider = p.getValue("weatherProvider") as Number;

        theme.resetNightMode(); // force update color theme
        updateColorTheme();
        updateActiveLabels();

        if(propTimeSeparator == 2) {
            clockBgText = "####";
        } else if(propTimeSeparator == 3) {
            clockBgText = "####B";
        } else {
            if(propClockFont == 2) {
                clockBgText = "## ##";
            } else {
                clockBgText = "#####";
            }
        }
    }

    hidden function getValueForSeconds(now as Gregorian.Info) as String {
        if(propSecondsShows == -3) {
            // updateSeconds logic
            if(isSleeping and (!propAlwaysShowSeconds or canBurnIn)) {
                return "";
            } else {
                return now.sec.format("%02d");
            }
        }
        return getValueByType(propSecondsShows, 5);
    }

    hidden function getClockData(now as Gregorian.Info) as String {
        var separator = ":";
        var after = "";
        if(propTimeSeparator == 1) { separator = " "; }
        if(propTimeSeparator == 2) { separator = ""; }
        if(propTimeSeparator == 3) {
            separator = ""; 
            if(now.hour >= 12) { after = "P"; } else { after = "A"; }
        }

        if(propZeropadHour) {
            return formatHour(now.hour, propIs24H, propHourFormat).format("%02d") + separator + now.min.format("%02d") + after;
        } else {
            return formatHour(now.hour, propIs24H, propHourFormat).format("%2d") + separator + now.min.format("%02d") + after;
        }
    }

    hidden function updateWeather() as Void {
        if (propWeatherProvider == 1) {
            // OWM provider: background service delegate handles fetching.
            // The view only reads the results from Application.Storage.
            owmError = Application.Storage.getValue("owm_error") as String?;
            try { weatherCondition = readWeatherData(); } catch(e) {}
        } else {
            // Garmin provider: original behavior unchanged.
            owmError = null;
            if (Weather.getCurrentConditions() != null) {
                try { storeWeatherData(); } catch(e) {}
            }
            try { weatherCondition = readWeatherData(); } catch(e) {}
        }
        cachedTempUnit = weatherHelper.getTempUnit(propTempUnit);
        weatherHelper.update(weatherCondition, owmError, cachedTempUnit, propShowTempUnit, propWindUnit, propPrecipAmountUnit, propIs24H, propHourFormat);
    }

    hidden function computeCcHash(cc) as Number {
        if (cc == null) { return 0; }
        var h = 17;
        var t = (cc.temperature != null) ? cc.temperature : -127;
        h = 31 * h + t;
        var c = (cc.condition != null) ? cc.condition : -1;
        h = 31 * h + c;
        var w = (cc.windSpeed != null) ? cc.windSpeed.toNumber() : -1;
        h = 31 * h + w;
        var b = (cc.windBearing != null) ? cc.windBearing : -1;
        h = 31 * h + b;

        return h;
    }

    hidden function storeWeatherData() as Void {
        var now = Time.now().value();
        var sysStats = System.getSystemStats();

        if (!isLowMem && sysStats.freeMemory < 15000) {
            isLowMem = true;
            Application.Storage.setValue("hourly_forecast", []); 
            lastHfTime = null; 
        } else if (isLowMem && sysStats.freeMemory > 17000) {
            isLowMem = false;
        }

        var cc = Weather.getCurrentConditions();
        var newCcHash = computeCcHash(cc);

        if (lastCcHash == null || lastCcHash != newCcHash) {
            var cc_data = {};
            if(cc != null) {
                if(cc.observationLocationPosition != null) {
                    cc_data["observationLocationPosition"] = cc.observationLocationPosition.toDegrees();
                }
                if(cc.condition != null) { cc_data["condition"] = cc.condition; }
                if(cc.highTemperature != null) { cc_data["highTemperature"] = cc.highTemperature; }
                if(cc.lowTemperature != null) { cc_data["lowTemperature"] = cc.lowTemperature; }
                if(cc.precipitationChance != null) { cc_data["precipitationChance"] = cc.precipitationChance; }
                if(cc.relativeHumidity != null) { cc_data["relativeHumidity"] = cc.relativeHumidity; }
                if(cc.temperature != null) { cc_data["temperature"] = cc.temperature; }
                if(cc.feelsLikeTemperature != null) { cc_data["feelsLikeTemperature"] = cc.feelsLikeTemperature; }
                if(cc.windBearing != null) { cc_data["windBearing"] = cc.windBearing; }
                if(cc.windSpeed != null) { cc_data["windSpeed"] = cc.windSpeed; }
                if(cc.uvIndex != null) { cc_data["uvIndex"] = cc.uvIndex; }
                if(cc.observationTime != null) { cc_data["observationTime"] = cc.observationTime.value(); }
            }

            cc_data["timestamp"] = now;
            Application.Storage.setValue("current_conditions", cc_data);
            
            lastCcHash = newCcHash;
        }

        if (isLowMem) { return; }

        var hf = Weather.getHourlyForecast();
        
        if (hf == null || hf.size() == 0) { return; }

        var firstForecastTime = hf[0].forecastTime.value();

        if (lastHfTime == null || lastHfTime != firstForecastTime) {
            var hf_data = [];
            
            for(var i=0; i<hf.size(); i++) {
                var tmp = {
                    "forecastTime" => hf[i].forecastTime.value(),
                    "condition" => hf[i].condition,
                    "precipitationChance" => hf[i].precipitationChance,
                    "temperature" => hf[i].temperature,
                    "windBearing" => hf[i].windBearing,
                    "windSpeed" => hf[i].windSpeed
                };
                if(hf[i].uvIndex != null) { tmp["uvIndex"] = hf[i].uvIndex; }
                
                hf_data.add(tmp);
            }

            Application.Storage.setValue("hourly_forecast", hf_data);
            lastHfTime = firstForecastTime;
        }
    }

    hidden function readWeatherData() as StoredWeather {
        var ret = new StoredWeather();
        var now = Time.now().value();
        var cc_data = Application.Storage.getValue("current_conditions") as Dictionary<String, Application.PropertyValueType>?;
        if(cc_data == null) { return ret; }
        
        var data_age_s = now - (cc_data.get("timestamp") as Number);
        var pos = cc_data.get("observationLocationPosition") as Array?;
        if (pos != null) {
            ret.observationLocationPosition = new Position.Location({:latitude => pos[0], :longitude => pos[1], :format => :degrees});
        }
        var hf_data = Application.Storage.getValue("hourly_forecast") as Array?;

        // Find the nearest forecast entry by absolute time distance (past or future).
        // Used to supplement fields missing from current conditions (e.g. windGust,
        // precipitationAmount which OWM only reports "where available" in current obs).
        var nearestEntry = null as Dictionary?;
        if (hf_data != null) {
            var nearestDist = 2147483647;
            for (var i = 0; i < hf_data.size(); i++) {
                var diff = now - (hf_data[i].get("forecastTime") as Number);
                if (diff < 0) { diff = -diff; }
                if (diff < nearestDist) { nearestDist = diff; nearestEntry = hf_data[i]; }
            }
        }

        // Current conditions are valid for at least 1 hour (Garmin path), or until the
        // first forecast slot starts — whichever is later. For OWM the first slot is always
        // in the future (~3h boundary), so this covers the gap without regressing Garmin.
        var ccTimestamp = cc_data.get("timestamp") as Number;
        var ccValidUntil = ccTimestamp + 3600;
        if (hf_data != null && hf_data.size() > 0) {
            var firstForecastTime = hf_data[0].get("forecastTime") as Number;
            if (firstForecastTime > ccValidUntil) { ccValidUntil = firstForecastTime; }
        }
        if(data_age_s >= 0 and now < ccValidUntil) {
            ret.condition = cc_data.get("condition") as Number;
            ret.highTemperature = cc_data.get("highTemperature") as Number;
            ret.lowTemperature = cc_data.get("lowTemperature") as Number;
            ret.precipitationChance = cc_data.get("precipitationChance") as Number;
            ret.relativeHumidity = cc_data.get("relativeHumidity") as Number;
            ret.temperature = cc_data.get("temperature") as Number;
            ret.feelsLikeTemperature = cc_data.get("feelsLikeTemperature") as Float;
            ret.windBearing = cc_data.get("windBearing") as Number;
            ret.windSpeed = cc_data.get("windSpeed") as Float;
            ret.windGust = cc_data.get("windGust") as Float;
            ret.precipitationAmount = cc_data.get("precipitationAmount") as Float;
            ret.uvIndex = cc_data.get("uvIndex") as Float;
            ret.cityName = cc_data.get("cityName") as String?;
            var obsTime = cc_data.get("observationTime");
            if (obsTime == null) { obsTime = cc_data.get("timestamp"); }
            ret.observationTimestamp = obsTime as Number;
            // OWM only includes windGust and precipitationAmount "where available" in
            // current conditions. Fill gaps from the nearest forecast entry.
            if (ret.windGust == null && nearestEntry != null) {
                ret.windGust = nearestEntry.get("windGust") as Float;
            }
            if (ret.precipitationAmount == null && nearestEntry != null) {
                ret.precipitationAmount = nearestEntry.get("precipitationAmount") as Float;
            }
        } else {
            if(hf_data == null) { return ret; }
            // Find the most recently passed slot. When now >= firstForecastTime there is
            // always at least one past entry, so no nearest-future fallback is needed.
            var bestEntry = null;
            var bestAge = 86401;
            for(var i=0; i<hf_data.size(); i++) {
                var forecast_age = now - (hf_data[i].get("forecastTime") as Number);
                if(forecast_age >= 0 and forecast_age < bestAge) {
                    bestAge = forecast_age;
                    bestEntry = hf_data[i];
                }
            }
            if(bestEntry != null) {
                ret.condition = bestEntry.get("condition") as Number;
                ret.temperature = bestEntry.get("temperature") as Number;
                ret.precipitationChance = bestEntry.get("precipitationChance") as Number;
                ret.windBearing = bestEntry.get("windBearing") as Number;
                ret.windSpeed = bestEntry.get("windSpeed") as Float;
                ret.windGust = bestEntry.get("windGust") as Float;
                ret.precipitationAmount = bestEntry.get("precipitationAmount") as Float;
                // Forecast entries lack feelsLike/humidity/high/low — use last known values.
                ret.feelsLikeTemperature = cc_data.get("feelsLikeTemperature") as Float;
                ret.relativeHumidity = cc_data.get("relativeHumidity") as Number;
                ret.highTemperature = cc_data.get("highTemperature") as Number;
                ret.lowTemperature = cc_data.get("lowTemperature") as Number;
                ret.uvIndex = cc_data.get("uvIndex") as Float;
                var obsTime2 = cc_data.get("observationTime");
                if (obsTime2 == null) { obsTime2 = cc_data.get("timestamp"); }
                ret.observationTimestamp = obsTime2 as Number;
            }
        }
        
        return ret;
    }

    hidden function getValueByTypeWithUnit(complicationType as Number, width as Number) as String {
        var unit = getUnitByType(complicationType);
        if (unit.length() > 0) {
            unit = " " + unit;
        }
        return getValueByType(complicationType, width) + unit;
    }

    hidden function getUnitByType(complicationType) as String {
        var unit = "";
        if(complicationType == 10) { // Calories / day
            unit = Application.loadResource(Rez.Strings.UNIT_KCAL);
        } else if(complicationType == 11) { // Altitude (m)
            unit = Application.loadResource(Rez.Strings.UNIT_M);
        } else if(complicationType == 14) { // Altitude (ft)
            unit = Application.loadResource(Rez.Strings.UNIT_FT);
        } else if(complicationType == 16) { // Steps / day
            unit = Application.loadResource(Rez.Strings.UNIT_STEPS);
        } else if(complicationType == 18) { // Wheelchair pushes
            unit = Application.loadResource(Rez.Strings.UNIT_PUSHES);
        } else if(complicationType == 25) { // Active calories / day
            unit = Application.loadResource(Rez.Strings.UNIT_KCAL);
        } else if(complicationType == 46) { // Active/Total calories / day
            unit = Application.loadResource(Rez.Strings.UNIT_KCAL);
        }
        return unit;
    }

    hidden function getValueByType(complicationType as Number, width as Number) as String {
        var val = "";
        var numberFormat = "%d";
        var activityInfo = null;

        if(complicationType == -2) { // Hidden
            return "";
        } else if(complicationType == -1) { // Date
            val = formatDate(propDateFormat, propDateCustomFormat, propFontSize, propWeekOffset);
        } else if(complicationType == 0) { // Active min / week
            activityInfo = ActivityMonitor.getInfo();
            if(activityInfo.activeMinutesWeek != null) {
                val = activityInfo.activeMinutesWeek.total.format(numberFormat);
            }
        } else if(complicationType == 62) { // Active hours / week
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.activeMinutesWeek != null) {
                val = (activityInfo.activeMinutesWeek.total / 60.0).format("%.1f");
            }
        } else if(complicationType == 1) { // Active min / day
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.activeMinutesDay != null) {
                val = activityInfo.activeMinutesDay.total.format(numberFormat);
            }
        } else if(complicationType == 2) { // distance / day
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.distance != null) {
                val = formatDistanceByWidth(activityInfo.distance / (propIsMetricDistance ? 100000.0 : 160900.0), width);
            }
        } else if(complicationType == 3) { // floors climbed / day
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.floorsClimbed != null) {
                val = activityInfo.floorsClimbed.format(numberFormat);
            }
        } else if(complicationType == 4) { // meters climbed / day
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.metersClimbed != null) {
                val = activityInfo.metersClimbed.format(numberFormat);
            }
        } else if(complicationType == 5) { // Time to Recovery (h)
            val = complications.getRecoveryTimeVal(numberFormat);

        } else if(complicationType == 6) { // VO2 Max Running
            var profile = UserProfile.getProfile();
            if(profile.vo2maxRunning != null) {
                val = complications.vo2RunTrend + (profile.vo2maxRunning as Number).format(numberFormat);
            }
        } else if(complicationType == 7) { // VO2 Max Cycling
            var profile = UserProfile.getProfile();
            if(profile.vo2maxCycling != null) {
                val = complications.vo2BikeTrend + (profile.vo2maxCycling as Number).format(numberFormat);
            }
        } else if(complicationType == 8) { // Respiration rate
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.respirationRate != null) {
                val = activityInfo.respirationRate.format(numberFormat);
            }
        } else if(complicationType == 9) {
            // Try to retrieve live HR from Activity::Info
            var activity_info = Activity.getActivityInfo();
            var sample = activity_info.currentHeartRate;
            if(sample != null) {
                val = sample.format("%01d");
            } else {
                var history = ActivityMonitor.getHeartRateHistory(1, /* newestFirst */ true);
                if (history != null) {
                    var hist = history.next();
                    if ((hist != null) && (hist.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                        val = hist.heartRate.format("%01d");
                    }
                }
            }
        } else if(complicationType == 10) { // Calories
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.calories != null) {
                val = activityInfo.calories.format(numberFormat);
            }
        } else if(complicationType == 11) { // Altitude (m)
                var alt = complications.getAltitudeValue();
                if (alt != null) {
                    val = alt.format(numberFormat);
            }
        } else if(complicationType == 12) { // Stress
        var st = getStressData();
            if(st != null) {
                val = st.format(numberFormat);
            }
        } else if(complicationType == 13) { // Body battery
            var bb = getBBData();
            if(bb != null) {
                val = bb.format(numberFormat);
            }
        } else if(complicationType == 14) { // Altitude (ft)
            var alt = complications.getAltitudeValue();
            if (alt != null) {
                val = (alt * 3.28084).format(numberFormat);
            }
        } else if(complicationType == 15) { // Alt TZ 1
            val = secondaryTimezone(propTzOffset1, width, propIs24H, propHourFormat, propTzHourFormat);
        } else if(complicationType == 16) { // Steps / day
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.steps != null) {
                var steps = activityInfo.steps;
                if(width >= 5) {
                    val = steps.format("%d");
                } else if(width == 4 and steps < 10000) {
                    val = steps.format("%d");
                } else {
                    val = (steps / 1000).format("%d") + "K";
                }
            }
        } else if(complicationType == 17) { // Distance (m) / day
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.distance != null) {
                val = (activityInfo.distance / 100).format(numberFormat);
            }
        } else if(complicationType == 18) { // Wheelchair pushes
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            if(activityInfo.pushes != null) {
                val = activityInfo.pushes.format(numberFormat);
            }
        } else if(complicationType == 19) { // Weekly run distance
            val = getWeeklyDistanceFromComplication(true, propIsMetricDistance ? 0.001 : 0.000621371, width);
        } else if(complicationType == 20) { // Weekly bike distance
            val = getWeeklyDistanceFromComplication(false, propIsMetricDistance ? 0.001 : 0.000621371, width);
        } else if(complicationType == 21) { // Training status
            val = complications.getTrainingStatusVal();
        } else if(complicationType == 22) { // Raw Barometric pressure (hPA)
            var info = Activity.getActivityInfo();
            if (info.rawAmbientPressure != null) {
                val = formatPressure(info.rawAmbientPressure / 100.0, width, propPressureUnit);
            }
        } else if(complicationType == 23) { // Weight kg
            var profile = UserProfile.getProfile();
            if(profile.weight != null) {
                var weight_kg = profile.weight / 1000.0;
                if (width == 3) {
                    val = weight_kg.format(numberFormat);
                } else {
                    val = weight_kg.format("%.1f");
                }
            }
        } else if(complicationType == 24) { // Weight lbs
            var profile = UserProfile.getProfile();
            if(profile.weight != null) {
                val = (profile.weight * 0.00220462).format(numberFormat);
            }
        } else if(complicationType == 25) { // Act Calories
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            var rest_calories = getRestCalories();
            // Get total calories and subtract rest calories
            if (activityInfo.calories != null && rest_calories > 0) {
                var active_calories = activityInfo.calories - rest_calories;
                if (active_calories > 0) {
                    val = active_calories.format(numberFormat);
                } else { val = "0"; }
            }
        } else if(complicationType == 26) { // Sea level pressure (hPA)
            var info = Activity.getActivityInfo();
            if (info.meanSeaLevelPressure != null) {
                val = formatPressure(info.meanSeaLevelPressure / 100.0, width, propPressureUnit);
            }
        } else if(complicationType == 27) { // Week number
            var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var week_number = isoWeekNumber(today.year, today.month, today.day, propWeekOffset);
            val = week_number.format(numberFormat);
        } else if(complicationType == 28 || complicationType == 29) { // Total distance past 7 days
            val = formatDistanceByWidth(getWeeklyDistance() * (propIsMetricDistance ? 0.00001 : 0.00000621371), width);
        } else if(complicationType == 30) { // Battery percentage
            var battery = System.getSystemStats().battery;
            val = battery.format("%d");
        } else if(complicationType == 31) { // Battery days remaining
            var stats35 = System.getSystemStats();
            if(stats35.batteryInDays != null) {
                val = Math.round(stats35.batteryInDays).format(numberFormat);
            }
        } else if(complicationType == 32) { // Notification count
            var notif_count = System.getDeviceSettings().notificationCount;
            if(notif_count != null) {
                if(notif_count == 0) {
                    val = ""; // Hide when zero
                } else {
                    val = notif_count.format(numberFormat);
                }
            }
        } else if(complicationType == 33) { // Solar intensity
            var stats37 = System.getSystemStats();
            if(stats37.solarIntensity != null) {
                val = stats37.solarIntensity.format(numberFormat);
            }
        } else if(complicationType == 34) { // Sensor temperature
            var tempIterator = Toybox.SensorHistory.getTemperatureHistory({:period => 1});
            if (tempIterator != null) {
                var temp = tempIterator.next();
                if(temp != null and temp.data != null) {
                    val = formatTemperature(convertTemperature(temp.data, cachedTempUnit), propShowTempUnit, cachedTempUnit);
                }
            }
        } else if(complicationType == 35 || complicationType == 36) { // Sunrise / Sunset
            if(weatherCondition != null) {
                var loc = weatherCondition.observationLocationPosition;
                if(loc != null) {
                    var now = Time.now();
                    var s = (complicationType == 35) ? Weather.getSunrise(loc, now) : Weather.getSunset(loc, now);
                    val = formatSunTime(s, width, propIs24H, propHourFormat);
                }
            }
        } else if(complicationType == 37) { // Alt TZ 2
            val = secondaryTimezone(propTzOffset2, width, propIs24H, propHourFormat, propTzHourFormat);
        } else if(complicationType == 38) { // Alarms
            val = System.getDeviceSettings().alarmCount.format(numberFormat);
        } else if(complicationType == 39) { // High temp
            if(weatherCondition != null and weatherCondition.highTemperature != null) {
                var tempVal = weatherCondition.highTemperature;
                val = formatTemperature(convertTemperature(tempVal, cachedTempUnit), propShowTempUnit, cachedTempUnit);
            }
        } else if(complicationType == 40) { // Low temp
            if(weatherCondition != null and weatherCondition.lowTemperature != null) {
                var tempVal = weatherCondition.lowTemperature;
                val = formatTemperature(convertTemperature(tempVal, cachedTempUnit), propShowTempUnit, cachedTempUnit);
            }
        } else if(complicationType == 41) { // Temperature
            val = weatherHelper.getTemperature();
        } else if(complicationType == 42) { // Precipitation chance
            val = weatherHelper.getPrecip();
            if(width == 3 and val.equals("100%")) { val = "100"; }
        } else if(complicationType == 43) { // Next Sun Event
            var nextSunEventArray = getNextSunEvent(weatherCondition);
            if(nextSunEventArray != null && nextSunEventArray.size() == 2) {
                val = formatSunTime(nextSunEventArray[0], width, propIs24H, propHourFormat);
            }
        } else if(complicationType == 44) { // Millitary Date Time Group
            val = getDateTimeGroup();
        } else if(complicationType == 45) { // Time of the next Calendar Event
            val = complications.getCalendarEventVal(width);
        } else if(complicationType == 46) { // Active / Total calories
            if(activityInfo == null) { activityInfo = ActivityMonitor.getInfo(); }
            var rest_calories = getRestCalories();
            var total_calories = 0;
            // Get total calories and subtract rest calories
            if (activityInfo.calories != null) {
                total_calories = activityInfo.calories;
            }
            var active_calories = total_calories - rest_calories;
            active_calories = (active_calories > 0) ? active_calories : 0; // Ensure active calories is not negative
            val = active_calories.format(numberFormat) + "/" + total_calories.format(numberFormat);
        } else if(complicationType == 47) { // PulseOx
            val = complications.getPulseOxVal(numberFormat);
        } else if(complicationType == 48) { // Location Long Lat dec deg
            var pos = Activity.getActivityInfo().currentLocation;
            if(pos != null) {
                val = pos.toDegrees()[0] + " " + pos.toDegrees()[1];
            } else {
                val = Application.loadResource(Rez.Strings.LABEL_POS_NA);
            }

        } else if(complicationType == 49) { // Location Millitary format
            var pos = Activity.getActivityInfo().currentLocation;
            if(pos != null) {
                val = pos.toGeoString(Position.GEO_MGRS);
            } else {
                val = Application.loadResource(Rez.Strings.LABEL_POS_NA);
            }

        } else if(complicationType == 50) { // Location Accuracy
            var acc = Activity.getActivityInfo().currentLocationAccuracy;
            if(acc != null) {
                if(width < 4) {
                    val = (acc as Number).format("%d");
                } else {
                    val = ["N/A", "LAST", "POOR", "USBL", "GOOD"][acc];
                }
            }
        } else if(complicationType == 51) { // UV Index
            val = weatherHelper.getUVIndex();
        } else if(complicationType == 52) { // Humidity
            val = weatherHelper.getHumidity();
        } else if(complicationType == 53) { // CGM Glucose + Trend
            val = complications.getCgmReading();
        } else if(complicationType == 54) { // CGM Age (minutes)
            val = complications.getCgmAge();
        } else if(complicationType == 55) { // Feels like
            val = weatherHelper.getFeelsLike();
        } else if(complicationType == 56) { // Hours to next sun event
            val = hoursToNextSunEvent(weatherCondition);
        } else if(complicationType == 57) { // Resting Heart Rate
            var profile = UserProfile.getProfile();
            if(profile.restingHeartRate != null) {
                val = profile.restingHeartRate.format(numberFormat);
            }
        } else if(complicationType == 58 || complicationType == 59) { // Run/bike distance past 7 days
            if(Time.now().value() - _lastActivityDistUpdate >= 60*5) {
                _lastActivityDistUpdate = Time.now().value();
                updateActivityDistCache();
            }
            var distFactor = propIsMetricDistance ? 0.001 : 0.000621371;
            val = formatDistanceByWidth((complicationType == 58 ? _cachedRunDist7Days : _cachedBikeDist7Days) * distFactor, width);
        } else if(complicationType == 65) { // Swim distance past 7 days
            if(Time.now().value() - _lastActivityDistUpdate >= 60*5) {
                _lastActivityDistUpdate = Time.now().value();
                updateActivityDistCache();
            }
            var distFactor = propIsMetricDistance ? 0.001 : 0.000621371;
            val = formatDistanceByWidth(_cachedSwimDist7Days * distFactor, width);
        } else if(complicationType == 66 || complicationType == 67) { // Run dist this month / past 28 days
            if(Time.now().value() - _lastActivityDistUpdate >= 60*5) {
                _lastActivityDistUpdate = Time.now().value();
                updateActivityDistCache();
            }
            var distFactor = propIsMetricDistance ? 0.001 : 0.000621371;
            val = formatDistanceByWidth((complicationType == 66 ? _cachedRunDistMonth : _cachedRunDist28Days) * distFactor, width);
        } else if(complicationType == 60) { // Weather data 1 format string
            val = weatherHelper.getWeatherByFormat(propWeatherFormat1);
        } else if(complicationType == 61) { // Weather data 2 format string
            val = weatherHelper.getWeatherByFormat(propWeatherFormat2);
        } else if(complicationType == 63 || complicationType == 64) { // Civil dawn / Civil dusk
            if(weatherCondition != null) {
                var loc = weatherCondition.observationLocationPosition;
                if(loc != null) {
                    var now = Time.now();
                    var sunrise = Weather.getSunrise(loc, now);
                    var sunset = Weather.getSunset(loc, now);
                    if(sunrise != null && sunset != null) {
                        var latDeg = loc.toDegrees()[0];
                        var twilight = getCivilTwilight(latDeg as Double, sunrise, sunset);
                        if(twilight != null) {
                            val = formatSunTime(complicationType == 63 ? twilight[0] : twilight[1], width, propIs24H, propHourFormat);
                        }
                    }
                }
            }
        } else if(complicationType == 68) { // Daily counter (resets at midnight)
            var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var todayKey = today.year * 10000 + today.month * 100 + today.day;
            var storedKey = Application.Storage.getValue("dailyCounterDay") as Number?;
            if(storedKey == null || storedKey != todayKey) {
                Application.Storage.setValue("dailyCounterDay", todayKey);
                Application.Storage.setValue("dailyCounter", 0);
            }
            var count = Application.Storage.getValue("dailyCounter") as Number?;
            val = (count != null ? count : 0).format(numberFormat);
        }

        return val;
    }

    hidden function getLabelByType(complicationType as Number, labelSize as Number) as String {
        // labelSize 1 = short, 2 = mid
        if(complicationType == 15) { return propTzName1.toUpper() + ":"; }
        if(complicationType == 37) { return propTzName2.toUpper() + ":"; }
        switch(complicationType) {
            case 0: return formatLabel(Rez.Strings.LABEL_WMIN_1, Rez.Strings.LABEL_WMIN_2, labelSize);
            case 62: return formatLabel(Rez.Strings.LABEL_WHRS_1, Rez.Strings.LABEL_WHRS_2, labelSize);
            case 1: return formatLabel(Rez.Strings.LABEL_DMIN_1, Rez.Strings.LABEL_DMIN_2, labelSize);
            case 2:
                if(propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_DKM_1, Rez.Strings.LABEL_DKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_DMI_1, Rez.Strings.LABEL_DMI_2, labelSize);
            case 3: return Application.loadResource(Rez.Strings.LABEL_FLOORS);
            case 4: return formatLabel(Rez.Strings.LABEL_CLIMB_1, Rez.Strings.LABEL_CLIMB_2, labelSize);
            case 5: return formatLabel(Rez.Strings.LABEL_RECOV_1, Rez.Strings.LABEL_RECOV_2, labelSize);
            case 6: return formatLabel(Rez.Strings.LABEL_VO2_1, Rez.Strings.LABEL_VO2RUN_2, labelSize);
            case 7: return formatLabel(Rez.Strings.LABEL_VO2_1, Rez.Strings.LABEL_VO2BIKE_2, labelSize);
            case 8: return formatLabel(Rez.Strings.LABEL_RESP_1, Rez.Strings.LABEL_RESP_2, labelSize);
            case 9: return Application.loadResource(Rez.Strings.LABEL_HR);
            case 10: return formatLabel(Rez.Strings.LABEL_CAL_1, Rez.Strings.LABEL_CAL_2, labelSize);
            case 11: return formatLabel(Rez.Strings.LABEL_ALT_1, Rez.Strings.LABEL_ALT_2, labelSize);
            case 12: return Application.loadResource(Rez.Strings.LABEL_STRESS);
            case 13: return formatLabel(Rez.Strings.LABEL_BBAT_1, Rez.Strings.LABEL_BBAT_2, labelSize);
            case 14: return formatLabel(Rez.Strings.LABEL_ALT_1, Rez.Strings.LABEL_ALT_2, labelSize);
            case 16: return Application.loadResource(Rez.Strings.LABEL_STEPS);
            case 17: return formatLabel(Rez.Strings.LABEL_DIST_1, Rez.Strings.LABEL_DIST_2, labelSize);
            case 18: return Application.loadResource(Rez.Strings.LABEL_PUSHES);
            case 66:
            case 67:
                if(propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_MKM_1, Rez.Strings.LABEL_MRUNKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_MMI_1, Rez.Strings.LABEL_MRUNMI_2, labelSize);
            case 58:
            case 19:
                if(propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WRUNM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WRUNMI_2, labelSize);
            case 59:
            case 20:
                if(propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WBIKEKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WBIKEMI_2, labelSize);
            case 21: return Application.loadResource(Rez.Strings.LABEL_TRAINING);
            case 22: return Application.loadResource(Rez.Strings.LABEL_PRESSURE);
            case 23: return formatLabel(Rez.Strings.LABEL_KG_1, Rez.Strings.LABEL_WEIGHT_2, labelSize);
            case 24: return formatLabel(Rez.Strings.LABEL_LBS_1, Rez.Strings.LABEL_WEIGHT_2, labelSize);
            case 25: return formatLabel(Rez.Strings.LABEL_ACAL_1, Rez.Strings.LABEL_ACAL_2, labelSize);
            case 26: return Application.loadResource(Rez.Strings.LABEL_PRESSURE);
            case 27: return Application.loadResource(Rez.Strings.LABEL_WEEK);
            case 29:
            case 28:
                if(propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WDISTKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WDISTMI_2, labelSize);
            case 30: return formatLabel(Rez.Strings.LABEL_BATT_1, Rez.Strings.LABEL_BATT_2, labelSize);
            case 31: return formatLabel(Rez.Strings.LABEL_BATTD_1, Rez.Strings.LABEL_BATTD_2, labelSize);
            case 32: return formatLabel(Rez.Strings.LABEL_NOTIFS_1, Rez.Strings.LABEL_NOTIFS_1, labelSize);
            case 33: return formatLabel(Rez.Strings.LABEL_SUN_1, Rez.Strings.LABEL_SUNINT_2, labelSize);
            case 34: return formatLabel(Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_STEMP_2, labelSize);
            case 35: return formatLabel(Rez.Strings.LABEL_SUNRISE_1, Rez.Strings.LABEL_SUNRISE_2, labelSize);
            case 36: return formatLabel(Rez.Strings.LABEL_SUNSET_1, Rez.Strings.LABEL_SUNSET_2, labelSize);
            case 38: return formatLabel(Rez.Strings.LABEL_ALARM_1, Rez.Strings.LABEL_ALARM_2, labelSize);
            case 39: return formatLabel(Rez.Strings.LABEL_HIGH_1, Rez.Strings.LABEL_HIGH_2, labelSize);
            case 40: return formatLabel(Rez.Strings.LABEL_LOW_1, Rez.Strings.LABEL_LOW_2, labelSize);
            case 41: return formatLabel(Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_TEMP_1, labelSize);
            case 42: return formatLabel(Rez.Strings.LABEL_PRECIP_1, Rez.Strings.LABEL_PRECIP_1, labelSize);
            case 43: return formatLabel(Rez.Strings.LABEL_NEXTSUN_1, Rez.Strings.LABEL_NEXTSUN_2, labelSize);
            case 45: return formatLabel(Rez.Strings.LABEL_NEXTCAL_1, Rez.Strings.LABEL_NEXTCAL_2, labelSize);
            case 47: return formatLabel(Rez.Strings.LABEL_OX_1, Rez.Strings.LABEL_OX_2, labelSize);
            case 50: return formatLabel(Rez.Strings.LABEL_ACC_1, Rez.Strings.LABEL_ACC_2, labelSize);
            case 51: return formatLabel(Rez.Strings.LABEL_UV_1, Rez.Strings.LABEL_UV_2, labelSize);
            case 52: return formatLabel(Rez.Strings.LABEL_HUM_1, Rez.Strings.LABEL_HUM_2, labelSize);
            case 53: return WatchUi.loadResource(Rez.Strings.LABEL_CGM) as String;
            case 54: return WatchUi.loadResource(Rez.Strings.LABEL_CGMAGE) as String;
            case 55: return formatLabel(Rez.Strings.LABEL_FL, Rez.Strings.LABEL_FL_2, labelSize);
            case 56: return formatLabel(Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_1, Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_1, labelSize);
            case 57: return formatLabel(Rez.Strings.LABEL_RHR_1, Rez.Strings.LABEL_RHR_2, labelSize);
            case 63: return Application.loadResource(Rez.Strings.LABEL_DAWN_1) as String;
            case 64: return Application.loadResource(Rez.Strings.LABEL_DUSK_1) as String;
            case 65:
                if(propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WSWIMKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WSWIMMI_2, labelSize);
            case 68: return formatLabel(Rez.Strings.LABEL_CNT_1, Rez.Strings.LABEL_CNT_2, labelSize);
        }
        return "";
    }
    // Square helper functions - only compiled for square devices
    (:Square)
    hidden function loadBottomField2Property() as Void {
        propBottomField2Shows = Application.Properties.getValue("bottomField2Shows") as Number;
    }

    (:Square)
    hidden function computeBottomField2Values(values as Dictionary) as Void {
        values[:dataBottom2] = getValueByType(propBottomField2Shows, 5);
        if (propBottomFieldShows != -2 and propBottomField2Shows != -2) {
            values[:dataLabelBottom] = getLabelByType(propBottomFieldShows, 2);
            values[:dataLabelBottom2] = getLabelByType(propBottomField2Shows, 2);
        }
    }

    (:Square)
    hidden function calculateSquareLayout() as Void {
        dualBottomFieldActive = (propBottomFieldShows != -2 and propBottomField2Shows != -2);
        bottomFiveYOriginal = bottomFiveY;

        if (dualBottomFieldActive) {
            // Position two 5-digit fields with 40px gap between them, centered
            var fieldWidth = bottomDataWidth * 5;
            var gap = 20;

            bottomFive1X = centerX - (gap / 2) - (fieldWidth / 2);
            bottomFive2X = centerX + (gap / 2) + (fieldWidth / 2);

            // Shift the entire row DOWN to make room for labels above (only if labels visible)
            if (propLabelVisibility == 0 or propLabelVisibility == 2) {
                bottomFiveY = bottomFiveY + labelHeight + labelMargin;
            }
        } else {
            // Single field mode - center position
            bottomFive1X = centerX;
            bottomFive2X = centerX;
        }
    }

    // Non-Square stubs for other devices
    (:Round)
    hidden function calculateSquareLayout() as Void {
        // No-op for non-square devices
    }

    (:Round)
    hidden function loadBottomField2Property() as Void {
        // No-op for non-square devices devices
    }

    (:Round)
    hidden function computeBottomField2Values(values as Dictionary) as Void {
        // No-op for non-square devices devices
    }

    hidden function drawIconWithOverlay(dc as Dc, x as Number, y as Number, justify as Number, iconStr as String, countStr as String, iconColor as Number?) as Void {
        dc.setColor(iconColor != null ? iconColor : theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fontIcons, iconStr, justify | Graphics.TEXT_JUSTIFY_VCENTER);
        if(!countStr.equals("")) {
            var labelX = justify == Graphics.TEXT_JUSTIFY_RIGHT ? x - 8 : x + 10;
            dc.setColor(theme.colors[bg], Graphics.COLOR_TRANSPARENT);
            dc.drawText(labelX, y - 4, fontLabel, countStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(theme.colors[dataVal], Graphics.COLOR_TRANSPARENT);
        }
    }

    (:Square)
    hidden function drawBottomFieldsWithIcons(dc as Dc, values as Dictionary) as Void {
        if (dualBottomFieldActive) {
            var field1Width = bottomDataWidth * 5;
            var field2Width = bottomDataWidth * 5;
            var field1Left = bottomFive1X - (field1Width / 2);
            var field2Left = bottomFive2X - (field2Width / 2);

            // Draw labels above fields - left aligned with field edge
            if (propLabelVisibility == 0 or propLabelVisibility == 2) {
                dc.setColor(theme.colors[fieldLbl], Graphics.COLOR_TRANSPARENT);
                dc.drawText(field1Left, bottomFiveYOriginal, fontLabel, values[:dataLabelBottom], Graphics.TEXT_JUSTIFY_LEFT);
                dc.drawText(field2Left, bottomFiveYOriginal, fontLabel, values[:dataLabelBottom2], Graphics.TEXT_JUSTIFY_LEFT);
            }

            // Draw both fields
            drawDataField(dc, bottomFive1X, bottomFiveY, 3,
                null, values[:dataBottom], 5,
                fontBottomData, field1Width);

            drawDataField(dc, bottomFive2X, bottomFiveY, 3,
                null, values[:dataBottom2], 5,
                fontBottomData, field2Width);

            // Icons on outer edges
            drawIconWithOverlay(dc, field1Left - (marginX / 2),
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                Graphics.TEXT_JUSTIFY_RIGHT, values[:dataIcon1], values[:dataIcon1Count] as String, values[:dataIcon1Color] as Number?);
            drawIconWithOverlay(dc, field2Left + field2Width + (marginX / 2) - 2,
                bottomFiveY + (largeDataHeight / 2) + iconYAdj,
                Graphics.TEXT_JUSTIFY_LEFT, values[:dataIcon2], values[:dataIcon2Count] as String, values[:dataIcon2Color] as Number?);
        } else {
            // Single field - original behavior
            var step_width = drawDataField(dc, centerX, bottomFiveY, 3, null, values[:dataBottom], 5, fontBottomData, bottomDataWidth * 5);

            // Draw icons
            if(propFontSize == 1 and step_width == 0) {
                var y = 0;
                if(screenWidth <= 280) {
                    step_width = 45;
                    y = screenHeight - 28;
                } else {
                    step_width = 65;
                    y = screenHeight - 31;
                }
                drawIconWithOverlay(dc, centerX - (step_width / 2) - (marginX / 2), y, Graphics.TEXT_JUSTIFY_RIGHT, values[:dataIcon1], values[:dataIcon1Count] as String, values[:dataIcon1Color] as Number?);
                drawIconWithOverlay(dc, centerX + (step_width / 2) + (marginX / 2) - 2, y, Graphics.TEXT_JUSTIFY_LEFT, values[:dataIcon2], values[:dataIcon2Count] as String, values[:dataIcon2Color] as Number?);
            } else {
                drawIconWithOverlay(dc, centerX - (step_width / 2) - (marginX / 2), bottomFiveY + (largeDataHeight / 2) + iconYAdj, Graphics.TEXT_JUSTIFY_RIGHT, values[:dataIcon1], values[:dataIcon1Count] as String, values[:dataIcon1Color] as Number?);
                drawIconWithOverlay(dc, centerX + (step_width / 2) + (marginX / 2) - 2, bottomFiveY + (largeDataHeight / 2) + iconYAdj, Graphics.TEXT_JUSTIFY_LEFT, values[:dataIcon2], values[:dataIcon2Count] as String, values[:dataIcon2Color] as Number?);
            }
        }
    }

    (:Round)
    hidden function drawBottomFieldsWithIcons(dc as Dc, values as Dictionary) as Void {
        var step_width = drawDataField(dc, centerX, bottomFiveY, 3, null, values[:dataBottom], 5, fontBottomData, bottomDataWidth * 5);

        // Draw icons
        if(propFontSize == 1 and step_width == 0) {
            var y = 0;
            if(screenWidth <= 280) {
                step_width = 45;
                y = screenHeight - 28;
            } else {
                step_width = 65;
                y = screenHeight - 31;
            }
            drawIconWithOverlay(dc, centerX - (step_width / 2) - (marginX / 2), y, Graphics.TEXT_JUSTIFY_RIGHT, values[:dataIcon1], values[:dataIcon1Count] as String, values[:dataIcon1Color] as Number?);
            drawIconWithOverlay(dc, centerX + (step_width / 2) + (marginX / 2) - 2, y, Graphics.TEXT_JUSTIFY_LEFT, values[:dataIcon2], values[:dataIcon2Count] as String, values[:dataIcon2Color] as Number?);
        } else {
            drawIconWithOverlay(dc, centerX - (step_width / 2) - (marginX / 2), bottomFiveY + (largeDataHeight / 2) + iconYAdj, Graphics.TEXT_JUSTIFY_RIGHT, values[:dataIcon1], values[:dataIcon1Count] as String, values[:dataIcon1Color] as Number?);
            drawIconWithOverlay(dc, centerX + (step_width / 2) + (marginX / 2) - 2, bottomFiveY + (largeDataHeight / 2) + iconYAdj, Graphics.TEXT_JUSTIFY_LEFT, values[:dataIcon2], values[:dataIcon2Count] as String, values[:dataIcon2Color] as Number?);
        }
    }

}

(:background_excluded)
class Segment34Delegate extends WatchUi.WatchFaceDelegate {
    var screenW = null;
    var screenH = null;
    var view as Segment34View;

    public function initialize(v as Segment34View) {
        WatchFaceDelegate.initialize();
        screenW = System.getDeviceSettings().screenWidth;
        screenH = System.getDeviceSettings().screenHeight;
        view = v;
    }

    public function onPress(clickEvent as WatchUi.ClickEvent) {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];

        if(y < screenH / 3) {
            handlePress("pressToOpenTop");
        } else if (y < (screenH / 3) * 2) {
            handlePress("pressToOpenMiddle");
        } else if (x < screenW / 3) {
            handlePress("pressToOpenBottomLeft");
        } else if (x < (screenW / 3) * 2) {
            handlePress("pressToOpenBottomCenter");
        } else {
            handlePress("pressToOpenBottomRight");
        }

        return true;
    }

    function handlePress(areaSetting as String) {
        var cID = Application.Properties.getValue(areaSetting) as Complications.Type;

        if(cID == -1) {
            switch(view.nightModeOverride) {
                case 1:
                    view.nightModeOverride = 0;
                    view.infoMessage = "DAY THEME";
                    break;
                case 0:
                    view.nightModeOverride = -1;
                    view.infoMessage = "THEME AUTO";
                    break;
                default:
                    view.nightModeOverride = 1;
                    view.infoMessage = "NIGHT THEME";
            }
            view.onSettingsChanged();
        }

        if(cID == -2 || cID == -3) { // Increase / decrease counter
            var count = Application.Storage.getValue("dailyCounter") as Number?;
            var newCount = (count != null ? count : 0) + (cID == -2 ? 1 : -1);
            Application.Storage.setValue("dailyCounter", newCount);
            view.forceDataRefresh();
            WatchUi.requestUpdate();
        }

        if(cID != null and cID > 0) {
            try {
                Complications.exitTo(new Id(cID));
            } catch (e) {}
        }
    }

}

(:background_excluded)
class StoredWeather {
    public var observationLocationPosition as Position.Location or Null;
    public var precipitationChance as Lang.Number or Null;
    public var precipitationAmount as Lang.Float or Null;
    public var temperature as Lang.Numeric or Null;
    public var windBearing as Lang.Number or Null;
    public var windSpeed as Lang.Float or Null;
    public var windGust as Lang.Float or Null;
    public var highTemperature as Lang.Numeric or Null;
    public var lowTemperature as Lang.Numeric or Null;
    public var feelsLikeTemperature as Lang.Float or Null;
    public var relativeHumidity as Lang.Number or Null;
    public var condition as Lang.Number or Null;
    public var uvIndex as Lang.Float or Null;
    public var cityName as Lang.String or Null;
    public var observationTimestamp as Lang.Number or Null;
}