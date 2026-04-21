import Toybox.Application;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Weather;

(:background)
class OpenWeatherService {

    hidden var _lat as Float = 0.0;
    hidden var _lon as Float = 0.0;

    function initialize() {}

    // Fire both current-conditions and forecast requests simultaneously.
    function fetchWeather(lat as Float, lon as Float, apiKey as String) as Void {
        _lat = lat;
        _lon = lon;
        Communications.makeWebRequest(
            "https://api.openweathermap.org/data/2.5/weather",
            { "lat" => lat, "lon" => lon, "appid" => apiKey, "units" => "metric" },
            { :method => Communications.HTTP_REQUEST_METHOD_GET,
              :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON },
            method(:onCurrentResponse)
        );
        Communications.makeWebRequest(
            "https://api.openweathermap.org/data/2.5/forecast",
            { "lat" => lat, "lon" => lon, "appid" => apiKey, "units" => "metric", "cnt" => 8 },
            { :method => Communications.HTTP_REQUEST_METHOD_GET,
              :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON },
            method(:onForecastResponse)
        );
    }

    // Receives current-conditions JSON from OWM and stores it in Application.Storage
    // using the same format as Segment34View.storeWeatherData().
    function onCurrentResponse(responseCode as Number, data as Dictionary?) as Void {
        //System.println(["OWM onCurrentResponse", responseCode, data]);
        if (responseCode == 401 || responseCode == 403) {
            Application.Storage.setValue("owm_error", "OWM: INVALID API KEY");
            return;
        }
        if (responseCode != 200 || data == null) {
            // Network error or server error — keep cached data, do not touch owm_error.
            return;
        }
        Application.Storage.deleteValue("owm_error");

        var now = Time.now().value();
        var cc_data = {};

        var main = data.get("main") as Dictionary?;
        if (main != null) {
            var temp = main.get("temp");
            if (temp != null) { cc_data["temperature"] = (temp as Float).toNumber(); }
            var feelsLike = main.get("feels_like");
            if (feelsLike != null) { cc_data["feelsLikeTemperature"] = (feelsLike as Float); }
            var humidity = main.get("humidity");
            if (humidity != null) { cc_data["relativeHumidity"] = humidity as Number; }
            // High/low come from forecast aggregation (owm_forecast_high/low), not
            // from the current-conditions endpoint whose temp_max/temp_min only
            // reflect the current 3-hour observation window.
            var fHigh = Application.Storage.getValue("owm_forecast_high");
            var fLow  = Application.Storage.getValue("owm_forecast_low");
            if (fHigh != null) { cc_data["highTemperature"] = fHigh as Number; }
            if (fLow  != null) { cc_data["lowTemperature"]  = fLow  as Number; }
        }

        var wind = data.get("wind") as Dictionary?;
        if (wind != null) {
            var speed = wind.get("speed");
            if (speed != null) { cc_data["windSpeed"] = (speed as Float).toFloat(); }
            var deg = wind.get("deg");
            if (deg != null) { cc_data["windBearing"] = deg as Number; }
            var gust = wind.get("gust");
            if (gust != null) { cc_data["windGust"] = (gust as Float).toFloat(); }
        }

        var rain = data.get("rain") as Dictionary?;
        var snow = data.get("snow") as Dictionary?;
        var precipMmh = 0.0f;
        if (rain != null) {
            var r1h = rain.get("1h");
            if (r1h != null) { precipMmh += (r1h as Float).toFloat(); }
        }
        if (snow != null) {
            var s1h = snow.get("1h");
            if (s1h != null) { precipMmh += (s1h as Float).toFloat(); }
        }
        if (precipMmh > 0.0f) { cc_data["precipitationAmount"] = precipMmh; }

        var weather = data.get("weather") as Array?;
        if (weather != null && weather.size() > 0) {
            var w0 = weather[0] as Dictionary;
            var id = w0.get("id");
            if (id != null) {
                cc_data["condition"] = owmCodeToGarmin(id as Number);
            }
        }

        // Grab UV index from Garmin's live data if available (OWM free tier lacks it).
        var garminCc = Weather.getCurrentConditions();
        if (garminCc != null && garminCc.uvIndex != null) {
            cc_data["uvIndex"] = garminCc.uvIndex;
        }

        var cityName = data.get("name");
        if (cityName != null) { cc_data["cityName"] = cityName as String; }

        cc_data["observationLocationPosition"] = [_lat, _lon];
        var dt = data.get("dt");
        if (dt != null) { cc_data["observationTime"] = dt as Number; }
        cc_data["timestamp"] = now;
        Application.Storage.setValue("current_conditions", cc_data);
        Application.Storage.setValue("owm_last_update", now);
        // Switch to the long interval now that we have data.
        Background.registerForTemporalEvent(new Time.Duration(3600));
    }

    // Receives 3-hour forecast JSON from OWM and stores it in Application.Storage.
    function onForecastResponse(responseCode as Number, data as Dictionary?) as Void {
        //System.println(["OWM onForecastResponse", responseCode, data]);
        if (responseCode != 200 || data == null) { return; }

        var list = data.get("list") as Array?;
        if (list == null || list.size() == 0) { return; }

        var hf_data = [] as Array<Dictionary>;
        for (var i = 0; i < list.size(); i++) {
            var entry = list[i] as Dictionary;
            var tmp = {} as Dictionary;

            var dt = entry.get("dt");
            if (dt != null) { tmp["forecastTime"] = dt as Number; }

            var weather = entry.get("weather") as Array?;
            if (weather != null && weather.size() > 0) {
                var w0 = weather[0] as Dictionary;
                var id = w0.get("id");
                if (id != null) { tmp["condition"] = owmCodeToGarmin(id as Number); }
            }

            var main = entry.get("main") as Dictionary?;
            if (main != null) {
                var temp = main.get("temp");
                if (temp != null) { tmp["temperature"] = (temp as Float).toNumber(); }
            }

            var wind = entry.get("wind") as Dictionary?;
            if (wind != null) {
                var speed = wind.get("speed");
                if (speed != null) { tmp["windSpeed"] = (speed as Float).toFloat(); }
                var deg = wind.get("deg");
                if (deg != null) { tmp["windBearing"] = deg as Number; }
            }

            var pop = entry.get("pop");
            if (pop != null) { tmp["precipitationChance"] = ((pop as Float) * 100).toNumber(); }

            hf_data.add(tmp);
        }

        Application.Storage.setValue("hourly_forecast", hf_data);

        // Aggregate daily high/low across all forecast periods.
        var dailyHigh = null as Number?;
        var dailyLow  = null as Number?;
        for (var i = 0; i < list.size(); i++) {
            var fMain = (list[i] as Dictionary).get("main") as Dictionary?;
            if (fMain != null) {
                var tMax = fMain.get("temp_max");
                var tMin = fMain.get("temp_min");
                if (tMax != null) {
                    var v = (tMax as Float).toNumber();
                    if (dailyHigh == null || v > (dailyHigh as Number)) { dailyHigh = v; }
                }
                if (tMin != null) {
                    var v = (tMin as Float).toNumber();
                    if (dailyLow == null || v < (dailyLow as Number)) { dailyLow = v; }
                }
            }
        }
        if (dailyHigh != null) { Application.Storage.setValue("owm_forecast_high", dailyHigh); }
        if (dailyLow  != null) { Application.Storage.setValue("owm_forecast_low",  dailyLow); }

        // Patch high/low and precipitationChance into current_conditions if it
        // already exists (i.e. onCurrentResponse ran first).
        var firstPop = (hf_data.size() > 0) ? hf_data[0].get("precipitationChance") : null;
        var cc = Application.Storage.getValue("current_conditions") as Dictionary?;
        if (cc != null) {
            if (firstPop  != null) { cc["precipitationChance"] = firstPop; }
            if (dailyHigh != null) { cc["highTemperature"] = dailyHigh as Number; }
            if (dailyLow  != null) { cc["lowTemperature"]  = dailyLow  as Number; }
            Application.Storage.setValue("current_conditions", cc);
        }
    }

    // Maps OWM weather code to Garmin Weather.Condition enum (0–53).
    static function owmCodeToGarmin(owmCode as Number) as Number {
        if (owmCode >= 200 && owmCode < 300) { return 6; }   // Thunderstorm
        if (owmCode >= 300 && owmCode < 400) { return 14; }  // Drizzle → light rain
        if (owmCode == 500) { return 14; }   // Light rain
        if (owmCode == 501) { return 3; }    // Moderate rain
        if (owmCode >= 502 && owmCode <= 504) { return 15; } // Heavy rain
        if (owmCode == 511) { return 32; }   // Freezing rain
        if (owmCode >= 520 && owmCode < 600) { return 11; }  // Shower → scattered showers
        if (owmCode == 600) { return 16; }   // Light snow
        if (owmCode == 601) { return 4; }    // Snow
        if (owmCode == 602) { return 17; }   // Heavy snow
        if (owmCode == 611 || owmCode == 612 || owmCode == 613) { return 33; } // Sleet
        if (owmCode == 615 || owmCode == 616) { return 21; } // Rain and snow
        if (owmCode >= 620 && owmCode < 700) { return 26; }  // Snow showers
        if (owmCode == 711) { return 39; }   // Smoke
        if (owmCode == 721) { return 9; }    // Haze
        if (owmCode == 731 || owmCode == 751 || owmCode == 761) { return 35; } // Dust/sand
        if (owmCode == 771) { return 37; }   // Squall
        if (owmCode == 781) { return 50; }   // Tornado
        if (owmCode >= 700 && owmCode < 800) { return 8; }   // Fog/mist (catch-all)
        if (owmCode == 800) { return 0; }    // Clear
        if (owmCode == 801 || owmCode == 802) { return 1; }  // Partly cloudy
        if (owmCode == 803) { return 2; }    // Mostly cloudy
        if (owmCode == 804) { return 20; }   // Overcast/cloudy
        return 53; // Unknown
    }
}
