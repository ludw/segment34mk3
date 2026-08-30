import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;

function formatTemperature(temp, propShowTempUnit as Boolean, tempUnit as String) as String {
    if(propShowTempUnit) {
        return temp.format("%d") + tempUnit;
    }
    return temp.format("%d");
}

function convertTemperature(temp as Numeric, unit as String) as Numeric {
    if(unit.equals("C")) {
        return temp;
    } else {
        return ((temp * 9/5) + 32);
    }
}

function formatWindSpeed(mps as Float, propWindUnit as Number) as String {
    if (propWindUnit == 0) {
        return Math.round(mps).format("%d");
    } else if (propWindUnit == 1) {
        return Math.round(mps * 3.6).format("%d");
    } else if (propWindUnit == 2) {
        return Math.round(mps * 2.237).format("%d");
    } else if (propWindUnit == 3) {
        return Math.round(mps * 1.944).format("%d");
    } else { // beaufort
        if (mps < 0.5f) { return "0"; }
        if (mps < 1.5f) { return "1"; }
        if (mps < 3.3f) { return "2"; }
        if (mps < 5.5f) { return "3"; }
        if (mps < 7.9f) { return "4"; }
        if (mps < 10.7f) { return "5"; }
        if (mps < 13.8f) { return "6"; }
        if (mps < 17.1f) { return "7"; }
        if (mps < 20.7f) { return "8"; }
        if (mps < 24.4f) { return "9"; }
        if (mps < 28.4f) { return "10"; }
        if (mps < 32.6f) { return "11"; }
        return "12";
    }
}

function formatPressure(pressureHpa as Float, width as Number, propPressureUnit as Number) as String {
    var val = "";
    var nf = "%d";

    if (propPressureUnit == 0) { // hPA
        val = pressureHpa.format(nf);
    } else if (propPressureUnit == 1) { // mmHG
        val = (pressureHpa * 0.750062).format(nf);
    } else if (propPressureUnit == 2) { // inHG
        if(width == 5) {
            val = (pressureHpa * 0.02953).format("%.2f");
        } else {
            val = (pressureHpa * 0.02953).format("%.1f");
        }
    }

    return val;
}

function formatDistanceByWidth(distance as Float, width as Number) as String {
    if (width == 3) {
        return distance < 9.9 ? distance.format("%.1f") : Math.round(distance).format("%d");
    } else if (width == 4) {
        return distance < 100 ? distance.format("%.1f") : distance.format("%d");
    } else {  // width == 5
        return distance < 1000 ? distance.format("%05.1f") : distance.format("%05d");
    }
}

function formatGraphAxisValue(val as Float) as String {
    var n = val.toNumber();
    if(n < 0) {
        var abs = (-val).toNumber();
        if(abs >= 1000) { return "-" + (abs / 1000).toString() + "K"; }
        if(abs < 10) { return "-" + val.format("%.1f"); }
        return "-" + abs.toString();
    }
    if(n >= 1000) { return (n / 1000).toString() + "K"; }
    if(n < 10) { return val.format("%.1f"); }
    return n.toString();
}

function goalPercent(val as Number, goal as Number) as Number {
    if(goal == 0 || val == 0) { return 0; }
    return Math.round(val.toFloat() / goal.toFloat() * 100.0);
}

function moonPhase(time, propHemisphere as Number) as String {
    if (time == null) { return "0"; }
    // Moon phase is a UTC-anchored calculation; using the device's local
    // date here would shift the result by up to a day depending on timezone.
    var utcNow = Time.Gregorian.utcInfo(Time.now(), Time.FORMAT_SHORT);
    return moonPhaseIndex(utcNow.year, utcNow.month, utcNow.day, propHemisphere).toString();
}

function formatLabel(short as ResourceId, mid as ResourceId, size as Number) as String {
    if(size == 1) { return Application.loadResource(short) + ":"; }
    return Application.loadResource(mid) + ":";
}

function formatSunTime(s as Time.Moment?, width as Number, propIs24H as Boolean, propHourFormat as Number) as String {
    if(s != null) {
        var info = Time.Gregorian.info(s, Time.FORMAT_SHORT);
        var h = formatHour(info.hour, propIs24H, propHourFormat);
        if(width < 5) { return h.format("%02d") + info.min.format("%02d"); }
        return h.format("%02d") + ":" + info.min.format("%02d");
    }
    return Application.loadResource(Rez.Strings.LABEL_NA);
}

// Returns [dawn, dusk] as Time.Moment objects, or null if unavailable.
// dawn = civil dawn (sun at -6°), dusk = civil dusk (sun at -6°).
function getCivilTwilight(lat_deg as Double, sunrise as Time.Moment, sunset as Time.Moment) as Array? {
    return getSolarHorizonEvent(lat_deg, sunrise, sunset, -6.0f);
}

// Returns [rise, set] as Time.Moment objects for a body that rises/sets when the Sun is
// at elevation h0_deg above/below the horizon. Positive h0 = sun above horizon at event
// (e.g. golden hour end at +6°); negative = below (e.g. civil twilight at -6°).
//
// Algorithm: back-calculates solar declination from sunrise/sunset times, then solves
// the hour-angle equation for the requested h0.
// NOTE: Not suitable for moon rise/set.
//
// Returns null when the event doesn't occur (polar conditions or out-of-range h0).
function getSolarHorizonEvent(lat_deg as Numeric, sunrise as Time.Moment, sunset as Time.Moment, h0_deg as Numeric) as Array? {
    var PI = Math.PI;
    var lat = lat_deg * PI / 180.0;

    // Half-day length as hour angle in radians (Earth rotates 2π in 86400s)
    var half_day_s = (sunset.value() - sunrise.value()) / 2.0;
    var H0 = half_day_s / 86400.0 * 2.0 * PI;

    // Back-calculate solar declination from H0 and latitude.
    // cos(H0) = (sin(h0_sun) - sin(lat)*sin(dec)) / (cos(lat)*cos(dec))
    // where h0_sun = -0.8333° (refraction + solar disc radius)
    var sin_h0_sun = Math.sin(-0.8333 * PI / 180.0);
    var a = Math.cos(H0) * Math.cos(lat);
    var b = Math.sin(lat);
    var R = Math.sqrt(a * a + b * b);
    var ratio = sin_h0_sun / R;
    if (ratio < -1.0 || ratio > 1.0) { return null; }
    var alpha = Math.atan2(b, a);
    var dec = alpha - Math.acos(ratio);

    // Hour angle for the requested h0
    var cos_H = (Math.sin(h0_deg * PI / 180.0) - Math.sin(lat) * Math.sin(dec)) /
                (Math.cos(lat) * Math.cos(dec));
    if (cos_H > 1.0) { return null; }
    if (cos_H < -1.0) { return null; }
    var H = Math.acos(cos_H);

    // delta = (H - H0) / (2π) * 86400
    var delta_s = (H - H0) / (2.0 * PI) * 86400.0;
    var delta = new Time.Duration(delta_s.toNumber());
    return [sunrise.subtract(delta), sunset.add(delta)];
}
