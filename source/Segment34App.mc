import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class Segment34App extends Application.AppBase {
    
    var mView;
    
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        updateTemporalEvent();
    }

    function getServiceDelegate() {
        return [new Segment34ServiceDelegate()];
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    (:background_excluded)
    function getInitialView() {
        mView = new Segment34View();
        var delegate = new Segment34Delegate(mView);
        return [mView, delegate];
    }

    function onSettingsChanged() as Void {
        // Reset weather service state so the next temporal event fetches immediately.
        Application.Storage.deleteValue("wx_last_update");
        Application.Storage.deleteValue("wx_error");
        Application.Storage.deleteValue("owm_forecast_high");
        Application.Storage.deleteValue("owm_forecast_low");
        Application.Storage.deleteValue("rain_forecast");
        updateTemporalEvent();
        mView.onSettingsChanged();
        WatchUi.requestUpdate();
    }

    hidden function updateTemporalEvent() as Void {
        var provider = (Application.Properties.getValue("weatherProvider") as Number);
        if (provider == 1 || provider == 2) {
            var interval = Application.Properties.getValue("owmRefreshInterval") as Number;
            var hasData = Application.Storage.getValue("wx_last_update") != null;
            Background.registerForTemporalEvent(new Time.Duration(hasData ? interval : 300));
        } else {
            Background.deleteTemporalEvent();
        }
    }

}

function getApp() as Segment34App {
    return Application.getApp() as Segment34App;
}