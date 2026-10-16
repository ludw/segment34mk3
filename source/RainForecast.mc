import Toybox.Application;
import Toybox.Lang;

(:background)
class RainForecast {
    static const THRESHOLD = 50;

    hidden var _startWet as Boolean? = null;
    hidden var _lastT as Number = 0;
    hidden var _result as Array? = null;

    function initialize() {}

    // feed(t, pop) -> true when the answer is decided (caller should break)
    function feed(t as Number, pop as Number) as Boolean {
        if (_result != null) { return true; }
        if (_startWet == null) {
            _startWet = (pop >= THRESHOLD);
            _lastT = t;
            return false;
        }
        if (t <= _lastT) { return false; }
        _lastT = t;
        var wet = (pop >= THRESHOLD);
        if (wet != (_startWet as Boolean)) {
            _result = [wet ? 0 : 1, t, pop];
            return true;
        }
        return false;
    }

    // [kind, at, chance]; kind 2/3 if never decided
    function result() as Array? {
        if (_result != null) { return _result; }
        if (_startWet == null) { return null; }
        return [(_startWet as Boolean) ? 3 : 2, _lastT, 0];
    }

    static function isEnabled() as Boolean {
        var f1 = Application.Properties.getValue("weatherFormat1") as String?;
        if (f1 != null && f1.find("x") != null) { return true; }
        var f2 = Application.Properties.getValue("weatherFormat2") as String?;
        return (f2 != null && f2.find("x") != null);
    }
}
