// Activity and sensor data helpers

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;

// Module-level cache vars for activity distance data (moved from Segment34View)
var _cachedRunDist7Days as Number = 0;
var _cachedBikeDist7Days as Number = 0;
var _cachedSwimDist7Days as Number = 0;
var _cachedRunDistMonth as Number = 0;
var _cachedRunDist28Days as Number = 0;
var _lastActivityDistUpdate as Number = 0;

// Battery bar fill strings (moved from Segment34View constants)
const BATT_FULL = "|||||||||||||||||||||||||||||||||||";
const BATT_EMPTY = "{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{";

function getBarData(data_source as Number) as Number? {
    if(data_source == 1) {
        return getStressData();
    } else if (data_source == 2) {
        return getBBData();
    } else if (data_source == 3) {
        return getStepGoalProgress();
    } else if (data_source == 4) {
        return getFloorGoalProgress();
    } else if (data_source == 5) {
        return getActMinGoalProgress();
    } else if (data_source == 6) {
        return getMoveBar();
    }
    return null;
}

function getStressData() as Number? {
    try {
        var complication_stress = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_STRESS));
        if (complication_stress != null && complication_stress.value != null) {
            return complication_stress.value;
        }
    } catch(e) {}
    return null;
}

function getStressColor(val as Number) as Graphics.ColorType {
    if (val <= 25) { return 0x00AAFF; } // Rest (Blue)
    if (val <= 50) { return 0xFFAA00; } // Low (Yellow/Orange)
    if (val <= 75) { return 0xFF5500; } // Medium (Orange)
    return 0xAA0000;                   // High (Red)
}

function getBBData() as Number? {
    try {
        var complication_bb = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY));
        if (complication_bb != null && complication_bb.value != null) { return complication_bb.value; }
    } catch(e) {}
    return null;
}

function getStepGoalProgress() as Number? {
    var info = ActivityMonitor.getInfo();
    if(info.steps != null and info.stepGoal != null) {
        return goalPercent(info.steps, info.stepGoal);
    }
    return null;
}

function getFloorGoalProgress() as Number? {
    var info = ActivityMonitor.getInfo();
    if(info.floorsClimbed != null and info.floorsClimbedGoal != null) {
        return goalPercent(info.floorsClimbed, info.floorsClimbedGoal);
    }
    return null;
}

function getActMinGoalProgress() as Number? {
    var info = ActivityMonitor.getInfo();
    if(info.activeMinutesWeek != null and info.activeMinutesWeekGoal != null) {
        return goalPercent(info.activeMinutesWeek.total, info.activeMinutesWeekGoal);
    }
    return null;
}

function getMoveBar() as Number? {
    if(ActivityMonitor.getInfo().moveBarLevel != null) {
        var mov = ActivityMonitor.getInfo().moveBarLevel;
        if(mov >= 1 && mov <= 5) { return 25 + mov * 15; }
    }
    return null;
}

function getBattData(propBatteryVariant as Number, screenHeight as Number, propFontSize as Number) as String {
    var value = "";

    if(propBatteryVariant == 0) {
        if (System.getSystemStats().batteryInDays != null){
            var sample = Math.round(System.getSystemStats().batteryInDays);
            value = sample.format("%0d") + "D";
        }
    }
    if(propBatteryVariant == 1) {
        var sample = System.getSystemStats().battery;
        if(sample < 100) {
            value = sample.format("%d") + "%";
        } else {
            value = sample.format("%d");
        }
    } else if(propBatteryVariant == 3 or propBatteryVariant == -1) {
            var sample = 0;
            var max = 0;
            var batLevel = System.getSystemStats().battery;

            if(screenHeight > 280 and propFontSize == 1) {
                // led_lines font: 2px/char, "T" outline interior → max = 24
                sample = Math.round(batLevel / 100.0 * 24).toNumber();
                max = 24;
            } else if(screenHeight > 280 or propFontSize == 1) {
                // led_small_lines or smol font: 1px/char → max = 35
                sample = Math.round(batLevel / 100.0 * 35).toNumber();
                max = 35;
            } else {
                sample = Math.round(batLevel / 100.0 * 20).toNumber();
                max = 20;
            }
            if (sample > 0) {
                value += BATT_FULL.substring(0, sample);
            }

            if (sample < max) {
                value += BATT_EMPTY.substring(0, max - sample);
            }
        }

    return value;
}

function getRestCalories() as Number {
    var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var profile = UserProfile.getProfile();

    if (profile.birthYear == null || profile.weight == null || profile.height == null) {
        return 0;
    }

    var age = today.year - profile.birthYear;
    var weight = profile.weight / 1000.0;
    var rest_calories = 0;

    if (profile.gender == UserProfile.GENDER_MALE) {
        rest_calories = 5.2 - 6.116 * age + 7.628 * profile.height + 12.2 * weight;
    } else {
        rest_calories = -197.6 - 6.116 * age + 7.628 * profile.height + 12.2 * weight;
    }

    // Calculate rest calories for the current time of day
    rest_calories = Math.round((today.hour * 60 + today.min) * rest_calories / 1440).toNumber();
    return rest_calories;
}

function getWeeklyDistance() as Number {
    var weekly_distance = 0;
    var history = ActivityMonitor.getHistory();
    if (history != null) {
        // Only take up to 6 previous days from history
        var daysToCount = history.size() < 6 ? history.size() : 6;
        for (var i = 0; i < daysToCount; i++) {
            if (history[i].distance != null) {
                weekly_distance += history[i].distance;
            }
        }
    }
    // Add today's distance
    if(ActivityMonitor.getInfo().distance != null) {
        weekly_distance += ActivityMonitor.getInfo().distance;
    }
    return weekly_distance;
}

function updateActivityDistCache() as Void {
    var sevenDaysAgoVal = Time.now().value() - (7 * 24 * 3600);
    var twentyEightDaysAgoVal = Time.now().value() - (28 * 24 * 3600);
    var nowInfo = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var monthStartMoment = Time.Gregorian.moment({:year => nowInfo.year, :month => nowInfo.month, :day => 1, :hour => 0, :minute => 0, :second => 0});
    var monthStartVal = monthStartMoment.value();
    var runDist = 0;
    var bikeDist = 0;
    var swimDist = 0;
    var runDist28Days = 0;
    var runDistMonth = 0;
    var iter = UserProfile.getUserActivityHistory();
    var act = iter.next();
    while (act != null) {
        if (act.startTime != null && act.distance != null) {
            var t = act.startTime.value();
            if (t >= sevenDaysAgoVal) {
                if (act.type == Activity.SPORT_RUNNING) { runDist += act.distance; }
                else if (act.type == Activity.SPORT_CYCLING) { bikeDist += act.distance; }
                else if (act.type == Activity.SPORT_SWIMMING) { swimDist += act.distance; }
            }
            if (act.type == Activity.SPORT_RUNNING) {
                if (t >= twentyEightDaysAgoVal) { runDist28Days += act.distance; }
                if (t >= monthStartVal) { runDistMonth += act.distance; }
            }
        }
        act = iter.next();
    }
    _cachedRunDist7Days = runDist;
    _cachedBikeDist7Days = bikeDist;
    _cachedSwimDist7Days = swimDist;
    _cachedRunDist28Days = runDist28Days;
    _cachedRunDistMonth = runDistMonth;
}

function getWeeklyDistanceFromComplication(isRun as Boolean, conversionFactor as Float, width as Number) as String {
    try {
        var compType = isRun ? Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE : Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE;
        var complication = Complications.getComplication(new Complications.Id(compType));
        if (complication != null && complication.value != null) {
            return formatDistanceByWidth(complication.value * conversionFactor, width);
        }
    } catch(e) {}
    return "";
}
