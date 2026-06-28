import Toybox.Application;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;

(:background)
class OpenMeteoService {

    hidden var _lat as Float = 0.0;
    hidden var _lon as Float = 0.0;

    function initialize() {}

    function fetchWeather(lat as Float, lon as Float) as Void {
        _lat = lat;
        _lon = lon;
        Communications.makeWebRequest(
            "https://api.open-meteo.com/v1/forecast",
            {
                "latitude"        => lat,
                "longitude"       => lon,
                "current"         => "temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m",
                "hourly"          => "temperature_2m,precipitation_probability,precipitation,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,uv_index,uv_index_clear_sky",
                "daily"           => "temperature_2m_max,temperature_2m_min",
                "timeformat"      => "unixtime",
                "forecast_days"   => 2,
                "forecast_hours"  => 8,
                "wind_speed_unit" => "ms"
            },
            { :method => Communications.HTTP_REQUEST_METHOD_GET,
              :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON },
            method(:onResponse)
        );
    }

    function onResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode >= 400 && responseCode < 500) {
            Application.Storage.setValue("wx_error", "OM: ERROR " + responseCode.toString());
            return;
        }
        if (responseCode != 200 || data == null) {
            // Network or server error — keep cached data, leave wx_error untouched.
            return;
        }
        Application.Storage.deleteValue("wx_error");

        var now = Time.now().value();
        var cc_data = {};

        // Current conditions block.
        var current = data.get("current") as Dictionary?;
        if (current != null) {
            var temp = current.get("temperature_2m");
            if (temp != null) { cc_data["temperature"] = (temp as Float).toNumber(); }
            var feelsLike = current.get("apparent_temperature");
            if (feelsLike != null) { cc_data["feelsLikeTemperature"] = (feelsLike as Float).toFloat(); }
            var humidity = current.get("relative_humidity_2m");
            if (humidity != null) { cc_data["relativeHumidity"] = humidity as Number; }
            var windSpeed = current.get("wind_speed_10m");
            if (windSpeed != null) { cc_data["windSpeed"] = (windSpeed as Float).toFloat(); }
            var windDir = current.get("wind_direction_10m");
            if (windDir != null) { cc_data["windBearing"] = (windDir as Float).toNumber(); }
            var windGust = current.get("wind_gusts_10m");
            if (windGust != null) { cc_data["windGust"] = (windGust as Float).toFloat(); }
            var precip = current.get("precipitation");
            if (precip != null && (precip as Float) > 0.0f) {
                cc_data["precipitationAmount"] = (precip as Float).toFloat();
            }
            var wCode = current.get("weather_code");
            if (wCode != null) { cc_data["condition"] = wmoCodeToGarmin(wCode as Number); }
            var obsTime = current.get("time");
            if (obsTime != null) { cc_data["observationTime"] = obsTime as Number; }
        }

        // Hourly block: build forecast array and harvest UV + precip chance for slot 0.
        var hf_data = [] as Array<Dictionary>;
        var hourly = data.get("hourly") as Dictionary?;
        if (hourly != null) {
            var times   = hourly.get("time")                     as Array?;
            var temps   = hourly.get("temperature_2m")           as Array?;
            var popArr  = hourly.get("precipitation_probability") as Array?;
            var precipArr = hourly.get("precipitation")          as Array?;
            var wCodes  = hourly.get("weather_code")             as Array?;
            var wSpeeds = hourly.get("wind_speed_10m")           as Array?;
            var wDirs   = hourly.get("wind_direction_10m")       as Array?;
            var wGusts  = hourly.get("wind_gusts_10m")           as Array?;
            var uvArr   = hourly.get("uv_index")                 as Array?;
            var uvClear = hourly.get("uv_index_clear_sky")        as Array?;

            // UV source toggle (Open-Meteo only). When enabled, use clear-sky UV
            // (matching Garmin's convention); otherwise use the cloud-adjusted value.
            var useClearSky = false;
            var toggle = Application.Properties.getValue("uvIndexClearSky");
            if (toggle != null && (toggle as Boolean)) { useClearSky = true; }

            if (times != null) {
                var count = times.size();
                for (var i = 0; i < count; i++) {
                    var tmp = {} as Dictionary;
                    tmp["forecastTime"] = times[i] as Number;
                    if (temps   != null && temps[i]    != null) { tmp["temperature"]        = (temps[i]    as Float).toNumber(); }
                    if (popArr  != null && popArr[i]   != null) { tmp["precipitationChance"] = popArr[i]  as Number; }
                    if (precipArr != null && precipArr[i] != null) {
                        var pa = (precipArr[i] as Float).toFloat();
                        if (pa > 0.0f) { tmp["precipitationAmount"] = pa; }
                    }
                    if (wCodes  != null && wCodes[i]   != null) { tmp["condition"]          = wmoCodeToGarmin(wCodes[i] as Number); }
                    if (wSpeeds != null && wSpeeds[i]  != null) { tmp["windSpeed"]          = (wSpeeds[i] as Float).toFloat(); }
                    if (wDirs   != null && wDirs[i]    != null) { tmp["windBearing"]        = (wDirs[i]   as Float).toNumber(); }
                    if (wGusts  != null && wGusts[i]   != null) { tmp["windGust"]           = (wGusts[i]  as Float).toFloat(); }
                    var uvSrc = useClearSky ? uvClear : uvArr;
                    if (uvSrc   != null && uvSrc[i]    != null) { tmp["uvIndex"]            = (uvSrc[i]   as Float).toFloat(); }
                    hf_data.add(tmp);
                }
            }

            // Pull UV index and precipitation chance from the first hourly slot (current hour).
            if (hf_data.size() > 0) {
                var first = hf_data[0];
                var pop0 = first.get("precipitationChance");
                if (pop0 != null) { cc_data["precipitationChance"] = pop0; }
                var uv0 = first.get("uvIndex");
                if (uv0 != null) {
                    cc_data["uvIndex"] = uv0;
                }
            }
        }

        // Daily block: today's high and low (index 0).
        var daily = data.get("daily") as Dictionary?;
        if (daily != null) {
            var maxArr = daily.get("temperature_2m_max") as Array?;
            var minArr = daily.get("temperature_2m_min") as Array?;
            if (maxArr != null && maxArr.size() > 0 && maxArr[0] != null) {
                cc_data["highTemperature"] = (maxArr[0] as Float).toNumber();
            }
            if (minArr != null && minArr.size() > 0 && minArr[0] != null) {
                cc_data["lowTemperature"] = (minArr[0] as Float).toNumber();
            }
        }

        cc_data["observationLocationPosition"] = [_lat, _lon];
        cc_data["timestamp"] = now;
        Application.Storage.setValue("current_conditions", cc_data);
        Application.Storage.setValue("hourly_forecast", hf_data);
        Application.Storage.setValue("wx_last_update", now);
        var interval = Application.Properties.getValue("owmRefreshInterval") as Number;
        Background.registerForTemporalEvent(new Time.Duration(interval));
    }

    // Maps WMO weather interpretation code to Garmin Weather.Condition enum (0–53).
    static function wmoCodeToGarmin(code as Number) as Number {
        if (code == 0)  { return 0; }   // Clear sky
        if (code == 1)  { return 1; }   // Mainly clear → Partly Cloudy
        if (code == 2)  { return 1; }   // Partly cloudy
        if (code == 3)  { return 20; }  // Overcast
        if (code == 45 || code == 48) { return 8; }   // Fog / Rime fog
        if (code == 51 || code == 53) { return 14; }  // Light/moderate drizzle → Light Rain
        if (code == 55) { return 3; }   // Dense drizzle → Rain
        if (code == 56 || code == 57) { return 32; }  // Freezing drizzle → Freezing Rain
        if (code == 61) { return 14; }  // Slight rain → Light Rain
        if (code == 63) { return 3; }   // Moderate rain → Rain
        if (code == 65) { return 15; }  // Heavy rain → Heavy Rain
        if (code == 66 || code == 67) { return 32; }  // Freezing rain
        if (code == 71) { return 16; }  // Slight snowfall → Light Snow
        if (code == 73) { return 4; }   // Moderate snowfall → Snow
        if (code == 75) { return 17; }  // Heavy snowfall → Heavy Snow
        if (code == 77) { return 16; }  // Snow grains → Light Snow
        if (code == 80 || code == 81) { return 11; }  // Rain showers → Scattered Showers
        if (code == 82) { return 15; }  // Violent rain showers → Heavy Rain
        if (code == 85 || code == 86) { return 26; }  // Snow showers
        if (code == 95) { return 6; }   // Thunderstorm
        if (code == 96 || code == 99) { return 6; }   // Thunderstorm with hail
        return 53; // Unknown
    }
}
