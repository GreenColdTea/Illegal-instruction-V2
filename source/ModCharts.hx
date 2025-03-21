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

        }
    }
}
    
