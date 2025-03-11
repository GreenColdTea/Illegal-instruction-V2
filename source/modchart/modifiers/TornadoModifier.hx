package modchart.modifiers;

import modchart.*;
import math.Vector3;
import flixel.FlxG;

class TornadoModifier extends Modifier {
    override public function getModType()
        return NOTE_MOD; // Affects note positions

    override public function getName()
        return "tornado";

    override public function getOrder()
        return DEFAULT;

    override public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite):Vector3 {
        var strength = getValue(player);
        if (strength == 0) return pos;

        var receptors = modMgr.receptors[player];
        var len = receptors.length;
        var column = data % len;

        var phaseShift = diff / 135;
        var columnPhaseShift = column * Math.PI / 3;

        var baseOffset = (-Math.cos(-columnPhaseShift) + 1) / 2 * Note.swagWidth * 3;
        var offsetX = (-Math.cos(phaseShift - columnPhaseShift) + 1) / 2 * Note.swagWidth * 3 - baseOffset;

        var outPos = pos.clone();
        return outPos.add(new Vector3(offsetX * strength));
    }
}
