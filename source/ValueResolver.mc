import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

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
        var distFactor = (_propIsMetricDistance ? 0.001 : 0.000621371) as Float;
        switch (complicationType) {
            case -2: return "";
            case -1: return formatDate(_propDateFormat, _propDateCustomFormat, _propFontSize, _propWeekOffset);
            case 0:  return _dataHelper.getActiveMinutesWeekFormatted();
            case 1:  return _dataHelper.getDailyActiveMinutesFormatted();
            case 2:  return _dataHelper.getDailyDistanceFormatted(_propIsMetricDistance, width);
            case 3:  return _dataHelper.getFloorsClimbedFormatted();
            case 4:  return _dataHelper.getMetersClimbedFormatted();
            case 5:  return _dataHelper.getRecoveryTimeVal("%d");
            case 6:  return _dataHelper.getVo2RunFormatted();
            case 7:  return _dataHelper.getVo2BikeFormatted();
            case 8:  return _dataHelper.getRespirationRateFormatted();
            case 9:  return _dataHelper.getHeartRateFormatted();
            case 10: return _dataHelper.getCaloriesFormatted();
            case 11: return _dataHelper.getAltitudeMFormatted();
            case 12: return _dataHelper.getStressFormatted();
            case 13: return _dataHelper.getBBFormatted();
            case 14: return _dataHelper.getAltitudeFtFormatted();
            case 15: return secondaryTimezone(_propTzOffset1, width, _propIs24H, _propHourFormat, _propTzHourFormat);
            case 16: return _dataHelper.getStepsFormatted(width);
            case 17: return _dataHelper.getRawDistanceMFormatted();
            case 18: return _dataHelper.getWheelchairPushesFormatted();
            case 19: return _dataHelper.getWeeklyDistanceFromComplication(true, distFactor, width);
            case 20: return _dataHelper.getWeeklyDistanceFromComplication(false, distFactor, width);
            case 21: return _dataHelper.getTrainingStatusVal();
            case 22:
            case 26: return getBarometricPressureFormatted(complicationType, width);
            case 23: return _dataHelper.getWeightKgFormatted(width);
            case 24: return _dataHelper.getWeightLbsFormatted();
            case 25: return _dataHelper.getActiveCaloriesFormatted();
            case 27: return getWeekNumberFormatted();
            case 28:
            case 29: return formatDistanceByWidth(_dataHelper.getWeeklyDistance() * (_propIsMetricDistance ? 0.00001 : 0.00000621371), width);
            case 30: return System.getSystemStats().battery.format("%d");
            case 31: return _dataHelper.getBatteryDaysFormatted();
            case 32: return _dataHelper.getNotificationCountFormatted();
            case 33: return _dataHelper.getSolarIntensityFormatted();
            case 34: return _weatherHelper.getSensorTemperatureFormatted();
            case 35:
            case 36: return _weatherHelper.getSunriseOrSunsetFormatted(complicationType, width);
            case 37: return secondaryTimezone(_propTzOffset2, width, _propIs24H, _propHourFormat, _propTzHourFormat);
            case 38: return System.getDeviceSettings().alarmCount.format("%d");
            case 39: return _weatherHelper.getHighTempFormatted();
            case 40: return _weatherHelper.getLowTempFormatted();
            case 41: return _weatherHelper.getTemperature();
            case 42: return _weatherHelper.getPrecipFormatted(width);
            case 43: return _weatherHelper.getNextSunEventFormatted(width);
            case 44: return getDateTimeGroup();
            case 45: return _dataHelper.getCalendarEventVal(width);
            case 46: return _dataHelper.getActiveTotalCaloriesFormatted();
            case 47: return _dataHelper.getPulseOxVal("%d");
            case 48: return _dataHelper.getLocationDecDegFormatted();
            case 49: return _dataHelper.getLocationMgrsFormatted();
            case 50: return _dataHelper.getLocationAccuracyFormatted(width);
            case 51: return _weatherHelper.getUVIndex();
            case 52: return _weatherHelper.getHumidity();
            case 53: return _dataHelper.getCgmReading();
            case 54: return _dataHelper.getCgmAge();
            case 55: return _weatherHelper.getFeelsLike();
            case 56: return hoursToNextSunEvent(_weatherCondition);
            case 57: return _dataHelper.getRestingHeartRateFormatted();
            case 58:
            case 59:
            case 65:
            case 66:
            case 67: return _dataHelper.getRecentActivityDistFormatted(complicationType, distFactor, width);
            case 60: return _weatherHelper.getWeatherByFormat(_propWeatherFormat1);
            case 61: return _weatherHelper.getWeatherByFormat(_propWeatherFormat2);
            case 62: return _dataHelper.getActiveHoursWeekFormatted();
            case 63:
            case 64: return _weatherHelper.getCivilTwilightFormatted(complicationType, width);
            case 68: return _dataHelper.getDailyCounterFormatted();
        }
        return "";
    }

    hidden function getBarometricPressureFormatted(complicationType as Number, width as Number) as String {
        var info = Activity.getActivityInfo();
        if (complicationType == 22 && info.rawAmbientPressure != null) {
            return formatPressure(info.rawAmbientPressure / 100.0, width, _propPressureUnit);
        }
        if (complicationType == 26 && info.meanSeaLevelPressure != null) {
            return formatPressure(info.meanSeaLevelPressure / 100.0, width, _propPressureUnit);
        }
        return "";
    }

    hidden function getWeekNumberFormatted() as String {
        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return isoWeekNumber(today.year, today.month, today.day, _propWeekOffset).format("%d");
    }

    hidden function getUnitByType(complicationType as Number) as String {
        switch (complicationType) {
            case 10:
            case 25:
            case 46: return Application.loadResource(Rez.Strings.UNIT_KCAL) as String;
            case 11: return Application.loadResource(Rez.Strings.UNIT_M) as String;
            case 14: return Application.loadResource(Rez.Strings.UNIT_FT) as String;
            case 16: return Application.loadResource(Rez.Strings.UNIT_STEPS) as String;
            case 18: return Application.loadResource(Rez.Strings.UNIT_PUSHES) as String;
        }
        return "";
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
