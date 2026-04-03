import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

(:background)
class Segment34ServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        System.ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var weatherProvider = Application.Properties.getValue("weatherProvider") as Number;
        if (weatherProvider != 1) { return; }

        var apiKey = Application.Properties.getValue("owmApiKey") as String;
        if (apiKey.length() == 0) { return; }

        var lat = 0.0f;
        var lon = 0.0f;
        var hasLocation = false;

        var locationOverride = Application.Properties.getValue("owmLocationOverride") as String;
        if (locationOverride != null && locationOverride.length() > 0) {
            var commaPos = locationOverride.find(",");
            if (commaPos != null && commaPos > 0) {
                var latStr = locationOverride.substring(0, commaPos);
                var lonStr = locationOverride.substring(commaPos + 1, locationOverride.length());
                if (latStr != null && lonStr != null) {
                    var parsedLat = latStr.toFloat();
                    var parsedLon = lonStr.toFloat();
                    if (parsedLat != null && parsedLon != null) {
                        lat = parsedLat;
                        lon = parsedLon;
                        hasLocation = true;
                    }
                }
            }
        }

        if (!hasLocation) {
            var garminCc = Weather.getCurrentConditions();
            if (garminCc == null || garminCc.observationLocationPosition == null) { return; }
            var deg = garminCc.observationLocationPosition.toDegrees();
            lat = (deg[0] as Decimal).toFloat();
            lon = (deg[1] as Decimal).toFloat();
        }

        var now = Time.now().value();
        var lastUpdate = Application.Storage.getValue("owm_last_update") as Number?;
        if (lastUpdate != null && now - lastUpdate < 7200 && !locationChangedSignificantly(lat, lon)) {
            return;
        }

        var service = new OpenWeatherService();
        service.fetchWeather(lat, lon, apiKey);
    }

    // Returns true if current position is >~55km from the stored weather location.
    hidden function locationChangedSignificantly(lat as Float, lon as Float) as Boolean {
        var stored = Application.Storage.getValue("current_conditions") as Dictionary?;
        if (stored == null) { return false; }
        var pos = stored.get("observationLocationPosition") as Array?;
        if (pos == null) { return false; }
        var latDiff = lat - (pos[0] as Decimal).toFloat();
        var lonDiff = lon - (pos[1] as Decimal).toFloat();
        if (latDiff < 0.0f) { latDiff = -latDiff; }
        if (lonDiff < 0.0f) { lonDiff = -lonDiff; }
        return latDiff > 0.5f || lonDiff > 0.5f;
    }
}
