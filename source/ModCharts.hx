package;

import modchart.*;
import flixel.math.FlxAngle;

class ModCharts {
    static function numericForInterval(start, end, interval, func){
        var index = start;
        while(index < end){
            func(index);
            index += interval;
        }
    }
    
    public static function lesGo(shit:PlayState, modManager:ModManager, songName:String) {
        switch (songName) {
            case "breakout":
                modManager.queueEaseP(384, 399, "drunk", 25, "quadIn");
                modManager.queueEaseP(384, 399, "tipsy", 15, "quadIn");

                modManager.queueEaseP(640, 656, "drunk", 0, "quadOut");
                modManager.queueEaseP(640, 656, "tipsy", 0, "quadOut");

                modManager.queueSetP(800, "boost", 65);

                modManager.queueSetP(1056, "boost", 0);

                modManager.queueEaseP(1056, 1062, "drunk", 30, "quadIn");
                modManager.queueEaseP(1056, 1062, "tipsy", 20, "quadIn");

                if (ClientPrefs.opponentStrums && !ClientPrefs.middleScroll) {
                    modManager.queueEaseP(1313, 1319, "alpha", 50, "cubeIn", 1);
                    modManager.queueEaseP(1313, 1325, "opponentSwap", 50, "backIn");
                }

                if (ClientPrefs.opponentStrums) {
                    modManager.queueEaseP(1568, 1571, "alpha", 0, "cubeOut", 1);
                }
                modManager.queueEaseP(1574, 1588, "opponentSwap", 0, "backOut");

                modManager.queueSetP(1613, "boost", 40);

                modManager.queueSetP(1870, "boost", 0);
                modManager.queueEaseP(1870, 1873, "opponentSwap", 100, "quadIn");

                if (ClientPrefs.opponentStrums) {
                    modManager.queueEaseP(2000, 2003, "alpha", 50, "cubeIn", 1);
                }
                modManager.queueEaseP(2000, 2004, "opponentSwap", 50, "backIn");

                numericForInterval(2138, 2288, 9, function(step) {
                    var value = (Std.int((step - 2138) / 9) % 2 == 0) ? 0 : 100;
                    modManager.queueEaseP(step, step + 8, "opponentSwap", value, "backIn");
                });  
                          
                modManager.queueEaseP(2289, 2300, "opponentSwap", 50, "backIn");
        }
    }
}
    
