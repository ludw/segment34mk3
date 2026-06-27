// Graph data fetching and rendering

import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.Time;
import Toybox.UserProfile;
import Toybox.WatchUi;

class GraphRenderer {

    // Mini graph field codes: 100–110 map to graph data sources 0–10.
    // Used by bottomFieldShows / bottomField2Shows to select a graph instead of a data value.
    static function isGraphCode(code as Number) as Boolean {
        return code >= 100 and code <= 110;
    }

    static function graphCodeToDataSource(code as Number) as Number {
        return code - 100;
    }

    // Layout params (set via configure())
    hidden var _barWidth as Number = 2;
    hidden var _barSpacing as Number = 2;
    hidden var _targetWidth as Number = 40;
    hidden var _halfWidth as Number = 0;
    hidden var _halfMarginY as Number = 0;
    hidden var _fontLabel as WatchUi.FontResource?;
    hidden var _labelHeight as Number = 8;

    // Props (set via configure())
    hidden var _propGraphData as Number = 0;
    hidden var _propGraphStyle as Number = 0;
    hidden var _propGraphXAxisLabels as Boolean = false;
    hidden var _propGraphYAxisLabels as Boolean = false;
    hidden var _xLabelYOffset as Number = 0;
    hidden var _propIs24H as Boolean = false;
    hidden var _propIsMetricDistance as Boolean = true;

    // State — written by getDataArrayByType, read by draw functions
    var graphGoalLine as Number? = null;
    var cachedGraphYMin as Float = 0.0;
    var cachedGraphYMax as Float = 100.0;
    var cachedGraphData2 as Array<Number>? = null;

    // X-axis label cache: recomputed once per minute, not every frame
    hidden var _cachedXLabelEpochMin as Number = -1;
    hidden var _cachedXLabelLeft as String = "";
    hidden var _cachedXLabelRight as String = "";

    // Data cache: avoids expensive SensorHistory iteration on sub-minute updates.
    // Shared by top graph and mini graph — each GraphRenderer instance caches independently.
    hidden var _cachedData as Array<Number>? = null;
    hidden var _cachedDataSource as Number = -1;
    hidden var _cachedMinute as Number = -1;

    function initialize() {}

    // Returns cached graph data, re-fetching only when the minute changes or the data source changes.
    // SensorHistory updates at most once per minute, so more frequent reads are wasted CPU.
    function getCachedDataArray(dataSource as Number, currentMinute as Number) as Array<Number>? {
        if(_cachedData == null or currentMinute != _cachedMinute or dataSource != _cachedDataSource) {
            _cachedData = getDataArrayByType(dataSource);
            _cachedDataSource = dataSource;
            _cachedMinute = currentMinute;
        }
        return _cachedData;
    }

    function clearCache() as Void {
        _cachedData = null;
    }

    function configure(
        barWidth as Number,
        barSpacing as Number,
        targetWidth as Number,
        halfWidth as Number,
        halfMarginY as Number,
        fontLabel as WatchUi.FontResource?,
        labelHeight as Number,
        propGraphData as Number,
        propGraphStyle as Number,
        propGraphXAxisLabels as Boolean,
        propGraphYAxisLabels as Boolean,
        xLabelYOffset as Number,
        propIs24H as Boolean,
        propIsMetricDistance as Boolean
    ) as Void {
        _barWidth = barWidth;
        _barSpacing = barSpacing;
        _targetWidth = targetWidth;
        _halfWidth = halfWidth;
        _halfMarginY = halfMarginY;
        _fontLabel = fontLabel;
        _labelHeight = labelHeight;
        _propGraphData = propGraphData;
        _propGraphStyle = propGraphStyle;
        _propGraphXAxisLabels = propGraphXAxisLabels;
        _propGraphYAxisLabels = propGraphYAxisLabels;
        _xLabelYOffset = xLabelYOffset;
        _propIs24H = propIs24H;
        _propIsMetricDistance = propIsMetricDistance;
    }

    function drawGraph(dc as Graphics.Dc, data as Array<Number>?, data2 as Array<Number>?, x as Number, y as Number, h as Number, themeColors as Array<Graphics.ColorType>) as Void {
        if(data == null || data.size() == 0) { return; }
        var scale = 100.0 / h;
        var bw = _barWidth;
        var bs = _barSpacing;

        if(_propGraphYAxisLabels) { y = y + _halfMarginY; }

        if(_propGraphData >= 8) {
            // Daily data mode: bar widths fill the device's graph area
            var n = data.size();
            bs = 6;
            bw = Math.round((_halfWidth.toFloat() * 2 - bs.toFloat() * (n - 1)) / n).toNumber();
            if(bw < 4) { bw = 4; }
        }
        var half_width = Math.round((data.size() * (bw + bs)) / 2);

        // Shift right when Y-axis labels are shown, to create space for Y-axis labels on the left
        var xShift = _propGraphYAxisLabels ? 10 : 0;

        if(_propGraphStyle > 0) {
            // Line graph: fixed total width regardless of data point count
            half_width = _halfWidth;
            drawLineGraph(dc, data, x + xShift, y, h, half_width, scale, themeColors);
        } else {
            drawBarGraph(dc, data, data2, x + xShift, y, h, half_width, bw, bs, scale, themeColors);
        }
    }

    hidden function drawBarGraph(dc as Graphics.Dc, data as Array<Number>, data2 as Array<Number>?, x as Number, y as Number, h as Number, half_width as Number, bw as Number, bs as Number, scale as Float, themeColors as Array<Graphics.ColorType>) as Void {
        var graphLeft = x - half_width;
        var graphRight = x + half_width;

        if(_propGraphXAxisLabels || _propGraphYAxisLabels) {
            dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(graphLeft, y + h, graphRight, y + h);   // X axis
            dc.drawLine(graphLeft, y, graphLeft, y + h);         // Y axis
        }

        if(_propGraphYAxisLabels) {
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
            var maxStr = formatGraphAxisValue(cachedGraphYMax);
            dc.drawText(graphLeft - 2, y - 3, _fontLabel, maxStr, Graphics.TEXT_JUSTIFY_RIGHT);
            var minStr = formatGraphAxisValue(cachedGraphYMin);
            dc.drawText(graphLeft - 2, y - 3 + h - _labelHeight, _fontLabel, minStr, Graphics.TEXT_JUSTIFY_RIGHT);
        }

        if(_propGraphXAxisLabels) {
            var leftLabel = getGraphXLabel(true);
            var rightLabel = getGraphXLabel(false);
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
            dc.drawText(graphLeft, y + h + _xLabelYOffset, _fontLabel, leftLabel, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(graphRight, y + h + _xLabelYOffset, _fontLabel, rightLabel, Graphics.TEXT_JUSTIFY_RIGHT);
        }

        if(graphGoalLine != null) {
            var goal_y = y + (h - Math.round(graphGoalLine / scale));
            dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
            dc.drawLine(graphLeft, goal_y, graphRight, goal_y);
        }

        dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
        for(var i = 0; i < data.size(); i++) {
            if(data[i] == -1) { continue; } // gap (e.g. stress not measurable)
            if(_propGraphData == 7) {
                dc.setColor(getStressColor(data[i]), Graphics.COLOR_TRANSPARENT);
            }
            var bar_x = graphLeft + i * (bw + bs);
            if(_propGraphData >= 8 && data[i] == 0) {
                // Zero value: draw a 1px stub
                dc.setColor(themeColors[dateDim], Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(bar_x, y + h - 1, bw, 1);
                dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
                continue;
            }
            var bar_height = Math.round(data[i] / scale);
            if(data2 != null && i < data2.size() && data2[i] > 0) {
                // Stacked bar: bottom = moderate (date color), top = vigorous (clock color)
                var vigorous_height = Math.round(data2[i] / scale);
                if(vigorous_height > bar_height) { vigorous_height = bar_height; }
                var moderate_height = bar_height - vigorous_height;
                if(moderate_height > 0) {
                    dc.setColor(themeColors[date], Graphics.COLOR_TRANSPARENT);
                    dc.fillRectangle(bar_x, y + h - bar_height, bw, moderate_height);
                }
                dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(bar_x, y + h - vigorous_height, bw, vigorous_height);
            } else {
                dc.fillRectangle(bar_x, y + (h - bar_height), bw, bar_height);
            }
        }
    }

    hidden function drawLineGraph(dc as Graphics.Dc, data as Array<Number>, x as Number, y as Number, h as Number, half_width as Number, scale as Float, themeColors as Array<Graphics.ColorType>) as Void {
        var n = data.size();
        var graphLeft = x - half_width;
        var graphRight = x + half_width;
        var totalW = graphRight - graphLeft;

        // Draw axes only if at least one axis label is enabled
        if(_propGraphXAxisLabels || _propGraphYAxisLabels) {
            dc.setColor(themeColors[fieldLbl], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(graphLeft, y + h, graphRight, y + h);   // X axis
            dc.drawLine(graphLeft, y, graphLeft, y + h);         // Y axis
        }

        // Draw axis labels if enabled
        if(_propGraphYAxisLabels) {
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
            var maxStr = formatGraphAxisValue(cachedGraphYMax);
            var minStr = formatGraphAxisValue(cachedGraphYMin);
            dc.drawText(graphLeft - 2, y - 3, _fontLabel, maxStr, Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(graphLeft - 2, y - 3 + h - _labelHeight, _fontLabel, minStr, Graphics.TEXT_JUSTIFY_RIGHT);
        }

        if(_propGraphXAxisLabels) {
            var leftLabel = getGraphXLabel(true);
            var rightLabel = getGraphXLabel(false);
            dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
            dc.drawText(graphLeft, y + h + _xLabelYOffset, _fontLabel, leftLabel, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawText(graphRight, y + h + _xLabelYOffset, _fontLabel, rightLabel, Graphics.TEXT_JUSTIFY_RIGHT);
        }

        // Draw line and optional dots
        dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
        var prevX = -1;
        var prevY = -1;
        for(var i = 0; i < n; i++) {
            if(data[i] < 0) { prevX = -1; prevY = -1; continue; } // gap
            var ptX = n > 1 ? graphLeft + Math.round(i.toFloat() * totalW / (n - 1)) : x;
            var ptY = y + h - 1 - Math.round(data[i] / scale);
            if(ptY < y) { ptY = y; }

            if(prevX >= 0) {
                dc.drawLine(prevX, prevY, ptX, ptY);
            }
            if(_propGraphStyle == 2) {
                if(_propGraphData == 7) {
                    dc.setColor(getStressColor(data[i]), Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(themeColors[dataVal], Graphics.COLOR_TRANSPARENT);
                }
                dc.fillRectangle(ptX - 1, ptY - 1, 3, 3);
                dc.setColor(themeColors[clock], Graphics.COLOR_TRANSPARENT);
            }
            prevX = ptX;
            prevY = ptY;
        }
    }

    // Returns the X-axis label for the leftmost (isLeft=true) or rightmost point.
    // For 2-hour data: formatted time; for 7-day data: abbreviated weekday.
    // Labels are cached per epoch-minute so Gregorian.info is only called once/minute.
    function getGraphXLabel(isLeft as Boolean) as String {
        refreshXLabels();
        return isLeft ? _cachedXLabelLeft : _cachedXLabelRight;
    }

    hidden function refreshXLabels() as Void {
        var nowMoment = Time.now();
        var epochMin = nowMoment.value() / 60;
        if (epochMin == _cachedXLabelEpochMin) { return; }
        _cachedXLabelEpochMin = epochMin;
        if (_propGraphData >= 8) {
            var infoNow = Time.Gregorian.info(nowMoment, Time.FORMAT_SHORT);
            var target6 = nowMoment.subtract(new Time.Duration(6 * 86400));
            var info6 = Time.Gregorian.info(target6, Time.FORMAT_SHORT);
            _cachedXLabelLeft = dayName(info6.day_of_week);
            _cachedXLabelRight = dayName(infoNow.day_of_week);
        } else {
            var target2h = nowMoment.subtract(new Time.Duration(7200));
            var infoNow = Time.Gregorian.info(nowMoment, Time.FORMAT_SHORT);
            var info2h = Time.Gregorian.info(target2h, Time.FORMAT_SHORT);
            _cachedXLabelLeft = formatXLabel(info2h.hour, info2h.min);
            _cachedXLabelRight = formatXLabel(infoNow.hour, infoNow.min);
        }
    }

    hidden function formatXLabel(h as Number, m as Number) as String {
        if (!_propIs24H) {
            var ampm = h >= 12 ? "P" : "A";
            h = h % 12;
            if (h == 0) { h = 12; }
            return h.toString() + ":" + m.format("%02d") + ampm;
        }
        return h.format("%02d") + ":" + m.format("%02d");
    }

    function getDataArrayByType(dataSource as Number) as Array<Number> {
        graphGoalLine = null;
        cachedGraphData2 = null;

        if(dataSource == 8 or dataSource == 9 or dataSource == 10) {
            return getDailyDataArray(dataSource);
        }

        var twoHours = new Time.Duration(7200);
        var iterator = null;
        var max = null;

        if(dataSource == 0) {
            if(!(Toybox.SensorHistory has :getBodyBatteryHistory)) { return []; }
            iterator = Toybox.SensorHistory.getBodyBatteryHistory({:period => twoHours, :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST});
            max = 100;
        } else if(dataSource == 1) {
            if(!(Toybox.SensorHistory has :getElevationHistory)) { return []; }
            iterator = Toybox.SensorHistory.getElevationHistory({:period => twoHours, :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST});
        } else if(dataSource == 2) {
            if(!(Toybox.SensorHistory has :getHeartRateHistory)) { return []; }
            iterator = Toybox.SensorHistory.getHeartRateHistory({:period => twoHours, :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST});
        } else if(dataSource == 3) {
            if(!(Toybox.SensorHistory has :getOxygenSaturationHistory)) { return []; }
            iterator = Toybox.SensorHistory.getOxygenSaturationHistory({:period => twoHours, :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST});
            max = 100;
        } else if(dataSource == 4) {
            if(!(Toybox.SensorHistory has :getPressureHistory)) { return []; }
            iterator = Toybox.SensorHistory.getPressureHistory({:period => twoHours, :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST});
        } else if(dataSource == 5 or dataSource == 7) {
            if(!(Toybox.SensorHistory has :getStressHistory)) { return []; }
            iterator = Toybox.SensorHistory.getStressHistory({:period => twoHours, :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST});
            max = 100;
        } else if(dataSource == 6) {
            if(!(Toybox.SensorHistory has :getTemperatureHistory)) { return []; }
            iterator = Toybox.SensorHistory.getTemperatureHistory({:period => twoHours, :order => Toybox.SensorHistory.ORDER_OLDEST_FIRST});
        }

        if(iterator == null) { return []; }
        if(max == null) { max = iterator.getMax(); }
        var min = iterator.getMin();
        if(min == null or max == null) { return []; }

        var hrMin = 0;
        if(dataSource == 2) {
            var hrProfile = UserProfile.getProfile();
            if(hrProfile != null && hrProfile.restingHeartRate != null && hrProfile.restingHeartRate > 30) {
                hrMin = hrProfile.restingHeartRate;
            }
        }

        // Set Y axis bounds for axis labels
        if(dataSource == 0) {
            cachedGraphYMin = 0.0; cachedGraphYMax = 100.0;
        } else if(dataSource == 1 or dataSource == 4) {
            var rawMin = min * 0.9;
            cachedGraphYMin = dataSource == 4 ? (rawMin / 100.0).toFloat() : rawMin.toFloat();
            cachedGraphYMax = dataSource == 4 ? (max.toFloat() / 100.0) : max.toFloat();
        } else if(dataSource == 2) {
            cachedGraphYMin = hrMin.toFloat(); cachedGraphYMax = max.toFloat();
        } else if(dataSource == 3) {
            cachedGraphYMin = 50.0; cachedGraphYMax = 100.0;
        } else if(dataSource == 5 or dataSource == 7) {
            cachedGraphYMin = 0.0; cachedGraphYMax = 100.0;
        } else if(dataSource == 6) {
            cachedGraphYMin = min.toFloat(); cachedGraphYMax = max.toFloat();
        }

        // Allocate one slot per display column, each covering an equal slice of the 2h window.
        // Anchor the right edge to the actual newest sample time rather than Time.now(), so the
        // slot mapping stays aligned even when the device clock drifts from sample timestamps.
        // secsPerSlot is exact because all graphTargetWidth values (25, 40, 45) divide 7200 evenly.
        var newestMoment = iterator.getNewestSampleTime();
        var oldestMoment = iterator.getOldestSampleTime();
        var nowEpoch = Time.now().value();
        var newestEpoch = newestMoment != null ? newestMoment.value() : nowEpoch;
        var oldestEpoch = oldestMoment != null ? oldestMoment.value() : (nowEpoch - 7200);
        // Some simulators return getNewestSampleTime/getOldestSampleTime with swapped semantics,
        // so take whichever is actually later as the right edge of the window.
        var windowEndEpoch = newestEpoch > oldestEpoch ? newestEpoch : oldestEpoch;
        var windowStartEpoch = windowEndEpoch - 7200;
        var secsPerSlot = 7200 / _targetWidth;
        var isStress = (dataSource == 5 or dataSource == 7);
        var diff = max - (min * 0.9);

        // ORDER_OLDEST_FIRST: older samples write first, newer samples overwrite → newest wins per slot.
        var ret = [] as Array<Number>;
        for(var i = 0; i < _targetWidth; i++) { ret.add(-1); }

        var sample = iterator.next();
        while(sample != null) {
            var slot = (sample.when.value() - windowStartEpoch) / secsPerSlot;
            if(slot < 0) { slot = 0; }
            if(slot >= _targetWidth) { slot = _targetWidth - 1; }

            var normalized = -1;
            if(dataSource == 2) {
                if(sample.data != null and sample.data != 0 and sample.data < 255) {
                    var hrRange = max - hrMin;
                    normalized = hrRange > 0 ? Math.round((sample.data.toFloat() - hrMin) / hrRange * 100).toNumber() : 0;
                    if(normalized < 0) { normalized = 0; }
                }
            } else if(dataSource == 1 or dataSource == 4) {
                if(sample.data != null) {
                    normalized = Math.round((sample.data.toFloat() - Math.round(min * 0.9)) / diff * 100).toNumber();
                }
            } else if(dataSource == 3) {
                if(sample.data != null) {
                    normalized = Math.round((sample.data.toFloat() - 50.0) / 50.0 * 100).toNumber();
                }
            } else {
                if(sample.data != null) {
                    normalized = Math.round(sample.data.toFloat() / max * 100).toNumber();
                }
                // for stress, null data stays -1 (not measurable — explicit gap)
            }

            if(normalized >= 0 or isStress) {
                ret[slot] = normalized;
            }

            sample = iterator.next();
        }

        return ret;
    }

    // Daily activity graph (distance / steps / active minutes), past 6 days + today.
    hidden function getDailyDataArray(dataSource as Number) as Array<Number> {
        graphGoalLine = null;
        cachedGraphData2 = null;
        var history = ActivityMonitor.getHistory();
        var todayInfo = ActivityMonitor.getInfo();
        var rawData = [];
        var rawVigorous = [];

        if(history != null) {
            var daysAvail = history.size() < 6 ? history.size() : 6;
            for(var i = daysAvail - 1; i >= 0; i--) {
                rawData.add(getHistoryDayValue(history[i], dataSource));
                if(dataSource == 10) {
                    rawVigorous.add(history[i].activeMinutes != null ? history[i].activeMinutes.vigorous * 2 : 0);
                }
            }
        }
        rawData.add(getTodayActivityValue(todayInfo, dataSource));
        if(dataSource == 10) {
            rawVigorous.add(todayInfo.activeMinutesDay != null ? todayInfo.activeMinutesDay.vigorous * 2 : 0);
        }

        var maxVal = 0;
        for(var i = 0; i < rawData.size(); i++) {
            if(rawData[i] > maxVal) { maxVal = rawData[i]; }
        }

        cachedGraphYMin = 0.0;
        if(dataSource == 8) {
            // Distance is in cm; convert to user's distance unit for the axis label
            cachedGraphYMax = maxVal.toFloat() / (_propIsMetricDistance ? 100000.0 : 160934.4);
        } else {
            cachedGraphYMax = maxVal.toFloat();
        }

        var ret = [];
        if(maxVal > 0) {
            for(var i = 0; i < rawData.size(); i++) {
                ret.add(Math.round(rawData[i].toFloat() / maxVal * 100).toNumber());
            }
            if(dataSource == 9 and todayInfo.stepGoal != null and todayInfo.stepGoal > 0) {
                var goalNorm = Math.round(todayInfo.stepGoal.toFloat() / maxVal * 100).toNumber();
                if(goalNorm <= 100) { graphGoalLine = goalNorm; }
            }
            if(dataSource == 10) {
                var vigRet = [];
                for(var i = 0; i < rawVigorous.size(); i++) {
                    vigRet.add(Math.round(rawVigorous[i].toFloat() / maxVal * 100).toNumber());
                }
                cachedGraphData2 = vigRet;
            }
        }
        return ret;
    }

    hidden function getHistoryDayValue(dayInfo, dataSource as Number) as Number {
        if(dataSource == 8) { return dayInfo.distance != null ? dayInfo.distance : 0; }
        if(dataSource == 9) { return dayInfo.steps != null ? dayInfo.steps : 0; }
        if(dataSource == 10) { return dayInfo.activeMinutes != null ? dayInfo.activeMinutes.total : 0; }
        return 0;
    }

    hidden function getTodayActivityValue(todayInfo, dataSource as Number) as Number {
        if(dataSource == 8) { return todayInfo.distance != null ? todayInfo.distance : 0; }
        if(dataSource == 9) { return todayInfo.steps != null ? todayInfo.steps : 0; }
        if(dataSource == 10) { return todayInfo.activeMinutesDay != null ? todayInfo.activeMinutesDay.total : 0; }
        return 0;
    }

}
