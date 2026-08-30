import Toybox.Test;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;

// Unit tests for CelestialCalc moon calculations.
// Run with: monkeyc --unit-test -d fenix7

// ── Julian day tests ──────────────────────────────────────────────────────────

(:test)
function testJulianDay2000Jan15(logger as Test.Logger) as Boolean {
    return julianDay(2000, 1, 15) == 2451559;
}

(:test)
function testJulianDay2024Jun21(logger as Test.Logger) as Boolean {
    return julianDay(2024, 6, 21) == 2460482;
}

(:test)
function testJulianDay2025Jan1(logger as Test.Logger) as Boolean {
    return julianDay(2025, 1, 1) == 2460668;
}

// ── Moon illumination % tests ──────────────────────────────────────────────────
// Known new moons: 2024-01-11, 2024-02-10, 2025-01-29
// Known full moons: 2024-01-25, 2024-06-22

(:test)
function testMoonIlluminationNewMoon(logger as Test.Logger) as Boolean {
    var illum = moonIlluminationPercent(2024, 1, 11);
    return illum >= 0 && illum <= 3;
}

(:test)
function testMoonIlluminationFullMoon(logger as Test.Logger) as Boolean {
    var illum = moonIlluminationPercent(2024, 6, 22);
    return illum >= 97 && illum <= 100;
}

(:test)
function testMoonIlluminationQuarter(logger as Test.Logger) as Boolean {
    var illum = moonIlluminationPercent(2024, 6, 14);
    return illum >= 45 && illum <= 55;
}

(:test)
function testMoonIlluminationRange(logger as Test.Logger) as Boolean {
    var valid = true;
    for (var m = 1; m <= 12; m += 1) {
        for (var d = 1; d <= 28; d += 5) {
            var illum = moonIlluminationPercent(2025, m, d);
            if (illum < 0 || illum > 100) { valid = false; }
        }
    }
    return valid;
}

// ── Moon phase index tests (same values as old FormatUtils.moonPhase) ─────────

(:test)
function testMoonPhaseNewMoon(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2024, 1, 11, 0) == 0;
}

(:test)
function testMoonPhaseFullMoon(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2024, 6, 22, 0) == 4;
}

(:test)
function testMoonPhaseSouthernHemisphere(logger as Test.Logger) as Boolean {
    var north = moonPhaseIndex(2024, 6, 14, 0);
    var south = moonPhaseIndex(2024, 6, 14, 1);
    return south == ((8 - north) % 8);
}

(:test)
function testMoonPhaseMayTheFourth(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2024, 5, 4, 0) == 8;
}

// ── Real-world 2026 event tests ──────────────────────────────────────────────
// Source: published Umeå, Sweden ephemeris (local CET/CEST), converted to the
// UTC calendar date the app now uses. moonPhaseIndex/moonIlluminationPercent
// take a UTC date, so these dates are the event's UTC day, not its local day.
//
//   Event           Local (Umeå)        -> UTC
//   New Moon        2026-01-18 20:52    -> 2026-01-18 19:52
//   First Quarter   2026-01-26 05:47    -> 2026-01-26 04:47
//   Full Moon       2026-02-01 23:09    -> 2026-02-01 22:09
//   Third Quarter   2026-02-09 13:43    -> 2026-02-09 12:43
//   Full Moon       2026-06-30 01:56    -> 2026-06-29 23:56  (crosses UTC day)
//   New Moon        2026-08-12 19:36    -> 2026-08-12 17:36  (solar eclipse)
//   Full Moon       2026-08-28 06:18    -> 2026-08-28 04:18  (lunar eclipse)

(:test)
function testMoonPhase2026JanNewMoon(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2026, 1, 18, 0) == 0;
}

(:test)
function testMoonPhase2026JanFirstQuarter(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2026, 1, 26, 0) == 2;
}

(:test)
function testMoonPhase2026FebFullMoon(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2026, 2, 1, 0) == 4;
}

(:test)
function testMoonPhase2026FebThirdQuarter(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2026, 2, 9, 0) == 6;
}

// The local event time (2026-06-30 01:56 CEST) falls on a different calendar
// day than its UTC equivalent (2026-06-29 23:56) - this is the exact class of
// off-by-one-day bug the UTC-vs-local fix addresses.
(:test)
function testMoonPhase2026JunFullMoonUtcDayBoundary(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2026, 6, 29, 0) == 4;
}

(:test)
function testMoonPhase2026AugEclipseNewMoon(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2026, 8, 12, 0) == 0;
}

(:test)
function testMoonPhase2026AugEclipseFullMoon(logger as Test.Logger) as Boolean {
    return moonPhaseIndex(2026, 8, 28, 0) == 4;
}

(:test)
function testMoonIllumination2026AugEclipseNewMoon(logger as Test.Logger) as Boolean {
    var illum = moonIlluminationPercent(2026, 8, 12);
    return illum >= 0 && illum <= 3;
}

(:test)
function testMoonIllumination2026AugEclipseFullMoon(logger as Test.Logger) as Boolean {
    var illum = moonIlluminationPercent(2026, 8, 28);
    return illum >= 97 && illum <= 100;
}