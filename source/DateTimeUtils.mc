import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;

// Module-level cache for day/month name lookups (avoids repeated resource loads)
var _cachedDayOfWeek as Number = -1;
var _cachedDayName as String = "";
var _cachedMonth as Number = -1;
var _cachedMonthName as String = "";

function dayName(day_of_week as Number) as String {
    if (_cachedDayOfWeek == day_of_week) { return _cachedDayName; }
    _cachedDayOfWeek = day_of_week;
    var names = [Rez.Strings.DAY_OF_WEEK_SUN, Rez.Strings.DAY_OF_WEEK_MON, Rez.Strings.DAY_OF_WEEK_TUE,
                 Rez.Strings.DAY_OF_WEEK_WED, Rez.Strings.DAY_OF_WEEK_THU, Rez.Strings.DAY_OF_WEEK_FRI,
                 Rez.Strings.DAY_OF_WEEK_SAT];
    _cachedDayName = Application.loadResource(names[day_of_week - 1]);
    return _cachedDayName;
}

function monthName(month as Number) as String {
    if (_cachedMonth == month) { return _cachedMonthName; }
    _cachedMonth = month;
    var names = [Rez.Strings.MONTH_JAN, Rez.Strings.MONTH_FEB, Rez.Strings.MONTH_MAR,
                 Rez.Strings.MONTH_APR, Rez.Strings.MONTH_MAY, Rez.Strings.MONTH_JUN,
                 Rez.Strings.MONTH_JUL, Rez.Strings.MONTH_AUG, Rez.Strings.MONTH_SEP,
                 Rez.Strings.MONTH_OCT, Rez.Strings.MONTH_NOV, Rez.Strings.MONTH_DEC];
    _cachedMonthName = Application.loadResource(names[month - 1]);
    return _cachedMonthName;
}

// julianDay moved to CelestialCalc.mc

function isLeapYear(year as Number) as Boolean {
    if (year % 4 != 0) {
        return false;
       } else if (year % 100 != 0) {
        return true;
    } else if (year % 400 == 0) {
        return true;
    }
    return false;
}

function isoWeekNumber(year as Number, month as Number, day as Number, propWeekOffset as Number) as Number {
    var first_day_of_year = julianDay(year, 1, 1);
    var given_day_of_year = julianDay(year, month, day);
    var day_of_week = (first_day_of_year + 3) % 7;
    var week_of_year = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
    var ret = 0;
    if (week_of_year == 53) {
        if (day_of_week == 6) {
            ret = week_of_year;
        } else if (day_of_week == 5 && isLeapYear(year)) {
            ret = week_of_year;
        } else {
            ret = 1;
        }
    } else if (week_of_year == 0) {
        first_day_of_year = julianDay(year - 1, 1, 1);
        day_of_week = (first_day_of_year + 3) % 7;
        ret = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
    } else {
        ret = week_of_year;
    }
    if(propWeekOffset != 0) {
        ret = ret + propWeekOffset;
    }
    return ret;
}

function formatHour(hour as Number, propIs24H as Boolean, propHourFormat as Number) as Number {
    if((!propIs24H and propHourFormat == 0) or propHourFormat == 2) {
        hour = hour % 12;
        if(hour == 0) { hour = 12; }
    }
    return hour;
}

function formatDate(propDateFormat as Number, propDateCustomFormat as String, propFontSize as Number, propWeekOffset as Number) as String {
    var now = Time.now();
    var today = Time.Gregorian.info(now, Time.FORMAT_SHORT);

    if(propDateFormat == 1) {
        return formatCustomDate(today, propDateCustomFormat, propWeekOffset);
    }
    // Auto: omit year for large font
    var base = dayName(today.day_of_week) + ", " + today.day + " " + monthName(today.month);
    if(propFontSize == 1) {
        return base;
    }
    return base + " " + today.year;
}

function formatCustomDate(today as Time.Gregorian.Info, propDateCustomFormat as String, propWeekOffset as Number) as String {
    var fmt = propDateCustomFormat;
    var result = "";
    var i = 0;
    while(i < fmt.length()) {
        var ch = fmt.substring(i, i + 1);
        if(ch.equals("y")) { result += today.year.toString(); }
        else if(ch.equals("m")) { result += today.month.format("%02d"); }
        else if(ch.equals("d")) { result += today.day.toString(); }
        else if(ch.equals("o")) { result += dayName(today.day_of_week); }
        else if(ch.equals("n")) { result += monthName(today.month); }
        else if(ch.equals("w")) { result += isoWeekNumber(today.year, today.month, today.day, propWeekOffset).toString(); }
        else { result += ch; }
        i += 1;
    }
    return result;
}

function getDateTimeGroup() as String {
    // DDHHMMZmmmYY (e.g. 052125ZMAR25)
    var now = Time.now();
    var utc = Time.Gregorian.utcInfo(now, Time.FORMAT_SHORT);
    return utc.day.format("%02d") + utc.hour.format("%02d") + utc.min.format("%02d") + "Z" + monthName(utc.month) + utc.year.toString().substring(2,4);
}

function secondaryTimezone(offset, width, propIs24H as Boolean, propHourFormat as Number, propTzHourFormat as Number) as String {
    var val = "";
    var now = Time.now();
    var utc = Time.Gregorian.utcInfo(now, Time.FORMAT_MEDIUM);
    var min = utc.min + (offset % 60);
    var hour = (utc.hour + (offset / 60)) % 24;

    if(min > 59) {
        min -= 60;
        hour += 1;
    }

    if(min < 0) {
        min += 60;
        hour -= 1;
    }

    if(hour < 0) {
        hour += 24;
    }
    if(hour > 23) {
        hour -= 24;
    }
    var mainClockIs12h = (!propIs24H and propHourFormat == 0) or propHourFormat == 2;
    var tzIs12h = (propTzHourFormat == 2) or (propTzHourFormat == 0 and mainClockIs12h);
    var f_hour = hour;
    if(tzIs12h) {
        f_hour = hour % 12;
        if(f_hour == 0) { f_hour = 12; }
    }
    if(width < 5) {
        val = f_hour.format("%02d") + min.format("%02d");
    } else {
        if(tzIs12h) {
            var ampm = "A";
            if(hour >= 12) { ampm = "P"; }
            val = f_hour.format("%02d") + min.format("%02d") + ampm;
        } else {
            val = f_hour.format("%02d") + ":" + min.format("%02d");
        }
    }
    return val;
}
