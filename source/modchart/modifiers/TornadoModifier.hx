package modchart.modifiers;

import modchart.*;
import flixel.math.FlxMath;
import math.*;

class TornadoModifier extends NoteModifier {
    override function getName():String return "tornado";

    override function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite):Vector3 {
        if (getPercent(player) == 0) return pos;

        var receptors = modMgr.receptors[player];
        if (receptors == null || receptors.length == 0) return pos;

        var playerColumn = data % receptors.length;
        var columnPhaseShift = playerColumn * Math.PI / 3;
        var phaseShift = diff / 135;
        var returnReceptorToZeroOffsetX = (-Math.cos(-columnPhaseShift) + 1) / 2 * Note.swagWidth * 3;
        var offsetX = (-Math.cos(phaseShift - columnPhaseShift) + 1) / 2 * Note.swagWidth * 3 - returnReceptorToZeroOffsetX;

        return pos.add(new Vector3(offsetX * getPercent(player)));
    }
}
