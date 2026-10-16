import Toybox.Test;
import Toybox.Lang;

// Unit tests for RainForecast stateful scanner.
// Run with: monkeyc --unit-test -d fenix7

(:test)
function testRainForecastEmpty(logger as Test.Logger) as Boolean {
    var rf = new RainForecast();
    return rf.result() == null;
}

(:test)
function testRainForecastDryToRain(logger as Test.Logger) as Boolean {
    var rf = new RainForecast();
    var t0 = 100000;
    if (rf.feed(t0, 10)) { return false; }
    if (rf.feed(t0 + 3600, 30)) { return false; }
    if (!rf.feed(t0 + 7200, 65)) { return false; }
    var res = rf.result();
    if (res == null || res.size() != 3) { return false; }
    return (res[0] == 0) && (res[1] == t0 + 7200) && (res[2] == 65);
}

(:test)
function testRainForecastWetToDry(logger as Test.Logger) as Boolean {
    var rf = new RainForecast();
    var t0 = 100000;
    if (rf.feed(t0, 80)) { return false; }
    if (rf.feed(t0 + 3600, 50)) { return false; }
    if (!rf.feed(t0 + 7200, 20)) { return false; }
    var res = rf.result();
    if (res == null || res.size() != 3) { return false; }
    return (res[0] == 1) && (res[1] == t0 + 7200);
}

(:test)
function testRainForecastAllDry(logger as Test.Logger) as Boolean {
    var rf = new RainForecast();
    var t0 = 100000;
    rf.feed(t0, 0);
    rf.feed(t0 + 3600, 20);
    rf.feed(t0 + 86400 * 3, 49);
    var res = rf.result();
    if (res == null || res.size() != 3) { return false; }
    return (res[0] == 2) && (res[1] == t0 + 86400 * 3);
}

(:test)
function testRainForecastAllWet(logger as Test.Logger) as Boolean {
    var rf = new RainForecast();
    var t0 = 100000;
    rf.feed(t0, 50);
    rf.feed(t0 + 3600, 90);
    rf.feed(t0 + 86400 * 3, 100);
    var res = rf.result();
    if (res == null || res.size() != 3) { return false; }
    return (res[0] == 3) && (res[1] == t0 + 86400 * 3);
}

(:test)
function testRainForecastThresholdBoundary(logger as Test.Logger) as Boolean {
    var rf = new RainForecast();
    var t0 = 100000;
    if (rf.feed(t0, 49)) { return false; }      // dry (49 < 50)
    if (!rf.feed(t0 + 3600, 50)) { return false; } // wet (50 >= 50) -> transition!
    var res = rf.result();
    if (res == null) { return false; }
    if (res[0] != 0 || res[1] != t0 + 3600 || res[2] != 50) { return false; }

    var rf2 = new RainForecast();
    if (rf2.feed(t0, 50)) { return false; }     // wet
    if (!rf2.feed(t0 + 3600, 49)) { return false; } // dry -> transition!
    var res2 = rf2.result();
    if (res2 == null) { return false; }
    return (res2[0] == 1) && (res2[1] == t0 + 3600);
}

(:test)
function testRainForecastDaySlotMidpoint(logger as Test.Logger) as Boolean {
    var rf = new RainForecast();
    var day0 = 1700006400; // midnight
    // Feed 8 hourly slots (dry)
    for (var i = 0; i < 8; i++) {
        rf.feed(day0 + i * 3600, 10);
    }
    // Feed daily slots at noon midpoint (day_t + 43200)
    var day1Noon = day0 + 86400 + 43200;
    var day2Noon = day0 + 2 * 86400 + 43200;
    if (rf.feed(day1Noon, 20)) { return false; }
    if (!rf.feed(day2Noon, 75)) { return false; }
    var res = rf.result();
    if (res == null) { return false; }
    return (res[0] == 0) && (res[1] == day2Noon) && (res[2] == 75);
}

(:test)
function testRainForecastNonMonotonicIgnored(logger as Test.Logger) as Boolean {
    var rf = new RainForecast();
    var t0 = 100000;
    rf.feed(t0, 10);
    rf.feed(t0 + 7200, 10);
    // Non-increasing timestamp with wet pop must be ignored
    if (rf.feed(t0 + 7200, 90)) { return false; }
    if (rf.feed(t0 + 3600, 90)) { return false; }
    // Increasing timestamp triggers decision
    if (!rf.feed(t0 + 10800, 80)) { return false; }
    var res = rf.result();
    if (res == null) { return false; }
    return (res[0] == 0) && (res[1] == t0 + 10800) && (res[2] == 80);
}
