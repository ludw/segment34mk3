import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.UserProfile;

class ThemeManager {

    var colors as Array<Graphics.ColorType> = [];
    var infoMessage as String = "";

    hidden var _nightMode as Boolean? = null;
    hidden var _propColorOverride as String = "";
    hidden var _propColorOverride2 as String = "";

    function initialize() {}

    function resetNightMode() as Void {
        _nightMode = null;
    }

    function update(
        nightModeOverride as Number,
        propTheme as Number,
        propNightTheme as Number,
        propNightThemeActivation as Number,
        propColorOverride as String,
        propColorOverride2 as String,
        weatherCondition as StoredWeather or Null
    ) as Void {
        _propColorOverride = propColorOverride;
        _propColorOverride2 = propColorOverride2;

        var newNightMode = _getNightModeValue(propNightTheme, propTheme, propNightThemeActivation, weatherCondition);
        if(nightModeOverride == 0) { newNightMode = false; }
        if(nightModeOverride == 1) { newNightMode = true; }

        if(_nightMode != newNightMode) {
            if(newNightMode == true && propNightTheme != -1) {
                colors = _setColorTheme(propNightTheme);
            } else {
                colors = _setColorTheme(propTheme);
            }
            _nightMode = newNightMode;
        }
    }

    (:MIP)
    hidden function _setColorTheme(theme as Number) as Array<Graphics.ColorType> {
        //                        bg,       clock,    clockBg,  outline,  dataVal,  fieldBg,  fieldLbl, date,     dateDim,  notif,    stress,   bodybatt, moon
        if(theme == 0 ) { return [0x000000, 0xFFFF00, 0x005555, 0xFFFF00, 0xFFFFFF, 0x005555, 0x55AAAA, 0xFFFF00, 0xa98753, 0x00AAFF, 0xFFAA00, 0x00AAFF, 0xFFFFFF]; } // Yellow on turquoise MIP
        if(theme == 1 ) { return [0x000000, 0xFF55AA, 0x005555, 0xFF55AA, 0xFFFFFF, 0x005555, 0xAA55AA, 0xFFFFFF, 0xa95399, 0xFF55AA, 0xFF55AA, 0x00FFAA, 0xFFFFFF]; } // Hot pink MIP
        if(theme == 2 ) { return [0x000000, 0x00FFFF, 0x0055AA, 0x00FFFF, 0xFFFFFF, 0x0055AA, 0x55AAAA, 0x00FFFF, 0x5ca28f, 0x00AAFF, 0xFFAA00, 0x00AAFF, 0xFFFFFF]; } // Blueish green MIP
        if(theme == 3 ) { return [0x000000, 0x00FF00, 0x005500, 0x00FF00, 0xFFFFFF, 0x005500, 0x00AA55, 0x00FF00, 0x5ca28f, 0x00AAFF, 0xFFAA00, 0x00AAFF, 0xFFFFFF]; } // Very green MIP
        if(theme == 4 ) { return [0x000000, 0xFFFFFF, 0x005555, 0xFFFFFF, 0xFFFFFF, 0x005555, 0x55AAAA, 0xFFFFFF, 0x114a5a, 0xAAAAAA, 0xFFAA55, 0x55AAFF, 0xFFFFFF]; } // White on turquoise MIP
        if(theme == 5 ) { return [0x000000, 0xFF5500, 0x5500AA, 0xFF5500, 0xFFFFFF, 0x5500AA, 0xFFAAAA, 0xFFAAAA, 0xaa6e56, 0xFFFFFF, 0xFF5555, 0x00AAFF, 0xFFFFFF]; } // Peachy Orange MIP
        if(theme == 6 ) { return [0x000000, 0xFFFFFF, 0xAA0000, 0xFFFFFF, 0xFFFFFF, 0xAA0000, 0xFF0000, 0xFFFFFF, 0xAA0000, 0xFF0000, 0xAA0000, 0x00AAFF, 0xFFFFFF]; } // Red and White MIP
        if(theme == 7 ) { return [0x000000, 0xFFFFFF, 0x0055AA, 0xFFFFFF, 0xFFFFFF, 0x0055AA, 0x0055AA, 0xFFFFFF, 0x0055AA, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // White on Blue MIP
        if(theme == 8 ) { return [0x000000, 0xFFAA00, 0x005555, 0xFFAA00, 0xFFFFFF, 0x005555, 0x55AAAA, 0xFFAA55, 0x555555, 0x55AAAA, 0xFFAA00, 0x55AAAA, 0xFFFFFF]; } // Orange on Teal MIP
        if(theme == 9 ) { return [0x000000, 0xFFFFFF, 0xaa5500, 0xFFFFFF, 0xFFFFFF, 0xaa5500, 0xFF5500, 0xFFFFFF, 0xAA5500, 0x00AAFF, 0xFFAA00, 0x00AAFF, 0xFFFFFF]; } // White and Orange MIP
        if(theme == 10) { return [0x000000, 0x0055AA, 0x000055, 0x0055AA, 0xFFFFFF, 0x555555, 0x0055AA, 0xFFFFFF, 0x0055AA, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // Blue MIP
        if(theme == 11) { return [0x000000, 0xFFAA00, 0x555555, 0xFFAA00, 0xFFFFFF, 0x555555, 0xFFAA00, 0xFFFFFF, 0x555555, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // Orange MIP
        if(theme == 12) { return [0x000000, 0xFFFFFF, 0x555555, 0xFFFFFF, 0xFFFFFF, 0x555555, 0xFFFFFF, 0xFFFFFF, 0x555555, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // White on black MIP
        if(theme == 13) { return [0xFFFFFF, 0x000000, 0xAAAAAA, 0x000000, 0x000000, 0xAAAAAA, 0x000000, 0x000000, 0x555555, 0x000000, 0xFFAA00, 0x55AAFF, 0x555555]; } // Black on White MIP
        if(theme == 14) { return [0xFFFFFF, 0xAA0000, 0xAAAAAA, 0xAA0000, 0x000000, 0xAAAAAA, 0xAA0000, 0x000000, 0x555555, 0x000000, 0xFFAA00, 0x55AAFF, 0x555555]; } // Red on White MIP
        if(theme == 15) { return [0xFFFFFF, 0x0000AA, 0xAAAAAA, 0x0000AA, 0x000000, 0xAAAAAA, 0x0000AA, 0x000000, 0x555555, 0x000000, 0xFFAA00, 0x55AAFF, 0x555555]; } // Blue on White MIP
        if(theme == 16) { return [0xFFFFFF, 0x00AA00, 0xAAAAAA, 0x00AA00, 0x000000, 0xAAAAAA, 0x00AA00, 0x000000, 0x555555, 0x000000, 0xFFAA00, 0x55AAFF, 0x555555]; } // Green on White MIP
        if(theme == 17) { return [0xFFFFFF, 0xFF5500, 0xAAAAAA, 0xFF5500, 0x000000, 0xAAAAAA, 0x555555, 0x000000, 0x555555, 0x000000, 0xFF5500, 0x55AAFF, 0x555555]; } // Orange on White MIP
        if(theme == 18) { return [0x000000, 0xFF5500, 0x005500, 0xFF5500, 0x00FF00, 0x005500, 0xFF5500, 0x00FF00, 0x5ca28f, 0x55FF55, 0xFF5500, 0x00AAFF, 0xFFFFFF]; } // Green and Orange MIP
        if(theme == 19) { return [0x000000, 0xAAAA55, 0x005500, 0xAAAA55, 0x00FF00, 0x005500, 0xAAAA00, 0xAAAA55, 0x546a36, 0x00FF55, 0xAAAA55, 0x00FF00, 0xFFFFFF]; } // Green Camo MIP
        if(theme == 20) { return [0x000000, 0xFF0000, 0x555555, 0xFF0000, 0xFFFFFF, 0x555555, 0xFF0000, 0xFFFFFF, 0x555555, 0x55AAFF, 0xFF5555, 0x55AAFF, 0xFFFFFF]; } // Red on Black MIP
        if(theme == 21) { return [0xFFFFFF, 0xAA00FF, 0xAAAAAA, 0xAA00FF, 0x000000, 0xAAAAAA, 0xAA00FF, 0x000000, 0x555555, 0x000000, 0xFF5500, 0x55AAFF, 0x555555]; } // Purple on White MIP
        if(theme == 22) { return [0x000000, 0xAA00FF, 0x555555, 0xAA00FF, 0xFFFFFF, 0x555555, 0xAA00FF, 0xFFFFFF, 0x555555, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // Purple on black MIP
        if(theme == 23) { return [0x000000, 0xFFAA00, 0x555555, 0xFFAA00, 0xFFAA55, 0x555555, 0xFFAA00, 0xFFAA55, 0x555555, 0x55AAAA, 0xFFAA00, 0x55AAAA, 0xFFFFFF]; } // Amber MIP
        if(theme == 30) { return _parseThemeString(_propColorOverride); }
        if(theme == 31) { return _parseThemeString(_propColorOverride2); }
        infoMessage = "THEME ERROR";
        return [0xff0000, 0x00ff00, 0x0000ff, 0x550000, 0x005500, 0x000055, 0xff00ff, 0x00ffff, 0xffff00, 0x005555, 0x550055, 0x555500, 0xffffff]; // error case
    }

    (:AMOLED)
    hidden function _setColorTheme(theme as Number) as Array<Graphics.ColorType> {
        //                        bg,       clock,    clockBg,  outline,  dataVal,  fieldBg,  fieldLbl,   date,   dateDim,  notif,   stress,    bodybatt, moon
        if(theme == 0 ) { return [0x000000, 0xFBCB77, 0x0f2d34, 0xFFEAC4, 0xd5ffff, 0x0D333C, 0x61c6c6, 0xfacf83, 0xa89252, 0x00AAFF, 0xFFAA00, 0x00AAFF, 0xFFFFFF]; } // Yellow on turquoise AMOLED
        if(theme == 1 ) { return [0x000000, 0xff85c2, 0x0F3B46, 0xFFD9FC, 0xffe6f2, 0x0E333C, 0xff85c2, 0xffe6f2, 0xbf7498, 0xFF55AA, 0xFF55AA, 0x4cb2db, 0xFFFFFF]; } // Hot pink AMOLED
        if(theme == 2 ) { return [0x000000, 0x89EFD2, 0x0F2246, 0xB8EFDF, 0xdffff6, 0x0F2246, 0x69cece, 0x98efd6, 0x5CA28F, 0x00AAFF, 0xffcf98, 0x74d0fd, 0xFFFFFF]; } // Blueish green AMOLED
        if(theme == 3 ) { return [0x000000, 0x96E0AC, 0x292929, 0xC3E0CC, 0xe7ffee, 0x292929, 0x7bffbd, 0x96E0AC, 0x5CA28F, 0x00AAFF, 0xFFC884, 0x59B9FE, 0xFFFFFF]; } // Very green AMOLED
        if(theme == 4 ) { return [0x000000, 0xFFFFFF, 0x0d333c, 0xadeffe, 0xFFFFFF, 0x0e333c, 0x55AAAA, 0xFFFFFF, 0x1d7e99, 0xAAAAAA, 0xFFAA55, 0x55AAFF, 0xFFFFFF]; } // White on turquoise AMOLED
        if(theme == 5 ) { return [0x000000, 0xFF9161, 0x172135, 0xFFB494, 0xffeadd, 0x1B263D, 0xffc6a3, 0xFFB383, 0xAA6E56, 0xFFFFFF, 0xff7550, 0x00AAFF, 0xFFFFFF]; } // Peachy Orange AMOLED
        if(theme == 6 ) { return [0x000000, 0xffffff, 0x550000, 0xc00003, 0xFFFFFF, 0x550000, 0xFF0000, 0xffffff, 0xAA0000, 0xFF0000, 0xAA0000, 0x00AAFF, 0xFFFFFF]; } // Red and White AMOLED
        if(theme == 7 ) { return [0x000000, 0xffffff, 0x14264b, 0xaecaff, 0xFFFFFF, 0x152a53, 0x1d81e6, 0xffffff, 0x0055AA, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // White on Blue AMOLED
        if(theme == 8 ) { return [0x000000, 0xff960c, 0x0f2d34, 0xffbf65, 0xd5ffff, 0x0D333C, 0x61c6c6, 0xffb759, 0x9a784d, 0xa8d6fd, 0xfdb500, 0xa8d6fd, 0xe3efd2]; } // Orange on Teal AMOLED
        if(theme == 9 ) { return [0x000000, 0xffffff, 0x572d07, 0xffd6ae, 0xFFFFFF, 0x58250b, 0xf76821, 0xffffff, 0xAA5500, 0x00AAFF, 0xFFAA00, 0x00AAFF, 0xFFFFFF]; } // White and Orange AMOLED
        if(theme == 10) { return [0x000000, 0x0855ff, 0x152445, 0x4580ff, 0xb0c9ff, 0x152445, 0x4b84ff, 0x8aafff, 0x3159af, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // Blue AMOLED
        if(theme == 11) { return [0x000000, 0xff7600, 0x333333, 0xff9133, 0xFFFFFF, 0x333333, 0xFFAA00, 0xffffff, 0x9a9a9a, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // Orange AMOLED
        if(theme == 12) { return [0x000000, 0xFFFFFF, 0x333333, 0xcbcbcb, 0xFFFFFF, 0x333333, 0xFFFFFF, 0xFFFFFF, 0x9a9a9a, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // White on black AMOLED
        if(theme == 13) { return [0xFFFFFF, 0x000000, 0xCCCCCC, 0x666666, 0x000000, 0xCCCCCC, 0x000000, 0x000000, 0x9a9a9a, 0x000000, 0xFFAA00, 0x55AAFF, 0x555555]; } // Black on White AMOLED
        if(theme == 14) { return [0xFFFFFF, 0xAA0000, 0xCCCCCC, 0xaa2325, 0x000000, 0xCCCCCC, 0xAA0000, 0x000000, 0x9a9a9a, 0x000000, 0xFFAA00, 0x55AAFF, 0x555555]; } // Red on White AMOLED
        if(theme == 15) { return [0xFFFFFF, 0x0050ff, 0xCCCCCC, 0x2222aa, 0x000000, 0xCCCCCC, 0x0000AA, 0x000000, 0x9a9a9a, 0x000000, 0xFFAA00, 0x55AAFF, 0x555555]; } // Blue on White AMOLED
        if(theme == 16) { return [0xFFFFFF, 0x00AA00, 0xCCCCCC, 0x22aa22, 0x000000, 0xCCCCCC, 0x00AA00, 0x000000, 0x9a9a9a, 0x000000, 0xFFAA00, 0x55AAFF, 0x555555]; } // Green on White AMOLED
        if(theme == 17) { return [0xFFFFFF, 0xFF5500, 0xCCCCCC, 0xff7632, 0x000000, 0xCCCCCC, 0x555555, 0x000000, 0x9a9a9a, 0x000000, 0xFF5500, 0x55AAFF, 0x555555]; } // Orange on White AMOLED
        if(theme == 18) { return [0x000000, 0xff7700, 0x102714, 0xE64322, 0x47b047, 0x17291a, 0xff7733, 0x60d060, 0x5F9956, 0x5eff5e, 0xFF7600, 0x59B9FE, 0xFFFFFF]; } // Green and Orange AMOLED
        if(theme == 19) { return [0x000000, 0x8c9f58, 0x152B19, 0x919F6B, 0x67ab55, 0x152B19, 0xb5b872, 0x889F4A, 0x7A9A4E, 0x00FF55, 0x889F4A, 0x55AA55, 0xE3EFD2]; } // Green Camo AMOLED
        if(theme == 20) { return [0x000000, 0xFF0000, 0x282828, 0xff3236, 0xFFFFFF, 0x282828, 0xff4646, 0xFFFFFF, 0x9a9a9a, 0x55AAFF, 0xFF5555, 0x55AAFF, 0xFFFFFF]; } // Red on Black AMOLED
        if(theme == 21) { return [0xFFFFFF, 0xAA00FF, 0xCCCCCC, 0xbb34ff, 0x000000, 0xCCCCCC, 0xAA00FF, 0x000000, 0x9a9a9a, 0x000000, 0xFF5500, 0x55AAFF, 0x555555]; } // Purple on White AMOLED
        if(theme == 22) { return [0x000000, 0xAA55AA, 0x212121, 0xAA77AA, 0xffd8ff, 0x282828, 0xde79de, 0xf1b2f1, 0x9A9A9A, 0x55AAFF, 0xFFAA00, 0x55AAFF, 0xFFFFFF]; } // Purple on black AMOLED
        if(theme == 23) { return [0x000000, 0xff960c, 0x302b24, 0xffbf65, 0xffdeb4, 0x302b24, 0xffac3f, 0xffb759, 0x9a784d, 0xa8d6fd, 0xfdb500, 0xa8d6fd, 0xe3efd2]; } // Amber AMOLED
        if(theme == 30) { return _parseThemeString(_propColorOverride); }
        if(theme == 31) { return _parseThemeString(_propColorOverride2); }
        infoMessage = "THEME ERROR";
        return [0xff0000, 0x00ff00, 0x0000ff, 0xff00ff, 0x00ffff, 0xffff00, 0x550000, 0x005500, 0x000055, 0x005555, 0x550055, 0x555500, 0xffffff];
    }

    hidden function _parseThemeString(override as String) as Array<Graphics.ColorType> {
        if(override == null or override.length() < 103) { return _setColorTheme(-1); }
        var ret = [] as Array<Graphics.ColorType>;
        for(var i=0; i + 7 <= override.length(); i += 8) {
            var color_str = override.substring(i+1, i+7);
            if(color_str == null) { return _setColorTheme(-1); }
            var color = color_str.toNumberWithBase(16);
            if(color == null or color < 0 or color > 16777215) {
                return _setColorTheme(-1);
            }
            ret.add(color as Graphics.ColorType);
        }

        if(ret.size() != 13) {
            return _setColorTheme(-1);
        }

        return ret;
    }

    hidden function _getNightModeValue(
        propNightTheme as Number,
        propTheme as Number,
        propNightThemeActivation as Number,
        weatherCondition as StoredWeather or Null
    ) as Boolean {
        if (propNightTheme == -1 || propNightTheme == propTheme) {
            return false;
        }

        var now = Time.now(); // Moment
        var todayMidnight = Time.today(); // Moment
        var nowAsTimeSinceMidnight = now.subtract(todayMidnight) as Duration; // Duration

        if(propNightThemeActivation == 0 or propNightThemeActivation == 1) {
            var profile = UserProfile.getProfile();
            var wakeTime = profile.wakeTime;
            var sleepTime = profile.sleepTime;

            if (wakeTime == null || sleepTime == null) {
                return false;
            }

            if(propNightThemeActivation == 1) {
                // Start two hours before sleep time
                sleepTime = new Time.Duration((sleepTime.value() - 7200 + 86400) % 86400);
            }

            if(sleepTime.greaterThan(wakeTime)) {
                return (nowAsTimeSinceMidnight.greaterThan(sleepTime) || nowAsTimeSinceMidnight.lessThan(wakeTime));
            } else {
                return (nowAsTimeSinceMidnight.greaterThan(sleepTime) and nowAsTimeSinceMidnight.lessThan(wakeTime));
            }
        }

        // From Sunset to Sunrise
        if(weatherCondition != null) {
            var nextSunEventArray = getNextSunEvent(weatherCondition);
            if(nextSunEventArray != null && nextSunEventArray.size() == 2) {
                return nextSunEventArray[1] as Boolean;
            }
        }

        return false;
    }

}
