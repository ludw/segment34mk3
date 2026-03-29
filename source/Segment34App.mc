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
        // Reset OWM state so the next temporal event fetches immediately with the new settings.
        Application.Storage.deleteValue("owm_last_update");
        Application.Storage.deleteValue("owm_error");
        updateTemporalEvent();
        mView.onSettingsChanged();
        WatchUi.requestUpdate();
    }

    hidden function updateTemporalEvent() as Void {
        if ((Application.Properties.getValue("weatherProvider") as Number) == 1) {
            // If no data yet, request a wake as soon as the OS allows.
            var hasData = Application.Storage.getValue("owm_last_update") != null;
            Background.registerForTemporalEvent(new Time.Duration(hasData ? 3600 : 300));
        } else {
            Background.deleteTemporalEvent();
        }
    }

}

function getApp() as Segment34App {
    return Application.getApp() as Segment34App;
}