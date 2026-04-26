// Weather display formatting helpers.
// The View holds one instance and calls update() after every weather/property refresh.
import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

class WeatherDisplayHelper {
    hidden var _w as StoredWeather or Null = null;
    hidden var _owmError as String or Null = null;
    hidden var _tempUnit as String = "C";
    hidden var _showTempUnit as Boolean = true;
    hidden var _windUnit as Number = 0;
    hidden var _precipAmountUnit as Number = 0;
    hidden var _is24H as Boolean = false;
    hidden var _hourFormat as Number = 0;

    function initialize() {}

    function update(
        w as StoredWeather or Null,
        owmError as String or Null,
        tempUnit as String,
        showTempUnit as Boolean,
        windUnit as Number,
        precipAmountUnit as Number,
        is24H as Boolean,
        hourFormat as Number
    ) as Void {
        _w = w;
        _owmError = owmError;
        _tempUnit = tempUnit;
        _showTempUnit = showTempUnit;
        _windUnit = windUnit;
        _precipAmountUnit = precipAmountUnit;
        _is24H = is24H;
        _hourFormat = hourFormat;
    }

    function getTempUnit(propTempUnit as Number) as String {
        var temp_unit_setting = System.getDeviceSettings().temperatureUnits;
        if ((temp_unit_setting == System.UNIT_METRIC and propTempUnit == 0) or propTempUnit == 1) {
            return "C";
        } else {
            return "F";
        }
    }

    function getCityName() as String {
        if (_w == null || (_w as StoredWeather).cityName == null) { return ""; }
        return (_w as StoredWeather).cityName.toUpper();
    }

    function getWeatherCondition() as String {
        if (_owmError != null) { return _owmError as String; }
        if (_w == null || (_w as StoredWeather).condition == null) { return ""; }
        var weatherStrings = [
            Rez.Strings.WEATHER_0,  Rez.Strings.WEATHER_1,  Rez.Strings.WEATHER_2,  Rez.Strings.WEATHER_3,
            Rez.Strings.WEATHER_4,  Rez.Strings.WEATHER_5,  Rez.Strings.WEATHER_6,  Rez.Strings.WEATHER_7,
            Rez.Strings.WEATHER_8,  Rez.Strings.WEATHER_9,  Rez.Strings.WEATHER_10, Rez.Strings.WEATHER_11,
            Rez.Strings.WEATHER_12, Rez.Strings.WEATHER_13, Rez.Strings.WEATHER_14, Rez.Strings.WEATHER_15,
            Rez.Strings.WEATHER_16, Rez.Strings.WEATHER_17, Rez.Strings.WEATHER_18, Rez.Strings.WEATHER_19,
            Rez.Strings.WEATHER_20, Rez.Strings.WEATHER_21, Rez.Strings.WEATHER_22, Rez.Strings.WEATHER_23,
            Rez.Strings.WEATHER_24, Rez.Strings.WEATHER_25, Rez.Strings.WEATHER_26, Rez.Strings.WEATHER_27,
            Rez.Strings.WEATHER_28, Rez.Strings.WEATHER_29, Rez.Strings.WEATHER_30, Rez.Strings.WEATHER_31,
            Rez.Strings.WEATHER_32, Rez.Strings.WEATHER_33, Rez.Strings.WEATHER_34, Rez.Strings.WEATHER_35,
            Rez.Strings.WEATHER_36, Rez.Strings.WEATHER_37, Rez.Strings.WEATHER_38, Rez.Strings.WEATHER_39,
            Rez.Strings.WEATHER_40, Rez.Strings.WEATHER_41, Rez.Strings.WEATHER_42, Rez.Strings.WEATHER_43,
            Rez.Strings.WEATHER_44, Rez.Strings.WEATHER_45, Rez.Strings.WEATHER_46, Rez.Strings.WEATHER_47,
            Rez.Strings.WEATHER_48, Rez.Strings.WEATHER_49, Rez.Strings.WEATHER_50, Rez.Strings.WEATHER_51,
            Rez.Strings.WEATHER_52, Rez.Strings.WEATHER_53
        ];
        var idx = (_w as StoredWeather).condition.toNumber();
        if (idx < 0 || idx >= weatherStrings.size()) { idx = 53; }
        return Application.loadResource(weatherStrings[idx]);
    }

    function getWeatherConditionShort() as String {
        if (_owmError != null) { return _owmError as String; }
        if (_w == null || (_w as StoredWeather).condition == null) { return ""; }
        var short = [
            "CLEAR", "CLOUDY", "CLOUDY", "RAIN", "SNOW", "WINDY", "THUNDER",
            "WINTRY", "FOG", "HAZY", "HAIL", "SHOWERS", "THUNDER", "UNKNOWN",
            "RAIN", "HVY RAIN", "SNOW", "HVY SNOW", "RAIN SNOW", "RAIN SNOW",
            "CLOUDY", "RAIN SNOW", "CLEAR", "CLEAR", "SHOWERS", "SHOWERS",
            "SHOWERS", "(SHOWERS)", "(THUNDER)", "MIST", "DUST", "DRIZZLE",
            "TORNADO", "SMOKE", "ICE", "SAND", "SQUALL", "SANDSTORM",
            "VOLC ASH", "HAZE", "FAIR", "HURRICANE", "TROP STORM", "(SNOW)",
            "(RAIN SNOW)", "(RAIN)", "(SNOW)", "(RAIN SNOW)", "FLURRIES",
            "FRZ RAIN", "SLEET", "ICE SNOW", "CLOUDY", "UNKNOWN"
        ];
        var idx = (_w as StoredWeather).condition.toNumber();
        if (idx < 0 || idx >= short.size()) { idx = 53; }
        return short[idx];
    }

    function getTemperature() as String {
        if (_w != null and (_w as StoredWeather).temperature != null) {
            var temp_val = (_w as StoredWeather).temperature;
            return formatTemperature(convertTemperature(temp_val, _tempUnit), _showTempUnit, _tempUnit);
        }
        return "";
    }

    function getWind() as String {
        var bearing = "";
        var windspeed = "";
        if (_w != null and (_w as StoredWeather).windSpeed != null) {
            windspeed = formatWindSpeed((_w as StoredWeather).windSpeed as Float, _windUnit);
        }
        if (_w != null and (_w as StoredWeather).windBearing != null) {
            bearing = ((Math.round(((_w as StoredWeather).windBearing.toFloat() + 180) / 45.0).toNumber() % 8) + 97).toChar().toString();
        }
        return bearing + windspeed;
    }

    function getWindGust() as String {
        if (_w == null) { return ""; }
        var gust_mps = (_w as StoredWeather).windGust;
        if (gust_mps == null) { return ""; }
        return formatWindSpeed(gust_mps as Float, _windUnit);
    }

    function getPrecipAmount() as String {
        if (_w == null) { return ""; }
        var mm_h = (_w as StoredWeather).precipitationAmount;
        if (mm_h == null) { return ""; }
        var useMetric = (_precipAmountUnit == 1) ||
            (_precipAmountUnit == 0 && System.getDeviceSettings().distanceUnits == System.UNIT_METRIC);
        if (useMetric) {
            return (mm_h as Float).format("%.1f");
        } else {
            return ((mm_h as Float) * 0.03937f).format("%.2f");
        }
    }

    function getObservationTime() as String {
        if (_w == null) { return ""; }
        var ts = (_w as StoredWeather).observationTimestamp;
        if (ts == null) { return ""; }
        var info = Time.Gregorian.info(new Time.Moment(ts as Number), Time.FORMAT_SHORT);
        var h = formatHour(info.hour, _is24H, _hourFormat);
        return h.format("%02d") + ":" + info.min.format("%02d");
    }

    function getFeelsLike() as String {
        if (_w != null and (_w as StoredWeather).feelsLikeTemperature != null) {
            return formatTemperature(convertTemperature((_w as StoredWeather).feelsLikeTemperature, _tempUnit), _showTempUnit, _tempUnit);
        }
        return "";
    }

    function getHumidity() as String {
        var ret = "";
        if (_w != null and (_w as StoredWeather).relativeHumidity != null) {
            ret = (_w as StoredWeather).relativeHumidity.format("%d") + "%";
        }
        return ret;
    }

    function getUVIndex() as String {
        var ret = "";
        if (_w != null and (_w as StoredWeather).uvIndex != null) {
            ret = (_w as StoredWeather).uvIndex.format("%d");
        }
        return ret;
    }

    function getHighLow() as String {
        var ret = "";
        if (_w != null) {
            if ((_w as StoredWeather).highTemperature != null and (_w as StoredWeather).lowTemperature != null) {
                var high = convertTemperature((_w as StoredWeather).highTemperature, _tempUnit);
                var low  = convertTemperature((_w as StoredWeather).lowTemperature,  _tempUnit);
                ret = formatTemperature(high, _showTempUnit, _tempUnit) + "/" + formatTemperature(low, _showTempUnit, _tempUnit);
            }
        }
        return ret;
    }

    function getPrecip() as String {
        var ret = "";
        if (_w != null and (_w as StoredWeather).precipitationChance != null) {
            ret = (_w as StoredWeather).precipitationChance.format("%d") + "%";
        }
        return ret;
    }

    function getWeatherByFormat(format as String) as String {
        var result = "";
        var i = 0;
        while (i < format.length()) {
            var ch = format.substring(i, i + 1);
            if      (ch.equals("t")) { result = result + getTemperature(); }
            else if (ch.equals("w")) { result = result + getWind(); }
            else if (ch.equals("g")) { result = result + getWindGust(); }
            else if (ch.equals("h")) { result = result + getHumidity(); }
            else if (ch.equals("p")) { result = result + getPrecip(); }
            else if (ch.equals("r")) { result = result + getPrecipAmount(); }
            else if (ch.equals("u")) { result = result + getUVIndex(); }
            else if (ch.equals("l")) { result = result + getHighLow(); }
            else if (ch.equals("f")) { result = result + getFeelsLike(); }
            else if (ch.equals("c")) { result = result + getWeatherCondition(); }
            else if (ch.equals("s")) { result = result + getWeatherConditionShort(); }
            else if (ch.equals("n")) { result = result + getCityName(); }
            else if (ch.equals("o")) { result = result + getObservationTime(); }
            else { result = result + ch; }
            i += 1;
        }
        return result;
    }
}
