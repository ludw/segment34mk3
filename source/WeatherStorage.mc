import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;
using Toybox.Position;

(:background_excluded)
class WeatherStorage {

    var isLowMem as Boolean = false;
    hidden var _lastHfTime as Number? = null;
    hidden var _lastCcHash as Number? = null;

    function initialize() {}

    function store() as Void {
        var now = Time.now().value();
        var sysStats = System.getSystemStats();

        if (!isLowMem && sysStats.freeMemory < 15000) {
            isLowMem = true;
            Application.Storage.setValue("hourly_forecast", []);
            _lastHfTime = null;
        } else if (isLowMem && sysStats.freeMemory > 17000) {
            isLowMem = false;
        }

        var cc = Weather.getCurrentConditions();
        var newCcHash = _ccHash(cc);

        if (_lastCcHash == null || _lastCcHash != newCcHash) {
            var cc_data = {};
            if(cc != null) {
                if(cc.observationLocationPosition != null) {
                    cc_data["observationLocationPosition"] = cc.observationLocationPosition.toDegrees();
                }
                if(cc.condition != null) { cc_data["condition"] = cc.condition; }
                if(cc.highTemperature != null) { cc_data["highTemperature"] = cc.highTemperature; }
                if(cc.lowTemperature != null) { cc_data["lowTemperature"] = cc.lowTemperature; }
                if(cc.precipitationChance != null) { cc_data["precipitationChance"] = cc.precipitationChance; }
                if(cc.relativeHumidity != null) { cc_data["relativeHumidity"] = cc.relativeHumidity; }
                if(cc.temperature != null) { cc_data["temperature"] = cc.temperature; }
                if(cc.feelsLikeTemperature != null) { cc_data["feelsLikeTemperature"] = cc.feelsLikeTemperature; }
                if(cc.windBearing != null) { cc_data["windBearing"] = cc.windBearing; }
                if(cc.windSpeed != null) { cc_data["windSpeed"] = cc.windSpeed; }
                if(cc.uvIndex != null) { cc_data["uvIndex"] = cc.uvIndex; }
                if(cc.observationTime != null) { cc_data["observationTime"] = cc.observationTime.value(); }
            }

            cc_data["timestamp"] = now;
            Application.Storage.setValue("current_conditions", cc_data);

            _lastCcHash = newCcHash;
        }

        if (isLowMem) { return; }

        var hf = Weather.getHourlyForecast();

        if (hf == null || hf.size() == 0) { return; }

        var firstForecastTime = hf[0].forecastTime.value();

        if (_lastHfTime == null || _lastHfTime != firstForecastTime) {
            var hf_data = [];

            for(var i=0; i<hf.size(); i++) {
                var tmp = {
                    "forecastTime" => hf[i].forecastTime.value(),
                    "condition" => hf[i].condition,
                    "precipitationChance" => hf[i].precipitationChance,
                    "temperature" => hf[i].temperature,
                    "windBearing" => hf[i].windBearing,
                    "windSpeed" => hf[i].windSpeed
                };
                if(hf[i].uvIndex != null) { tmp["uvIndex"] = hf[i].uvIndex; }

                hf_data.add(tmp);
            }

            Application.Storage.setValue("hourly_forecast", hf_data);
            _lastHfTime = firstForecastTime;
        }
    }

    function read() as StoredWeather {
        var ret = new StoredWeather();
        var now = Time.now().value();
        var cc_data = Application.Storage.getValue("current_conditions") as Dictionary<String, Application.PropertyValueType>?;
        if(cc_data == null) { return ret; }

        var data_age_s = now - (cc_data.get("timestamp") as Number);
        var pos = cc_data.get("observationLocationPosition") as Array?;
        if (pos != null) {
            ret.observationLocationPosition = new Position.Location({:latitude => pos[0], :longitude => pos[1], :format => :degrees});
        }
        var hf_data = Application.Storage.getValue("hourly_forecast") as Array?;

        // Find the nearest forecast entry by absolute time distance (past or future).
        // Used to supplement fields missing from current conditions (e.g. windGust,
        // precipitationAmount which OWM only reports "where available" in current obs).
        var nearestEntry = null as Dictionary?;
        if (hf_data != null) {
            var nearestDist = 2147483647;
            for (var i = 0; i < hf_data.size(); i++) {
                var diff = now - (hf_data[i].get("forecastTime") as Number);
                if (diff < 0) { diff = -diff; }
                if (diff < nearestDist) { nearestDist = diff; nearestEntry = hf_data[i]; }
            }
        }

        // Current conditions are valid for at least 1 hour (Garmin path), or until the
        // first forecast slot starts — whichever is later. For OWM the first slot is always
        // in the future (~3h boundary), so this covers the gap without regressing Garmin.
        var ccTimestamp = cc_data.get("timestamp") as Number;
        var ccValidUntil = ccTimestamp + 3600;
        if (hf_data != null && hf_data.size() > 0) {
            var firstForecastTime = hf_data[0].get("forecastTime") as Number;
            if (firstForecastTime > ccValidUntil) { ccValidUntil = firstForecastTime; }
        }
        if(data_age_s >= 0 and now < ccValidUntil) {
            ret.condition = cc_data.get("condition") as Number;
            ret.highTemperature = cc_data.get("highTemperature") as Number;
            ret.lowTemperature = cc_data.get("lowTemperature") as Number;
            ret.precipitationChance = cc_data.get("precipitationChance") as Number;
            ret.relativeHumidity = cc_data.get("relativeHumidity") as Number;
            ret.temperature = cc_data.get("temperature") as Number;
            ret.feelsLikeTemperature = cc_data.get("feelsLikeTemperature") as Float;
            ret.windBearing = cc_data.get("windBearing") as Number;
            ret.windSpeed = cc_data.get("windSpeed") as Float;
            ret.windGust = cc_data.get("windGust") as Float;
            ret.precipitationAmount = cc_data.get("precipitationAmount") as Float;
            ret.uvIndex = cc_data.get("uvIndex") as Float;
            ret.cityName = cc_data.get("cityName") as String?;
            var obsTime = cc_data.get("observationTime");
            if (obsTime == null) { obsTime = cc_data.get("timestamp"); }
            ret.observationTimestamp = obsTime as Number;
            // OWM only includes windGust and precipitationAmount "where available" in
            // current conditions. Fill gaps from the nearest forecast entry.
            if (ret.windGust == null && nearestEntry != null) {
                ret.windGust = nearestEntry.get("windGust") as Float;
            }
            if (ret.precipitationAmount == null && nearestEntry != null) {
                ret.precipitationAmount = nearestEntry.get("precipitationAmount") as Float;
            }
        } else {
            if(hf_data == null) { return ret; }
            // Find the most recently passed slot. When now >= firstForecastTime there is
            // always at least one past entry, so no nearest-future fallback is needed.
            var bestEntry = null;
            var bestAge = 86401;
            for(var i=0; i<hf_data.size(); i++) {
                var forecast_age = now - (hf_data[i].get("forecastTime") as Number);
                if(forecast_age >= 0 and forecast_age < bestAge) {
                    bestAge = forecast_age;
                    bestEntry = hf_data[i];
                }
            }
            if(bestEntry != null) {
                ret.condition = bestEntry.get("condition") as Number;
                ret.temperature = bestEntry.get("temperature") as Number;
                ret.precipitationChance = bestEntry.get("precipitationChance") as Number;
                ret.windBearing = bestEntry.get("windBearing") as Number;
                ret.windSpeed = bestEntry.get("windSpeed") as Float;
                ret.windGust = bestEntry.get("windGust") as Float;
                ret.precipitationAmount = bestEntry.get("precipitationAmount") as Float;
                // Forecast entries lack feelsLike/humidity/high/low — use last known values.
                ret.feelsLikeTemperature = cc_data.get("feelsLikeTemperature") as Float;
                ret.relativeHumidity = cc_data.get("relativeHumidity") as Number;
                ret.highTemperature = cc_data.get("highTemperature") as Number;
                ret.lowTemperature = cc_data.get("lowTemperature") as Number;
                ret.uvIndex = cc_data.get("uvIndex") as Float;
                var obsTime2 = cc_data.get("observationTime");
                if (obsTime2 == null) { obsTime2 = cc_data.get("timestamp"); }
                ret.observationTimestamp = obsTime2 as Number;
            }
        }

        return ret;
    }

    hidden function _ccHash(cc) as Number {
        if (cc == null) { return 0; }
        var h = 17;
        var t = (cc.temperature != null) ? cc.temperature : -127;
        h = 31 * h + t;
        var c = (cc.condition != null) ? cc.condition : -1;
        h = 31 * h + c;
        var w = (cc.windSpeed != null) ? cc.windSpeed.toNumber() : -1;
        h = 31 * h + w;
        var b = (cc.windBearing != null) ? cc.windBearing : -1;
        h = 31 * h + b;

        return h;
    }
}
