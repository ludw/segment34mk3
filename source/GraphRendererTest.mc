import Toybox.Test;
import Toybox.Lang;
import Toybox.Time;

// Unit tests for GraphRenderer static helpers (mini graph field codes).
// Run with: monkeyc --unit-test -d fenix7

(:test)
function testIsGraphCodeTrue(logger as Test.Logger) as Boolean {
    return GraphRenderer.isGraphCode(100)
        && GraphRenderer.isGraphCode(112)
        && GraphRenderer.isGraphCode(105);
}

(:test)
function testIsGraphCodeFalse(logger as Test.Logger) as Boolean {
    return !GraphRenderer.isGraphCode(99)
        && !GraphRenderer.isGraphCode(113)
        && !GraphRenderer.isGraphCode(16)
        && !GraphRenderer.isGraphCode(-2);
}

(:test)
function testGraphCodeToDataSource(logger as Test.Logger) as Boolean {
    return GraphRenderer.graphCodeToDataSource(100) == 0
        && GraphRenderer.graphCodeToDataSource(112) == 12
        && GraphRenderer.graphCodeToDataSource(105) == 5
        && GraphRenderer.graphCodeToDataSource(108) == 8;
}

(:test)
function testHistoryWindowPressureIsSixHours(logger as Test.Logger) as Boolean {
    return GraphRenderer.historyWindowSecs(4) == 21600;
}

(:test)
function testPressureBoundsSteadyUsesSixHpaWindow(logger as Test.Logger) as Boolean {
    var bounds = GraphRenderer.pressureBoundsHpa(100780.0f, 100840.0f);
    return bounds[0] == 1005.0f && bounds[1] == 1011.0f;
}

(:test)
function testPressureBoundsModerateFrontTrend(logger as Test.Logger) as Boolean {
    var bounds = GraphRenderer.pressureBoundsHpa(100610.0f, 101020.0f);
    return bounds[0] == 1005.0f && bounds[1] == 1011.0f;
}

(:test)
function testPressureBoundsLargeStormChangeExpands(logger as Test.Logger) as Boolean {
    var bounds = GraphRenderer.pressureBoundsHpa(100400.0f, 101400.0f);
    return bounds[0] == 1003.0f && bounds[1] == 1015.0f;
}

(:test)
function testPressureYAxisLabelShowsFullHpaNot1K(logger as Test.Logger) as Boolean {
    var gr = new GraphRenderer();
    gr.configure(2, 2, 40, 60, 2, null, 8, 4, 0, false, true, 0, true, true, 0);
    return gr.formatYAxisLabel(1011.0f).equals("1011")
        && gr.formatYAxisLabel(1005.0f).equals("1005");
}

(:test)
function testHistoryWindowOthersAreTwoHours(logger as Test.Logger) as Boolean {
    return GraphRenderer.historyWindowSecs(0) == 7200
        && GraphRenderer.historyWindowSecs(2) == 7200
        && GraphRenderer.historyWindowSecs(5) == 7200;
}

(:test)
function testFormatGraphAxisValueNegativeSingleDigit(logger as Test.Logger) as Boolean {
    return formatGraphAxisValue(-3.5f).equals("-3.5")
        && formatGraphAxisValue(-0.5f).equals("-0.5")
        && formatGraphAxisValue(-15.0f).equals("-15")
        && formatGraphAxisValue(-1500.0f).equals("-1K");
}

(:test)
function testGoalPercentReturnsNumber(logger as Test.Logger) as Boolean {
    var pct = goalPercent(50, 100);
    return (pct instanceof Lang.Number) && pct == 50;
}

(:test)
function testSecondaryTimezoneDoesNotCrash(logger as Test.Logger) as Boolean {
    var tz24 = secondaryTimezone(-210, 4, true, 0, 1);
    var tz12 = secondaryTimezone(-210, 5, false, 0, 2);
    return tz24.length() == 4 && tz12.length() == 5;
}

(:test)
function testParseThemeStringMalformedDoesNotCrash(logger as Test.Logger) as Boolean {
    var tm = new ThemeManager();
    tm.update(0, 30, -1, 0, "#", "", null);
    if (tm.colors.size() != 13) { return false; }
    tm.resetNightMode();
    tm.update(0, 30, -1, 0, "#ZZZZZZ,#000000,#000000,#000000,#000000,#000000,#000000,#000000,#000000,#000000,#000000,#000000,#000000", "", null);
    return tm.colors.size() == 13 && tm.infoMessage.equals("THEME ERROR");
}

(:test)
function testPrecipAmountZeroReturnsNumberArray(logger as Test.Logger) as Boolean {
    var now = Time.now().value();
    Toybox.Application.Storage.setValue("hourly_forecast", [
        { "forecastTime" => now + 600, "precipitationAmount" => 0.0f },
        { "forecastTime" => now + 4200 }
    ]);
    var gr = new GraphRenderer();
    var arr = gr.getDataArrayByType(12);
    Toybox.Application.Storage.deleteValue("hourly_forecast");
    return arr.size() == 2 && (arr[0] instanceof Lang.Number) && (arr[1] instanceof Lang.Number);
}
