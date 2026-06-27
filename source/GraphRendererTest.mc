import Toybox.Test;
import Toybox.Lang;

// Unit tests for GraphRenderer static helpers (mini graph field codes).
// Run with: monkeyc --unit-test -d fenix7

(:test)
function testIsGraphCodeTrue(logger as Test.Logger) as Boolean {
    return GraphRenderer.isGraphCode(100)
        && GraphRenderer.isGraphCode(110)
        && GraphRenderer.isGraphCode(105);
}

(:test)
function testIsGraphCodeFalse(logger as Test.Logger) as Boolean {
    return !GraphRenderer.isGraphCode(99)
        && !GraphRenderer.isGraphCode(111)
        && !GraphRenderer.isGraphCode(16)
        && !GraphRenderer.isGraphCode(-2);
}

(:test)
function testGraphCodeToDataSource(logger as Test.Logger) as Boolean {
    return GraphRenderer.graphCodeToDataSource(100) == 0
        && GraphRenderer.graphCodeToDataSource(110) == 10
        && GraphRenderer.graphCodeToDataSource(105) == 5
        && GraphRenderer.graphCodeToDataSource(108) == 8;
}
