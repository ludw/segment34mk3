// Celestial body calculations: sun, moon, twilight, golden hour.

import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Weather;

// ── Next-event helpers ────────────────────────────────────────────────────────

function getNextEvent(todayFirstEvent as Time.Moment?, todaySecondEvent as Time.Moment?, tomorrowFirstEvent as Time.Moment?, tomorrowSecondEvent as Time.Moment?, now as Time.Moment) as Lang.Array {
    if (todayFirstEvent == null || todaySecondEvent == null || tomorrowFirstEvent == null || tomorrowSecondEvent == null) {
        return [];
    }

    var first = todayFirstEvent as Time.Moment;
    if (first.lessThan(now)) {
        first = tomorrowFirstEvent as Time.Moment;
    }

    var second = todaySecondEvent as Time.Moment;
    if (second.lessThan(now)) {
        second = tomorrowSecondEvent as Time.Moment;
    }

    if (first.lessThan(second)) {
        return [first, true];
    }
    return [second, false];
}

function getNextSunEvent(weatherCondition as StoredWeather?) as Lang.Array {
    var now = Time.now();
    if (weatherCondition != null) {
        var loc = weatherCondition.observationLocationPosition;
        if (loc != null) {
            var tomorrow = Time.today().add(new Time.Duration(86401));
            var sunrise = Weather.getSunrise(loc, now);
            var sunset = Weather.getSunset(loc, now);
            var tomorrowSunrise = Weather.getSunrise(loc, tomorrow);
            var tomorrowSunset = Weather.getSunset(loc, tomorrow);
            return getNextEvent(sunrise, sunset, tomorrowSunrise, tomorrowSunset, now);
        }
    }
    return [];
}

function getNextCivilTwilightEvent(weatherCondition as StoredWeather?) as Lang.Array {
    var now = Time.now();
    if (weatherCondition != null) {
        var loc = weatherCondition.observationLocationPosition;
        if (loc != null) {
            var tomorrow = Time.today().add(new Time.Duration(86401));
            var sunrise = Weather.getSunrise(loc, now);
            var sunset = Weather.getSunset(loc, now);
            var tomorrowSunrise = Weather.getSunrise(loc, tomorrow);
            var tomorrowSunset = Weather.getSunset(loc, tomorrow);
            if (sunrise != null && sunset != null && tomorrowSunrise != null && tomorrowSunset != null) {
                var latDeg = loc.toDegrees()[0];
                var twilight = getCivilTwilight(latDeg as Double, sunrise, sunset);
                var tomorrowTwilight = getCivilTwilight(latDeg as Double, tomorrowSunrise, tomorrowSunset);
                if (twilight != null && tomorrowTwilight != null) {
                    return getNextEvent(twilight[0], twilight[1], tomorrowTwilight[0], tomorrowTwilight[1], now);
                }
            }
        }
    }
    return [];
}

function hoursToNextSunEvent(weatherCondition as StoredWeather?) as Lang.String {
    var nextSunEventArray = getNextSunEvent(weatherCondition);
    if (nextSunEventArray != null && nextSunEventArray.size() == 2) {
        var nextSunEvent = nextSunEventArray[0] as Time.Moment;
        var now = Time.now();
        // Converting seconds to hours
        var diff = (nextSunEvent.subtract(now)).value();
        if (diff >= 36000) { // No decimals if 10+ hours
            return (diff / 3600.0).format("%d");
        }
        return (diff / 3600.0).format("%.1f");
    }
    return "";
}

// ── Golden hour ───────────────────────────────────────────────────────────────

// Returns [goldenHourEnd, goldenHourStart]:
//   goldenHourEnd   = morning time sun rises above +6° (end of morning golden hour)
//   goldenHourStart = evening time sun descends to +6° (start of evening golden hour)
// Returns [] if unavailable.
function getGoldenHour(weatherCondition as StoredWeather?) as Lang.Array {
    var now = Time.now();
    if (weatherCondition != null) {
        var loc = weatherCondition.observationLocationPosition;
        if (loc != null) {
            var sunrise = Weather.getSunrise(loc, now);
            var sunset  = Weather.getSunset(loc, now);
            if (sunrise != null && sunset != null) {
                var latDeg = loc.toDegrees()[0];
                var result = getSolarHorizonEvent(latDeg as Float, sunrise, sunset, 6.0f);
                if (result != null) { return result as Array; }
            }
        }
    }
    return [];
}

// ── Moon calculations ─────────────────────────────────────────────────────────

// Julian Day Number from calendar date.
function julianDay(year as Number, month as Number, day as Number) as Number {
    var a = (14 - month) / 12;
    var y = (year + 4800 - a);
    var m = (month + 12 * a - 3);
    return day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045;
}

// Moon illumination percentage (0–100).
// Based on the synodic month length of 29.53059 days.
// Known new moon epoch: JD 2459966 (2023-01-21, ~20:53 UTC).
function moonIlluminationPercent(year as Number, month as Number, day as Number) as Number {
    var jd = julianDay(year, month, day);
    var days_since_new_moon = jd - 2459966;
    var lunar_cycle = 29.53059;
    var phase = (days_since_new_moon / lunar_cycle);
    phase = phase - Math.floor(phase);
    if (phase < 0) { phase += 1.0; }
    var illum = (1.0 - Math.cos(2.0 * Math.PI * phase)) / 2.0 * 100.0;
    return Math.round(illum).toNumber();
}

// Moon phase index (0–7) for the moon icon font.
// 0 = new moon, 4 = full moon, 8 = "that's no moon" easter egg (May 4th).
// Southern hemisphere inverts the phase (1↔7, 2↔6, 3↔5).
function moonPhaseIndex(year as Number, month as Number, day as Number, propHemisphere as Number) as Number {
    var jd = julianDay(year, month, day);
    var days_since_new_moon = jd - 2459966;
    var lunar_cycle = 29.53059;
    var phase_frac = (days_since_new_moon / lunar_cycle);
    phase_frac = phase_frac - Math.floor(phase_frac);
    if (phase_frac < 0) { phase_frac += 1.0; }

    if (month == 5 && day == 4) {
        return 8;
    }

    // 8 equal-width buckets (cycle/8 each), centered on the 8 named phases
    // rather than starting at them, so each icon spans its exact phase ±half a bucket.
    var moonPhaseIdx = Math.round(phase_frac * 8).toNumber() % 8;

    if (propHemisphere == 1) {
        moonPhaseIdx = (8 - moonPhaseIdx) % 8;
    }

    return moonPhaseIdx;
}