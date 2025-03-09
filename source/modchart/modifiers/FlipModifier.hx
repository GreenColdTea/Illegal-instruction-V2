package modchart.modifiers;

import modchart.*;
import flixel.math.FlxMath;
import math.Vector3;

class FlipModifier extends Modifier {
    override function getPath(visualDiff:Float, pos:Vector3, data:Int, player:Int, timeDiff:Float) {
        if (getPercent(player) == 0 || player >= modMgr.receptors.length || data >= modMgr.receptors[player].length)
            return pos;

        var receptors = modMgr.receptors[player];
        var kNum = receptors.length - 1;

        // barriers
        if (data < 0 || data > kNum) return pos;

        var distance = Note.swagWidth * (kNum / 2) * (1 - (2 * data / kNum));
        pos.x += distance * getPercent(player);

        return pos;
    }
}
