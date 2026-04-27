import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;

// Module-level constants (Monkey C does not allow const inside a class)
const BATT_FULL  = "|||||||||||||||||||||||||||||||||||";
const BATT_EMPTY = "{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{";

// Module-level function kept for GraphRenderer (which has no DataHelper reference)
function getStressColor(val as Number) as Graphics.ColorType {
    if (val <= 25) { return 0x00AAFF; } // Rest (Blue)
    if (val <= 50) { return 0xFFAA00; } // Low (Yellow/Orange)
    if (val <= 75) { return 0xFF5500; } // Medium (Orange)
    return 0xAA0000;                   // High (Red)
}

class DataHelper {

    // Complication state
    hidden var cgmComplicationId as Complications.Id? = null;
    hidden var cgmAgeComplicationId as Complications.Id? = null;
    var vo2RunTrend as String = "";
    var vo2BikeTrend as String = "";

    // Activity distance cache
    hidden var _cachedRunDist7Days as Number = 0;
    hidden var _cachedBikeDist7Days as Number = 0;
    hidden var _cachedSwimDist7Days as Number = 0;
    hidden var _cachedRunDistMonth as Number = 0;
    hidden var _cachedRunDist28Days as Number = 0;
    hidden var _lastActivityDistUpdate as Number = 0;

    function initialize() {}

    // --- Activity & sensor data ---

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
        return $.getStressColor(val);
    }

    function getBBData() as Number? {
        try {
            var complication_bb = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY));
            if (complication_bb != null && complication_bb.value != null) { return complication_bb.value; }
        } catch(e) {}
        return null;
    }

    hidden function getStepGoalProgress() as Number? {
        var info = ActivityMonitor.getInfo();
        if(info.steps != null and info.stepGoal != null) {
            return goalPercent(info.steps, info.stepGoal);
        }
        return null;
    }

    hidden function getFloorGoalProgress() as Number? {
        var info = ActivityMonitor.getInfo();
        if(info.floorsClimbed != null and info.floorsClimbedGoal != null) {
            return goalPercent(info.floorsClimbed, info.floorsClimbedGoal);
        }
        return null;
    }

    hidden function getActMinGoalProgress() as Number? {
        var info = ActivityMonitor.getInfo();
        if(info.activeMinutesWeek != null and info.activeMinutesWeekGoal != null) {
            return goalPercent(info.activeMinutesWeek.total, info.activeMinutesWeekGoal);
        }
        return null;
    }

    hidden function getMoveBar() as Number? {
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

    // Activity distance cache accessors
    function getCachedRunDist7Days() as Number { return _cachedRunDist7Days; }
    function getCachedBikeDist7Days() as Number { return _cachedBikeDist7Days; }
    function getCachedSwimDist7Days() as Number { return _cachedSwimDist7Days; }
    function getCachedRunDistMonth() as Number { return _cachedRunDistMonth; }
    function getCachedRunDist28Days() as Number { return _cachedRunDist28Days; }
    function getLastActivityDistUpdate() as Number { return _lastActivityDistUpdate; }
    function setLastActivityDistUpdate(val as Number) as Void { _lastActivityDistUpdate = val; }

    // --- Complication data ---

    function getIconState(setting as Number) as String {
        if(setting == 1) { // Alarm
            var alarms = System.getDeviceSettings().alarmCount;
            if(alarms > 0) {
                return "A";
            } else {
                return "";
            }
        } else if(setting == 2) { // DND
            var dnd = System.getDeviceSettings().doNotDisturb;
            if(dnd) {
                return "D";
            } else {
                return "";
            }
        } else if(setting == 3) { // Bluetooth (on / off)
            var bl = System.getDeviceSettings().phoneConnected;
            if(bl) {
                return "L";
            } else {
                return "M";
            }
        } else if(setting == 4) { // Bluetooth (just off)
            var bl = System.getDeviceSettings().phoneConnected;
            if(bl) {
                return "";
            } else {
                return "M";
            }
        } else if(setting == 5) { // Move bar
            var mov = 0;
            if(ActivityMonitor.getInfo().moveBarLevel != null) {
                mov = ActivityMonitor.getInfo().moveBarLevel;
            }
            if(mov == 0) { return ""; }
            if(mov == 1) { return "N"; }
            if(mov == 2) { return "O"; }
            if(mov == 3) { return "P"; }
            if(mov == 4) { return "Q"; }
            if(mov == 5) { return "R"; }
        } else if(setting == 6 || setting == 7) { // Notification icon (6) or notification icon with count (7)
            var notif = System.getDeviceSettings().notificationCount;
            if(notif != null && notif > 0) {
                return "H";
            }
        } else if(setting == 8) { // Training status icon
            try {
                var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
                if(complication != null && complication.value != null) { return "V"; }
            } catch(e) {}
        }
        return "";
    }

    (:AMOLED)
    function getIconColor(setting as Number) as Number? {
        if(setting == 8) { // Training status icon
            try {
                var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
                if(complication != null && complication.value != null) {
                    var status = complication.value.toUpper();
                    if(status.find("OVERREACHING") != null) { return 0xFF3333; }
                    if(status.find("PEAKING") != null) { return 0x7B60FF; }
                    if(status.find("UNPRODUCTIVE") != null) { return 0xFF7700; }
                    if(status.find("PRODUCTIVE") != null) { return 0x30A050; }
                    if(status.find("MAINTAINING") != null) { return 0xFFCC00; }
                    if(status.find("RECOVERY") != null) { return 0x4488EE; }
                    if(status.find("STRAINED") != null) { return 0xFF44AA; }
                    if(status.find("DETRAINING") != null) { return 0x808080; }
                    if(status.find("PAUSED") != null) { return 0x444444; }
                    return 0x808080; // No Status / unknown
                }
            } catch(e) {}
        }
        return null;
    }

    (:MIP)
    function getIconColor(setting as Number) as Number? {
        if(setting == 8) { // Training status icon
            try {
                var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
                if(complication != null && complication.value != null) {
                    var status = complication.value.toUpper();
                    if(status.find("OVERREACHING") != null) { return 0xFF0000; }
                    if(status.find("PEAKING") != null) { return 0xAA55FF; }
                    if(status.find("UNPRODUCTIVE") != null) { return 0xFFAA00; }
                    if(status.find("PRODUCTIVE") != null) { return 0x55AA55; }
                    if(status.find("MAINTAINING") != null) { return 0xFFFF00; }
                    if(status.find("RECOVERY") != null) { return 0x55AAFF; }
                    if(status.find("STRAINED") != null) { return 0xFF55AA; }
                    if(status.find("DETRAINING") != null) { return 0xAAAAAA; }
                    if(status.find("PAUSED") != null) { return 0x555555; }
                    return 0xAAAAAA; // No Status / unknown
                }
            } catch(e) {}
        }
        return null;
    }

    function getIconCountOverlay(setting as Number) as String {
        if(setting == 7) {
            var notif = System.getDeviceSettings().notificationCount;
            if(notif != null && notif > 0) {
                return notif > 9 ? "9+" : notif.format("%d");
            }
        }
        return "";
    }

    function getAltitudeValue() as Float? {
        try {
            var comp = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_ALTITUDE));
            if (comp != null && comp.value != null) { return comp.value.toFloat(); }
        } catch(e) {}
        return null;
    }

    function getRecoveryTimeVal(numberFormat as String) as String {
        var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME));
        if (complication != null && complication.value != null) {
            var recovery_h = complication.value / 60.0;
            if(recovery_h < 9.9 and recovery_h != 0) { return recovery_h.format("%.1f"); }
            return Math.round(recovery_h).format(numberFormat);
        }
        return "";
    }

    function getTrainingStatusVal() as String {
        try {
            var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS));
            if (complication != null && complication.value != null) { return complication.value.toUpper(); }
        } catch(e) {}
        return "";
    }

    function getCalendarEventVal(width as Number) as String {
        var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS));
        var colon_index = null;
        var val = "";
        if (complication != null && complication.value != null) {
            val = complication.value;
            colon_index = val.find(":");
            if (colon_index != null && colon_index < 2) { val = "0" + val; }
        } else {
            val = "--:--";
        }
        if (width < 5 and colon_index != null) { val = val.substring(0, 2) + val.substring(3, 5); }
        return val;
    }

    function getPulseOxVal(numberFormat as String) as String {
        var complication = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_PULSE_OX));
        if (complication != null && complication.value != null) { return complication.value.format(numberFormat); }
        return "";
    }

    hidden function getCgmComplicationByLabel(targetLabel as String) as Complications.Id? {
        try {
            var iter = Complications.getComplications();
            var comp = iter.next();
            while (comp != null) {
                var compType = comp.getType();
                var compLabel = comp.shortLabel;
                if (compType == Complications.COMPLICATION_TYPE_INVALID && compLabel != null) {
                    if (compLabel.equals(targetLabel)) {
                        return comp.complicationId;
                    }
                }
                comp = iter.next();
            }
        } catch (e) {}
        return null;
    }

    hidden function convertCgmTrendToArrow(trend as String) as String {
        if (trend.equals("R")) { return "a"; }  // Rapidly rising ↑
        if (trend.equals("r")) { return "b"; }  // Rising ↗
        if (trend.equals("n")) { return "c"; }  // Neutral →
        if (trend.equals("d")) { return "d"; }  // Falling ↘
        if (trend.equals("D")) { return "e"; }  // Rapidly falling ↓
        return "";
    }

    // Returns a trend arrow char (b=↗ c=→ d=↘) based on stored VO2 history.
    // Stores a new reading every 5 days; drops entries older than 30 days.
    // Returns "" if fewer than 2 stored entries exist.
    hidden function getVo2Trend(key as String, currentVal as Number) as String {
        var nowDays = (Time.now().value() / 86400).toNumber();
        var FIVE_DAYS  = 5;
        var THIRTY_DAYS = 30;

        var history = Application.Storage.getValue(key) as Array?;
        if (history == null) { history = [] as Array; }

        // Prune entries older than 30 days
        var pruned = [] as Array;
        for (var i = 0; i < history.size(); i++) {
            var entry = history[i] as Array;
            if (nowDays - (entry[0] as Number) <= THIRTY_DAYS) {
                pruned.add(entry);
            }
        }

        // Add new entry if history empty or >= 5 days since last stored
        var shouldAdd = pruned.size() == 0 ||
            (nowDays - ((pruned[pruned.size() - 1] as Array)[0] as Number) >= FIVE_DAYS);
        if (shouldAdd) {
            pruned.add([nowDays, currentVal]);
        }

        if (shouldAdd || pruned.size() != history.size()) {
            Application.Storage.setValue(key, pruned);
        }

        if (pruned.size() < 2) { return ""; }

        var oldest = (pruned[0] as Array)[1] as Number;
        if (currentVal > oldest) { return "b"; }  // ↗
        if (currentVal < oldest) { return "d"; }  // ↘
        return "c";  // →
    }

    function getCgmReading() as String {
        try {
            if (cgmComplicationId == null) {
                cgmComplicationId = getCgmComplicationByLabel("CGM");
            }
            if (cgmComplicationId == null) { return ""; }

            var comp = Complications.getComplication(cgmComplicationId);
            if (comp == null || comp.value == null) { return ""; }

            var valueStr = comp.value.toString();
            if (valueStr.equals("---")) { return "---"; }

            var spaceIndex = valueStr.find(" ");
            if (spaceIndex == null) { return valueStr; }

            var reading = valueStr.substring(0, spaceIndex);
            var trend = valueStr.substring(spaceIndex + 1, valueStr.length());
            var arrow = convertCgmTrendToArrow(trend);
            return reading + arrow;
        } catch (e) {}
        return "";
    }

    function getCgmAge() as String {
        try {
            if (cgmAgeComplicationId == null) {
                cgmAgeComplicationId = getCgmComplicationByLabel("CGM Age");
            }
            if (cgmAgeComplicationId == null) { return ""; }
            var comp = Complications.getComplication(cgmAgeComplicationId);
            if (comp == null || comp.value == null) { return ""; }
            var timestamp = comp.value.toString().toLong();
            if (timestamp == null || timestamp < 0) { return "---"; }
            var ageMin = (Time.now().value() - timestamp) / 60;
            if (ageMin < 0) { return "---"; }
            return ageMin.format("%d");
        } catch (e) {}
        return "";
    }

    function updateVo2History() as Void {
        var profile = UserProfile.getProfile();
        if (profile.vo2maxRunning != null) {
            vo2RunTrend = getVo2Trend("vo2run_hist", profile.vo2maxRunning as Number);
        }
        if (profile.vo2maxCycling != null) {
            vo2BikeTrend = getVo2Trend("vo2bike_hist", profile.vo2maxCycling as Number);
        }
    }

    // --- Formatted value getters for ValueResolver switch ---

    function getActiveMinutesWeekFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.activeMinutesWeek != null) { return info.activeMinutesWeek.total.format("%d"); }
        return "";
    }

    function getActiveHoursWeekFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.activeMinutesWeek != null) { return (info.activeMinutesWeek.total / 60.0).format("%.1f"); }
        return "";
    }

    function getDailyActiveMinutesFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.activeMinutesDay != null) { return info.activeMinutesDay.total.format("%d"); }
        return "";
    }

    function getDailyDistanceFormatted(isMetric as Boolean, width as Number) as String {
        var info = ActivityMonitor.getInfo();
        if (info.distance != null) {
            return formatDistanceByWidth(info.distance / (isMetric ? 100000.0 : 160900.0), width);
        }
        return "";
    }

    function getFloorsClimbedFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.floorsClimbed != null) { return info.floorsClimbed.format("%d"); }
        return "";
    }

    function getMetersClimbedFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.metersClimbed != null) { return info.metersClimbed.format("%d"); }
        return "";
    }

    function getVo2RunFormatted() as String {
        var profile = UserProfile.getProfile();
        if (profile.vo2maxRunning != null) { return vo2RunTrend + (profile.vo2maxRunning as Number).format("%d"); }
        return "";
    }

    function getVo2BikeFormatted() as String {
        var profile = UserProfile.getProfile();
        if (profile.vo2maxCycling != null) { return vo2BikeTrend + (profile.vo2maxCycling as Number).format("%d"); }
        return "";
    }

    function getRespirationRateFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.respirationRate != null) { return info.respirationRate.format("%d"); }
        return "";
    }

    function getHeartRateFormatted() as String {
        var actInfo = Activity.getActivityInfo();
        var sample = actInfo.currentHeartRate;
        if (sample != null) { return sample.format("%01d"); }
        var history = ActivityMonitor.getHeartRateHistory(1, true);
        if (history != null) {
            var hist = history.next();
            if (hist != null && hist.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return hist.heartRate.format("%01d");
            }
        }
        return "";
    }

    function getCaloriesFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.calories != null) { return info.calories.format("%d"); }
        return "";
    }

    function getAltitudeMFormatted() as String {
        var alt = getAltitudeValue();
        if (alt != null) { return alt.format("%d"); }
        return "";
    }

    function getAltitudeFtFormatted() as String {
        var alt = getAltitudeValue();
        if (alt != null) { return (alt * 3.28084).format("%d"); }
        return "";
    }

    function getStressFormatted() as String {
        var st = getStressData();
        if (st != null) { return st.format("%d"); }
        return "";
    }

    function getBBFormatted() as String {
        var bb = getBBData();
        if (bb != null) { return bb.format("%d"); }
        return "";
    }

    function getStepsFormatted(width as Number) as String {
        var info = ActivityMonitor.getInfo();
        if (info.steps != null) {
            var steps = info.steps;
            if (width >= 5 || (width == 4 && steps < 10000)) { return steps.format("%d"); }
            return (steps / 1000).format("%d") + "K";
        }
        return "";
    }

    function getRawDistanceMFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.distance != null) { return (info.distance / 100).format("%d"); }
        return "";
    }

    function getWheelchairPushesFormatted() as String {
        var info = ActivityMonitor.getInfo();
        if (info.pushes != null) { return info.pushes.format("%d"); }
        return "";
    }

    function getWeightKgFormatted(width as Number) as String {
        var profile = UserProfile.getProfile();
        if (profile.weight != null) {
            var weight_kg = profile.weight / 1000.0;
            return weight_kg.format(width == 3 ? "%d" : "%.1f");
        }
        return "";
    }

    function getWeightLbsFormatted() as String {
        var profile = UserProfile.getProfile();
        if (profile.weight != null) { return (profile.weight * 0.00220462).format("%d"); }
        return "";
    }

    function getActiveCaloriesFormatted() as String {
        var info = ActivityMonitor.getInfo();
        var rest_calories = getRestCalories();
        if (info.calories != null && rest_calories > 0) {
            var active_calories = info.calories - rest_calories;
            return active_calories > 0 ? active_calories.format("%d") : "0";
        }
        return "";
    }

    function getActiveTotalCaloriesFormatted() as String {
        var info = ActivityMonitor.getInfo();
        var rest_calories = getRestCalories();
        var total_calories = info.calories != null ? info.calories : 0;
        var active_calories = total_calories - rest_calories;
        active_calories = active_calories > 0 ? active_calories : 0;
        return active_calories.format("%d") + "/" + total_calories.format("%d");
    }

    function getBatteryDaysFormatted() as String {
        var stats = System.getSystemStats();
        if (stats.batteryInDays != null) { return Math.round(stats.batteryInDays).format("%d"); }
        return "";
    }

    function getNotificationCountFormatted() as String {
        var notif_count = System.getDeviceSettings().notificationCount;
        if (notif_count != null && notif_count > 0) { return notif_count.format("%d"); }
        return "";
    }

    function getSolarIntensityFormatted() as String {
        var stats = System.getSystemStats();
        if (stats.solarIntensity != null) { return stats.solarIntensity.format("%d"); }
        return "";
    }

    function getRestingHeartRateFormatted() as String {
        var profile = UserProfile.getProfile();
        if (profile.restingHeartRate != null) { return profile.restingHeartRate.format("%d"); }
        return "";
    }

    // Handles types 58 (run 7d), 59 (bike 7d), 65 (swim 7d), 66 (run month), 67 (run 28d).
    function getRecentActivityDistFormatted(complicationType as Number, distFactor as Float, width as Number) as String {
        if (Time.now().value() - _lastActivityDistUpdate >= 60 * 5) {
            _lastActivityDistUpdate = Time.now().value();
            updateActivityDistCache();
        }
        var dist = 0;
        if      (complicationType == 58) { dist = _cachedRunDist7Days; }
        else if (complicationType == 59) { dist = _cachedBikeDist7Days; }
        else if (complicationType == 65) { dist = _cachedSwimDist7Days; }
        else if (complicationType == 66) { dist = _cachedRunDistMonth; }
        else                             { dist = _cachedRunDist28Days; }
        return formatDistanceByWidth(dist * distFactor, width);
    }

    function getDailyCounterFormatted() as String {
        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var todayKey = today.year * 10000 + today.month * 100 + today.day;
        var storedKey = Application.Storage.getValue("dailyCounterDay") as Number?;
        if (storedKey == null || storedKey != todayKey) {
            Application.Storage.setValue("dailyCounterDay", todayKey);
            Application.Storage.setValue("dailyCounter", 0);
        }
        var count = Application.Storage.getValue("dailyCounter") as Number?;
        return (count != null ? count : 0).format("%d");
    }

    function getLocationDecDegFormatted() as String {
        var pos = Activity.getActivityInfo().currentLocation;
        if (pos != null) { return pos.toDegrees()[0] + " " + pos.toDegrees()[1]; }
        return Application.loadResource(Rez.Strings.LABEL_POS_NA) as String;
    }

    function getLocationMgrsFormatted() as String {
        var pos = Activity.getActivityInfo().currentLocation;
        if (pos != null) { return pos.toGeoString(Position.GEO_MGRS); }
        return Application.loadResource(Rez.Strings.LABEL_POS_NA) as String;
    }

    function getLocationAccuracyFormatted(width as Number) as String {
        var acc = Activity.getActivityInfo().currentLocationAccuracy;
        if (acc != null) {
            if (width < 4) { return (acc as Number).format("%d"); }
            return ["N/A", "LAST", "POOR", "USBL", "GOOD"][acc];
        }
        return "";
    }
}
