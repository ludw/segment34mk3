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