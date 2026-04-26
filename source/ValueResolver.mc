import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.WatchUi;
import Toybox.Weather;

// Handles all value and label resolution for configurable fields.
// Holds references to WeatherDisplayHelper and ComplicationHelper, and stores
// a copy of all props it needs so the view does not need to pass them individually.
(:background_excluded)
class ValueResolver {

    // References to other helpers
    hidden var _weatherHelper as WeatherDisplayHelper;
    hidden var _dataHelper as DataHelper;

    // Weather data — updated via setWeatherData() each display cycle
    hidden var _weatherCondition as StoredWeather or Null;
    hidden var _cachedTempUnit as String = "C";

    // Stored props
    hidden var _propIs24H as Boolean = false;
    hidden var _propHourFormat as Number = 0;
    hidden var _propTzHourFormat as Number = 0;
    hidden var _propTzOffset1 as Number = 0;
    hidden var _propTzOffset2 as Number = 0;
    hidden var _propTzName1 as String = "";
    hidden var _propTzName2 as String = "";
    hidden var _propDateFormat as Number = 0;
    hidden var _propDateCustomFormat as String = "DDD, DD MMMM";
    hidden var _propWeekOffset as Number = 0;
    hidden var _propFontSize as Number = 0;
    hidden var _propIsMetricDistance as Boolean = true;
    hidden var _propPressureUnit as Number = 0;
    hidden var _propShowTempUnit as Boolean = true;
    hidden var _propWeatherFormat1 as String = "t w p";
    hidden var _propWeatherFormat2 as String = "c";
    hidden var _propSunriseFieldShows as Number = 39;
    hidden var _propSunsetFieldShows as Number = 40;
    hidden var _propLeftValueShows as Number = 6;
    hidden var _propMiddleValueShows as Number = 10;
    hidden var _propRightValueShows as Number = 0;
    hidden var _propFourthValueShows as Number = 0;

    // Cached labels (moved from View)
    public var strLabelTopLeft as String = "";
    public var strLabelTopRight as String = "";
    public var strLabelBottomLeft as String = "";
    public var strLabelBottomMiddle as String = "";
    public var strLabelBottomRight as String = "";
    public var strLabelBottomFourth as String = "";

    // Info message (moved from View)
    public var infoMessage as String = "";

    function initialize(weatherHelper as WeatherDisplayHelper, dataHelper as DataHelper) {
        _weatherHelper = weatherHelper;
        _dataHelper = dataHelper;
        _weatherCondition = null;
    }

    function configure(
        propIs24H as Boolean,
        propHourFormat as Number,
        propTzHourFormat as Number,
        propTzOffset1 as Number,
        propTzOffset2 as Number,
        propTzName1 as String,
        propTzName2 as String,
        propDateFormat as Number,
        propDateCustomFormat as String,
        propWeekOffset as Number,
        propFontSize as Number,
        propIsMetricDistance as Boolean,
        propPressureUnit as Number,
        propShowTempUnit as Boolean,
        propWeatherFormat1 as String,
        propWeatherFormat2 as String,
        propSunriseFieldShows as Number,
        propSunsetFieldShows as Number,
        propLeftValueShows as Number,
        propMiddleValueShows as Number,
        propRightValueShows as Number,
        propFourthValueShows as Number
    ) as Void {
        _propIs24H = propIs24H;
        _propHourFormat = propHourFormat;
        _propTzHourFormat = propTzHourFormat;
        _propTzOffset1 = propTzOffset1;
        _propTzOffset2 = propTzOffset2;
        _propTzName1 = propTzName1;
        _propTzName2 = propTzName2;
        _propDateFormat = propDateFormat;
        _propDateCustomFormat = propDateCustomFormat;
        _propWeekOffset = propWeekOffset;
        _propFontSize = propFontSize;
        _propIsMetricDistance = propIsMetricDistance;
        _propPressureUnit = propPressureUnit;
        _propShowTempUnit = propShowTempUnit;
        _propWeatherFormat1 = propWeatherFormat1;
        _propWeatherFormat2 = propWeatherFormat2;
        _propSunriseFieldShows = propSunriseFieldShows;
        _propSunsetFieldShows = propSunsetFieldShows;
        _propLeftValueShows = propLeftValueShows;
        _propMiddleValueShows = propMiddleValueShows;
        _propRightValueShows = propRightValueShows;
        _propFourthValueShows = propFourthValueShows;
    }

    // Update weather-related runtime data. Call once at the start of each display cycle.
    function setWeatherData(weatherCondition as StoredWeather or Null, cachedTempUnit as String) as Void {
        _weatherCondition = weatherCondition;
        _cachedTempUnit = cachedTempUnit;
    }

    function updateActiveLabels(fieldWidths as Array<Number>) as Void {
        strLabelTopLeft = getLabelByType(_propSunriseFieldShows, 1);
        strLabelTopRight = getLabelByType(_propSunsetFieldShows, 1);
        if (_propFontSize == 0) {
            strLabelBottomLeft = getLabelByType(_propLeftValueShows, fieldWidths[0] - 1);
            strLabelBottomMiddle = getLabelByType(_propMiddleValueShows, fieldWidths[1] - 1);
            strLabelBottomRight = getLabelByType(_propRightValueShows, fieldWidths[2] - 1);
            strLabelBottomFourth = getLabelByType(_propFourthValueShows, fieldWidths[3] - 1);
        } else { // Large text
            strLabelBottomLeft = getLabelByType(_propLeftValueShows, 1);
            strLabelBottomMiddle = getLabelByType(_propMiddleValueShows, 1);
            strLabelBottomRight = getLabelByType(_propRightValueShows, 1);
            strLabelBottomFourth = getLabelByType(_propFourthValueShows, 1);
        }
    }

    function getValueByTypeWithUnit(complicationType as Number, width as Number) as String {
        var unit = getUnitByType(complicationType);
        if (unit.length() > 0) {
            unit = " " + unit;
        }
        return getValueByType(complicationType, width) + unit;
    }

    function getValueByType(complicationType as Number, width as Number) as String {
        var val = getClockValue(complicationType, width);
        if (val == null) { val = getActivityValue(complicationType, width); }
        if (val == null) { val = getWeatherValue(complicationType, width); }
        if (val == null) { val = getComplicationValue(complicationType, width); }
        return val != null ? val : "";
    }

    hidden function getUnitByType(complicationType as Number) as String {
        var unit = "";
        if(complicationType == 10) { // Calories / day
            unit = Application.loadResource(Rez.Strings.UNIT_KCAL);
        } else if(complicationType == 11) { // Altitude (m)
            unit = Application.loadResource(Rez.Strings.UNIT_M);
        } else if(complicationType == 14) { // Altitude (ft)
            unit = Application.loadResource(Rez.Strings.UNIT_FT);
        } else if(complicationType == 16) { // Steps / day
            unit = Application.loadResource(Rez.Strings.UNIT_STEPS);
        } else if(complicationType == 18) { // Wheelchair pushes
            unit = Application.loadResource(Rez.Strings.UNIT_PUSHES);
        } else if(complicationType == 25) { // Active calories / day
            unit = Application.loadResource(Rez.Strings.UNIT_KCAL);
        } else if(complicationType == 46) { // Active/Total calories / day
            unit = Application.loadResource(Rez.Strings.UNIT_KCAL);
        }
        return unit;
    }

    // Types: -2 (hidden), -1 (date), 15/37 (alt TZ), 27 (week#), 44 (DTG), 48/49/50 (location)
    hidden function getClockValue(complicationType as Number, width as Number) as String? {
        var numberFormat = "%d";
        if (complicationType == -2) { // Hidden
            return "";
        } else if (complicationType == -1) { // Date
            return formatDate(_propDateFormat, _propDateCustomFormat, _propFontSize, _propWeekOffset);
        } else if (complicationType == 15) { // Alt TZ 1
            return secondaryTimezone(_propTzOffset1, width, _propIs24H, _propHourFormat, _propTzHourFormat);
        } else if (complicationType == 27) { // Week number
            var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var week_number = isoWeekNumber(today.year, today.month, today.day, _propWeekOffset);
            return week_number.format(numberFormat);
        } else if (complicationType == 37) { // Alt TZ 2
            return secondaryTimezone(_propTzOffset2, width, _propIs24H, _propHourFormat, _propTzHourFormat);
        } else if (complicationType == 44) { // Military Date Time Group
            return getDateTimeGroup();
        } else if (complicationType == 48) { // Location Long Lat dec deg
            var pos = Activity.getActivityInfo().currentLocation;
            if (pos != null) {
                return pos.toDegrees()[0] + " " + pos.toDegrees()[1];
            } else {
                return Application.loadResource(Rez.Strings.LABEL_POS_NA);
            }
        } else if (complicationType == 49) { // Location Military format
            var pos = Activity.getActivityInfo().currentLocation;
            if (pos != null) {
                return pos.toGeoString(Position.GEO_MGRS);
            } else {
                return Application.loadResource(Rez.Strings.LABEL_POS_NA);
            }
        } else if (complicationType == 50) { // Location Accuracy
            var acc = Activity.getActivityInfo().currentLocationAccuracy;
            if (acc != null) {
                if (width < 4) {
                    return (acc as Number).format("%d");
                } else {
                    return ["N/A", "LAST", "POOR", "USBL", "GOOD"][acc];
                }
            }
            return "";
        }
        return null;
    }

    // Types: 0-4, 8-10, 12-13, 16-20, 23-25, 28-29, 46, 57-59, 62, 65-68 (activity/fitness metrics)
    hidden function getActivityValue(complicationType as Number, width as Number) as String? {
        var numberFormat = "%d";
        var activityInfo = null;
        if (complicationType == 0) { // Active min / week
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.activeMinutesWeek != null) {
                return activityInfo.activeMinutesWeek.total.format(numberFormat);
            }
            return "";
        } else if (complicationType == 62) { // Active hours / week
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.activeMinutesWeek != null) {
                return (activityInfo.activeMinutesWeek.total / 60.0).format("%.1f");
            }
            return "";
        } else if (complicationType == 1) { // Active min / day
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.activeMinutesDay != null) {
                return activityInfo.activeMinutesDay.total.format(numberFormat);
            }
            return "";
        } else if (complicationType == 2) { // distance / day
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.distance != null) {
                return formatDistanceByWidth(activityInfo.distance / (_propIsMetricDistance ? 100000.0 : 160900.0), width);
            }
            return "";
        } else if (complicationType == 3) { // floors climbed / day
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.floorsClimbed != null) {
                return activityInfo.floorsClimbed.format(numberFormat);
            }
            return "";
        } else if (complicationType == 4) { // meters climbed / day
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.metersClimbed != null) {
                return activityInfo.metersClimbed.format(numberFormat);
            }
            return "";
        } else if (complicationType == 8) { // Respiration rate
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.respirationRate != null) {
                return activityInfo.respirationRate.format(numberFormat);
            }
            return "";
        } else if (complicationType == 9) { // Heart Rate (live)
            // Try to retrieve live HR from Activity::Info
            var activity_info = Activity.getActivityInfo();
            var sample = activity_info.currentHeartRate;
            if (sample != null) {
                return sample.format("%01d");
            } else {
                var history = ActivityMonitor.getHeartRateHistory(1, /* newestFirst */ true);
                if (history != null) {
                    var hist = history.next();
                    if ((hist != null) && (hist.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                        return hist.heartRate.format("%01d");
                    }
                }
            }
            return "";
        } else if (complicationType == 10) { // Calories
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.calories != null) {
                return activityInfo.calories.format(numberFormat);
            }
            return "";
        } else if (complicationType == 12) { // Stress
            var st = _dataHelper.getStressData();
            if (st != null) {
                return st.format(numberFormat);
            }
            return "";
        } else if (complicationType == 13) { // Body battery
            var bb = _dataHelper.getBBData();
            if (bb != null) {
                return bb.format(numberFormat);
            }
            return "";
        } else if (complicationType == 16) { // Steps / day
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.steps != null) {
                var steps = activityInfo.steps;
                if (width >= 5) {
                    return steps.format("%d");
                } else if (width == 4 and steps < 10000) {
                    return steps.format("%d");
                } else {
                    return (steps / 1000).format("%d") + "K";
                }
            }
            return "";
        } else if (complicationType == 17) { // Distance (m) / day
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.distance != null) {
                return (activityInfo.distance / 100).format(numberFormat);
            }
            return "";
        } else if (complicationType == 18) { // Wheelchair pushes
            activityInfo = ActivityMonitor.getInfo();
            if (activityInfo.pushes != null) {
                return activityInfo.pushes.format(numberFormat);
            }
            return "";
        } else if (complicationType == 19) { // Weekly run distance
            return _dataHelper.getWeeklyDistanceFromComplication(true, _propIsMetricDistance ? 0.001 : 0.000621371, width);
        } else if (complicationType == 20) { // Weekly bike distance
            return _dataHelper.getWeeklyDistanceFromComplication(false, _propIsMetricDistance ? 0.001 : 0.000621371, width);
        } else if (complicationType == 23) { // Weight kg
            var profile = UserProfile.getProfile();
            if (profile.weight != null) {
                var weight_kg = profile.weight / 1000.0;
                if (width == 3) {
                    return weight_kg.format(numberFormat);
                } else {
                    return weight_kg.format("%.1f");
                }
            }
            return "";
        } else if (complicationType == 24) { // Weight lbs
            var profile = UserProfile.getProfile();
            if (profile.weight != null) {
                return (profile.weight * 0.00220462).format(numberFormat);
            }
            return "";
        } else if (complicationType == 25) { // Act Calories
            activityInfo = ActivityMonitor.getInfo();
            var rest_calories = _dataHelper.getRestCalories();
            // Get total calories and subtract rest calories
            if (activityInfo.calories != null && rest_calories > 0) {
                var active_calories = activityInfo.calories - rest_calories;
                if (active_calories > 0) {
                    return active_calories.format(numberFormat);
                } else { return "0"; }
            }
            return "";
        } else if (complicationType == 28 || complicationType == 29) { // Total distance past 7 days
            return formatDistanceByWidth(_dataHelper.getWeeklyDistance() * (_propIsMetricDistance ? 0.00001 : 0.00000621371), width);
        } else if (complicationType == 46) { // Active / Total calories
            activityInfo = ActivityMonitor.getInfo();
            var rest_calories = _dataHelper.getRestCalories();
            var total_calories = 0;
            // Get total calories and subtract rest calories
            if (activityInfo.calories != null) {
                total_calories = activityInfo.calories;
            }
            var active_calories = total_calories - rest_calories;
            active_calories = (active_calories > 0) ? active_calories : 0; // Ensure active calories is not negative
            return active_calories.format(numberFormat) + "/" + total_calories.format(numberFormat);
        } else if (complicationType == 57) { // Resting Heart Rate
            var profile = UserProfile.getProfile();
            if (profile.restingHeartRate != null) {
                return profile.restingHeartRate.format(numberFormat);
            }
            return "";
        } else if (complicationType == 58 || complicationType == 59) { // Run/bike distance past 7 days
            if (Time.now().value() - _dataHelper.getLastActivityDistUpdate() >= 60*5) {
                _dataHelper.setLastActivityDistUpdate(Time.now().value());
                _dataHelper.updateActivityDistCache();
            }
            var distFactor = _propIsMetricDistance ? 0.001 : 0.000621371;
            return formatDistanceByWidth((complicationType == 58 ? _dataHelper.getCachedRunDist7Days() : _dataHelper.getCachedBikeDist7Days()) * distFactor, width);
        } else if (complicationType == 65) { // Swim distance past 7 days
            if (Time.now().value() - _dataHelper.getLastActivityDistUpdate() >= 60*5) {
                _dataHelper.setLastActivityDistUpdate(Time.now().value());
                _dataHelper.updateActivityDistCache();
            }
            var distFactor = _propIsMetricDistance ? 0.001 : 0.000621371;
            return formatDistanceByWidth(_dataHelper.getCachedSwimDist7Days() * distFactor, width);
        } else if (complicationType == 66 || complicationType == 67) { // Run dist this month / past 28 days
            if (Time.now().value() - _dataHelper.getLastActivityDistUpdate() >= 60*5) {
                _dataHelper.setLastActivityDistUpdate(Time.now().value());
                _dataHelper.updateActivityDistCache();
            }
            var distFactor = _propIsMetricDistance ? 0.001 : 0.000621371;
            return formatDistanceByWidth((complicationType == 66 ? _dataHelper.getCachedRunDistMonth() : _dataHelper.getCachedRunDist28Days()) * distFactor, width);
        } else if (complicationType == 68) { // Daily counter (resets at midnight)
            var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var todayKey = today.year * 10000 + today.month * 100 + today.day;
            var storedKey = Application.Storage.getValue("dailyCounterDay") as Number?;
            if (storedKey == null || storedKey != todayKey) {
                Application.Storage.setValue("dailyCounterDay", todayKey);
                Application.Storage.setValue("dailyCounter", 0);
            }
            var count = Application.Storage.getValue("dailyCounter") as Number?;
            return (count != null ? count : 0).format(numberFormat);
        }
        return null;
    }

    // Types: 22/26 (pressure), 34 (sensor temp), 35/36 (sun), 39-43 (weather), 51/52/55/56 (weather detail), 60/61 (format), 63/64 (twilight)
    hidden function getWeatherValue(complicationType as Number, width as Number) as String? {
        if (complicationType == 22) { // Raw Barometric pressure (hPA)
            var info = Activity.getActivityInfo();
            if (info.rawAmbientPressure != null) {
                return formatPressure(info.rawAmbientPressure / 100.0, width, _propPressureUnit);
            }
            return "";
        } else if (complicationType == 26) { // Sea level pressure (hPA)
            var info = Activity.getActivityInfo();
            if (info.meanSeaLevelPressure != null) {
                return formatPressure(info.meanSeaLevelPressure / 100.0, width, _propPressureUnit);
            }
            return "";
        } else if (complicationType == 34) { // Sensor temperature
            var tempIterator = Toybox.SensorHistory.getTemperatureHistory({:period => 1});
            if (tempIterator != null) {
                var temp = tempIterator.next();
                if (temp != null and temp.data != null) {
                    return formatTemperature(convertTemperature(temp.data, _cachedTempUnit), _propShowTempUnit, _cachedTempUnit);
                }
            }
            return "";
        } else if (complicationType == 35 || complicationType == 36) { // Sunrise / Sunset
            if (_weatherCondition != null) {
                var loc = _weatherCondition.observationLocationPosition;
                if (loc != null) {
                    var now = Time.now();
                    var s = (complicationType == 35) ? Weather.getSunrise(loc, now) : Weather.getSunset(loc, now);
                    return formatSunTime(s, width, _propIs24H, _propHourFormat);
                }
            }
            return "";
        } else if (complicationType == 39) { // High temp
            if (_weatherCondition != null and _weatherCondition.highTemperature != null) {
                var tempVal = _weatherCondition.highTemperature;
                return formatTemperature(convertTemperature(tempVal, _cachedTempUnit), _propShowTempUnit, _cachedTempUnit);
            }
            return "";
        } else if (complicationType == 40) { // Low temp
            if (_weatherCondition != null and _weatherCondition.lowTemperature != null) {
                var tempVal = _weatherCondition.lowTemperature;
                return formatTemperature(convertTemperature(tempVal, _cachedTempUnit), _propShowTempUnit, _cachedTempUnit);
            }
            return "";
        } else if (complicationType == 41) { // Temperature
            return _weatherHelper.getTemperature();
        } else if (complicationType == 42) { // Precipitation chance
            var val = _weatherHelper.getPrecip();
            if (width == 3 and val.equals("100%")) { val = "100"; }
            return val;
        } else if (complicationType == 43) { // Next Sun Event
            var nextSunEventArray = getNextSunEvent(_weatherCondition);
            if (nextSunEventArray != null && nextSunEventArray.size() == 2) {
                return formatSunTime(nextSunEventArray[0], width, _propIs24H, _propHourFormat);
            }
            return "";
        } else if (complicationType == 51) { // UV Index
            return _weatherHelper.getUVIndex();
        } else if (complicationType == 52) { // Humidity
            return _weatherHelper.getHumidity();
        } else if (complicationType == 55) { // Feels like
            return _weatherHelper.getFeelsLike();
        } else if (complicationType == 56) { // Hours to next sun event
            return hoursToNextSunEvent(_weatherCondition);
        } else if (complicationType == 60) { // Weather data 1 format string
            return _weatherHelper.getWeatherByFormat(_propWeatherFormat1);
        } else if (complicationType == 61) { // Weather data 2 format string
            return _weatherHelper.getWeatherByFormat(_propWeatherFormat2);
        } else if (complicationType == 63 || complicationType == 64) { // Civil dawn / Civil dusk
            if (_weatherCondition != null) {
                var loc = _weatherCondition.observationLocationPosition;
                if (loc != null) {
                    var now = Time.now();
                    var sunrise = Weather.getSunrise(loc, now);
                    var sunset = Weather.getSunset(loc, now);
                    if (sunrise != null && sunset != null) {
                        var latDeg = loc.toDegrees()[0];
                        var twilight = getCivilTwilight(latDeg as Double, sunrise, sunset);
                        if (twilight != null) {
                            return formatSunTime(complicationType == 63 ? twilight[0] : twilight[1], width, _propIs24H, _propHourFormat);
                        }
                    }
                }
            }
            return "";
        }
        return null;
    }

    // Types: 5-7 (recovery/VO2), 11/14 (altitude), 21 (training), 30-33/38 (system), 45/47/53/54 (complications)
    hidden function getComplicationValue(complicationType as Number, width as Number) as String? {
        var numberFormat = "%d";
        if (complicationType == 5) { // Time to Recovery (h)
            return _dataHelper.getRecoveryTimeVal(numberFormat);
        } else if (complicationType == 6) { // VO2 Max Running
            var profile = UserProfile.getProfile();
            if (profile.vo2maxRunning != null) {
                return _dataHelper.vo2RunTrend + (profile.vo2maxRunning as Number).format(numberFormat);
            }
            return "";
        } else if (complicationType == 7) { // VO2 Max Cycling
            var profile = UserProfile.getProfile();
            if (profile.vo2maxCycling != null) {
                return _dataHelper.vo2BikeTrend + (profile.vo2maxCycling as Number).format(numberFormat);
            }
            return "";
        } else if (complicationType == 11) { // Altitude (m)
            var alt = _dataHelper.getAltitudeValue();
            if (alt != null) {
                return alt.format(numberFormat);
            }
            return "";
        } else if (complicationType == 14) { // Altitude (ft)
            var alt = _dataHelper.getAltitudeValue();
            if (alt != null) {
                return (alt * 3.28084).format(numberFormat);
            }
            return "";
        } else if (complicationType == 21) { // Training status
            return _dataHelper.getTrainingStatusVal();
        } else if (complicationType == 30) { // Battery percentage
            var battery = System.getSystemStats().battery;
            return battery.format("%d");
        } else if (complicationType == 31) { // Battery days remaining
            var stats35 = System.getSystemStats();
            if (stats35.batteryInDays != null) {
                return Math.round(stats35.batteryInDays).format(numberFormat);
            }
            return "";
        } else if (complicationType == 32) { // Notification count
            var notif_count = System.getDeviceSettings().notificationCount;
            if (notif_count != null) {
                if (notif_count == 0) {
                    return ""; // Hide when zero
                } else {
                    return notif_count.format(numberFormat);
                }
            }
        } else if (complicationType == 33) { // Solar intensity
            var stats37 = System.getSystemStats();
            if (stats37.solarIntensity != null) {
                return stats37.solarIntensity.format(numberFormat);
            }
            return "";
        } else if (complicationType == 38) { // Alarms
            return System.getDeviceSettings().alarmCount.format(numberFormat);
        } else if (complicationType == 45) { // Time of the next Calendar Event
            return _dataHelper.getCalendarEventVal(width);
        } else if (complicationType == 47) { // PulseOx
            return _dataHelper.getPulseOxVal(numberFormat);
        } else if (complicationType == 53) { // CGM Glucose + Trend
            return _dataHelper.getCgmReading();
        } else if (complicationType == 54) { // CGM Age (minutes)
            return _dataHelper.getCgmAge();
        }
        return null;
    }

    function getLabelByType(complicationType as Number, labelSize as Number) as String {
        // labelSize 1 = short, 2 = mid
        if(complicationType == 15) { return _propTzName1.toUpper() + ":"; }
        if(complicationType == 37) { return _propTzName2.toUpper() + ":"; }
        switch(complicationType) {
            case 0: return formatLabel(Rez.Strings.LABEL_WMIN_1, Rez.Strings.LABEL_WMIN_2, labelSize);
            case 62: return formatLabel(Rez.Strings.LABEL_WHRS_1, Rez.Strings.LABEL_WHRS_2, labelSize);
            case 1: return formatLabel(Rez.Strings.LABEL_DMIN_1, Rez.Strings.LABEL_DMIN_2, labelSize);
            case 2:
                if(_propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_DKM_1, Rez.Strings.LABEL_DKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_DMI_1, Rez.Strings.LABEL_DMI_2, labelSize);
            case 3: return Application.loadResource(Rez.Strings.LABEL_FLOORS);
            case 4: return formatLabel(Rez.Strings.LABEL_CLIMB_1, Rez.Strings.LABEL_CLIMB_2, labelSize);
            case 5: return formatLabel(Rez.Strings.LABEL_RECOV_1, Rez.Strings.LABEL_RECOV_2, labelSize);
            case 6: return formatLabel(Rez.Strings.LABEL_VO2_1, Rez.Strings.LABEL_VO2RUN_2, labelSize);
            case 7: return formatLabel(Rez.Strings.LABEL_VO2_1, Rez.Strings.LABEL_VO2BIKE_2, labelSize);
            case 8: return formatLabel(Rez.Strings.LABEL_RESP_1, Rez.Strings.LABEL_RESP_2, labelSize);
            case 9: return Application.loadResource(Rez.Strings.LABEL_HR);
            case 10: return formatLabel(Rez.Strings.LABEL_CAL_1, Rez.Strings.LABEL_CAL_2, labelSize);
            case 11: return formatLabel(Rez.Strings.LABEL_ALT_1, Rez.Strings.LABEL_ALT_2, labelSize);
            case 12: return Application.loadResource(Rez.Strings.LABEL_STRESS);
            case 13: return formatLabel(Rez.Strings.LABEL_BBAT_1, Rez.Strings.LABEL_BBAT_2, labelSize);
            case 14: return formatLabel(Rez.Strings.LABEL_ALT_1, Rez.Strings.LABEL_ALT_2, labelSize);
            case 16: return Application.loadResource(Rez.Strings.LABEL_STEPS);
            case 17: return formatLabel(Rez.Strings.LABEL_DIST_1, Rez.Strings.LABEL_DIST_2, labelSize);
            case 18: return Application.loadResource(Rez.Strings.LABEL_PUSHES);
            case 66:
            case 67:
                if(_propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_MKM_1, Rez.Strings.LABEL_MRUNKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_MMI_1, Rez.Strings.LABEL_MRUNMI_2, labelSize);
            case 58:
            case 19:
                if(_propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WRUNM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WRUNMI_2, labelSize);
            case 59:
            case 20:
                if(_propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WBIKEKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WBIKEMI_2, labelSize);
            case 21: return Application.loadResource(Rez.Strings.LABEL_TRAINING);
            case 22: return Application.loadResource(Rez.Strings.LABEL_PRESSURE);
            case 23: return formatLabel(Rez.Strings.LABEL_KG_1, Rez.Strings.LABEL_WEIGHT_2, labelSize);
            case 24: return formatLabel(Rez.Strings.LABEL_LBS_1, Rez.Strings.LABEL_WEIGHT_2, labelSize);
            case 25: return formatLabel(Rez.Strings.LABEL_ACAL_1, Rez.Strings.LABEL_ACAL_2, labelSize);
            case 26: return Application.loadResource(Rez.Strings.LABEL_PRESSURE);
            case 27: return Application.loadResource(Rez.Strings.LABEL_WEEK);
            case 29:
            case 28:
                if(_propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WDISTKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WDISTMI_2, labelSize);
            case 30: return formatLabel(Rez.Strings.LABEL_BATT_1, Rez.Strings.LABEL_BATT_2, labelSize);
            case 31: return formatLabel(Rez.Strings.LABEL_BATTD_1, Rez.Strings.LABEL_BATTD_2, labelSize);
            case 32: return formatLabel(Rez.Strings.LABEL_NOTIFS_1, Rez.Strings.LABEL_NOTIFS_1, labelSize);
            case 33: return formatLabel(Rez.Strings.LABEL_SUN_1, Rez.Strings.LABEL_SUNINT_2, labelSize);
            case 34: return formatLabel(Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_STEMP_2, labelSize);
            case 35: return formatLabel(Rez.Strings.LABEL_SUNRISE_1, Rez.Strings.LABEL_SUNRISE_2, labelSize);
            case 36: return formatLabel(Rez.Strings.LABEL_SUNSET_1, Rez.Strings.LABEL_SUNSET_2, labelSize);
            case 38: return formatLabel(Rez.Strings.LABEL_ALARM_1, Rez.Strings.LABEL_ALARM_2, labelSize);
            case 39: return formatLabel(Rez.Strings.LABEL_HIGH_1, Rez.Strings.LABEL_HIGH_2, labelSize);
            case 40: return formatLabel(Rez.Strings.LABEL_LOW_1, Rez.Strings.LABEL_LOW_2, labelSize);
            case 41: return formatLabel(Rez.Strings.LABEL_TEMP_1, Rez.Strings.LABEL_TEMP_1, labelSize);
            case 42: return formatLabel(Rez.Strings.LABEL_PRECIP_1, Rez.Strings.LABEL_PRECIP_1, labelSize);
            case 43: return formatLabel(Rez.Strings.LABEL_NEXTSUN_1, Rez.Strings.LABEL_NEXTSUN_2, labelSize);
            case 45: return formatLabel(Rez.Strings.LABEL_NEXTCAL_1, Rez.Strings.LABEL_NEXTCAL_2, labelSize);
            case 47: return formatLabel(Rez.Strings.LABEL_OX_1, Rez.Strings.LABEL_OX_2, labelSize);
            case 50: return formatLabel(Rez.Strings.LABEL_ACC_1, Rez.Strings.LABEL_ACC_2, labelSize);
            case 51: return formatLabel(Rez.Strings.LABEL_UV_1, Rez.Strings.LABEL_UV_2, labelSize);
            case 52: return formatLabel(Rez.Strings.LABEL_HUM_1, Rez.Strings.LABEL_HUM_2, labelSize);
            case 53: return WatchUi.loadResource(Rez.Strings.LABEL_CGM) as String;
            case 54: return WatchUi.loadResource(Rez.Strings.LABEL_CGMAGE) as String;
            case 55: return formatLabel(Rez.Strings.LABEL_FL, Rez.Strings.LABEL_FL_2, labelSize);
            case 56: return formatLabel(Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_1, Rez.Strings.LABEL_HRS_NEXT_SUN_EVENT_1, labelSize);
            case 57: return formatLabel(Rez.Strings.LABEL_RHR_1, Rez.Strings.LABEL_RHR_2, labelSize);
            case 63: return Application.loadResource(Rez.Strings.LABEL_DAWN_1) as String;
            case 64: return Application.loadResource(Rez.Strings.LABEL_DUSK_1) as String;
            case 65:
                if(_propIsMetricDistance) { return formatLabel(Rez.Strings.LABEL_WKM_1, Rez.Strings.LABEL_WSWIMKM_2, labelSize); }
                return formatLabel(Rez.Strings.LABEL_WMI_1, Rez.Strings.LABEL_WSWIMMI_2, labelSize);
            case 68: return formatLabel(Rez.Strings.LABEL_CNT_1, Rez.Strings.LABEL_CNT_2, labelSize);
        }
        return "";
    }

}
