import Toybox.Test;
import Toybox.Lang;

// Unit tests for WeatherDisplayHelper.maxUvIndexNext8h()
// Max UV index over the next 8 hours from the hourly forecast stored in
// Application.Storage. Window matches the precip graph convention:
//   keep entries where -3600 <= (forecastTime - now) < 8*3600
// Run with: monkeyc --unit-test -d fenix7

// Helper: build an hourly-forecast entry dictionary like the ones stored by
// WeatherStorage / OpenMeteoService.
function makeUvEntry(forecastTime as Number, uvIndex as Float) as Dictionary {
    return {
        "forecastTime" => forecastTime,
        "uvIndex" => uvIndex
    };
}

(:test)
function testMaxUvNext8hEmpty(logger as Test.Logger) as Boolean {
    return WeatherDisplayHelper.maxUvIndexNext8h([], 1000) == null;
}

(:test)
function testMaxUvNext8hNullArray(logger as Test.Logger) as Boolean {
    return WeatherDisplayHelper.maxUvIndexNext8h(null, 1000) == null;
}

(:test)
function testMaxUvNext8hPicksMax(logger as Test.Logger) as Boolean {
    var now = 100000;
    var hf = [
        makeUvEntry(now, 2.0),
        makeUvEntry(now + 3600, 5.0),
        makeUvEntry(now + 7200, 3.0)
    ];
    return WeatherDisplayHelper.maxUvIndexNext8h(hf, now) == 5.0;
}

(:test)
function testMaxUvNext8hIgnoresOutsideWindow(logger as Test.Logger) as Boolean {
    var now = 100000;
    var hf = [
        makeUvEntry(now, 1.0),
        makeUvEntry(now + 7 * 3600, 7.0),        // within 8h window
        makeUvEntry(now + 10 * 3600, 9.0),       // beyond 8h -> ignore
        makeUvEntry(now - 2 * 3600, 8.0)         // older than 1h -> ignore
    ];
    return WeatherDisplayHelper.maxUvIndexNext8h(hf, now) == 7.0;
}

(:test)
function testMaxUvNext8hSkipsNullUv(logger as Test.Logger) as Boolean {
    var now = 100000;
    var hf = [
        makeUvEntry(now, 1.0),
        { "forecastTime" => now + 3600 },        // no uvIndex
        makeUvEntry(now + 7200, 4.0)
    ];
    return WeatherDisplayHelper.maxUvIndexNext8h(hf, now) == 4.0;
}

(:test)
function testMaxUvNext8hAllNull(logger as Test.Logger) as Boolean {
    var now = 100000;
    var hf = [
        { "forecastTime" => now },
        { "forecastTime" => now + 3600 }
    ];
    return WeatherDisplayHelper.maxUvIndexNext8h(hf, now) == null;
}

// --- Tests for WeatherDisplayHelper.formatRainForecast ---

(:test)
function testFormatRainForecastNullAndStale(logger as Test.Logger) as Boolean {
    var now = 100000;
    if (!WeatherDisplayHelper.formatRainForecast(null, now).equals("")) { return false; }
    if (!WeatherDisplayHelper.formatRainForecast([], now).equals("")) { return false; }
    // Stale: at <= now
    if (!WeatherDisplayHelper.formatRainForecast([0, now, 60], now).equals("")) { return false; }
    if (!WeatherDisplayHelper.formatRainForecast([1, now - 60, 0], now).equals("")) { return false; }
    return true;
}

(:test)
function testFormatRainForecastKind0And1Boundaries(logger as Test.Logger) as Boolean {
    var now = 100000;
    // < 60 min -> Xm
    if (!WeatherDisplayHelper.formatRainForecast([0, now + 30 * 60, 100], now).equals("100% IN 30M")) { return false; }
    if (!WeatherDisplayHelper.formatRainForecast([1, now + 59 * 60, 0], now).equals("DRY IN 59M")) { return false; }
    // 60 min -> 1h
    if (!WeatherDisplayHelper.formatRainForecast([0, now + 60 * 60, 60], now).equals("60% IN 1H")) { return false; }
    // 23h -> 23h
    if (!WeatherDisplayHelper.formatRainForecast([1, now + 23 * 3600, 0], now).equals("DRY IN 23H")) { return false; }
    // 24h -> 1d
    if (!WeatherDisplayHelper.formatRainForecast([0, now + 24 * 3600, 75], now).equals("75% IN 1D")) { return false; }
    // 2.5 days -> floor to 2d
    if (!WeatherDisplayHelper.formatRainForecast([0, now + 60 * 3600, 60], now).equals("60% IN 2D")) { return false; }
    return true;
}

(:test)
function testFormatRainForecastKind2And3(logger as Test.Logger) as Boolean {
    var now = 100000;
    // 3 days lookahead
    if (!WeatherDisplayHelper.formatRainForecast([2, now + 3 * 86400, 0], now).equals("DRY 3D+")) { return false; }
    if (!WeatherDisplayHelper.formatRainForecast([3, now + 3 * 86400 + 3600, 0], now).equals("RAIN 3D+")) { return false; }
    // 2 days lookahead
    if (!WeatherDisplayHelper.formatRainForecast([2, now + 2 * 86400, 0], now).equals("DRY 2D+")) { return false; }
    // < 1d remaining -> ""
    if (!WeatherDisplayHelper.formatRainForecast([2, now + 23 * 3600, 0], now).equals("")) { return false; }
    if (!WeatherDisplayHelper.formatRainForecast([3, now + 3600, 0], now).equals("")) { return false; }
    return true;
}