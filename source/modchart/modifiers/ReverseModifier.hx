package modchart.modifiers;
import ui.*;
import modchart.*;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
using StringTools;
import math.*;

class ReverseModifier extends Modifier {
    private var cachedUpscrollOffset:Float;
    private var cachedDownscrollOffset:Float;

    public function new(modMgr:ModManager) {
        super(modMgr);
        cachedUpscrollOffset = modMgr.state.upscrollOffset;
        cachedDownscrollOffset = modMgr.state.downscrollOffset;
    }

    public function getReversePercent(dir:Int, player:Int, ?scrolling=false):Float {
        var suffix = scrolling ? "Scroll" : "";
        var receptors = modMgr.receptors[player];
        var kNum = receptors.length;
        
        var percent = getPercent(player) 
            + getSubmodPercent("reverse" + Std.string(dir), player) 
            + getSubmodPercent("split" + suffix, player) 
            + getSubmodPercent("alternate" + suffix, player);
        
        if (dir >= kNum / 2) percent += getSubmodPercent("split" + suffix, player);
        if ((dir % 2) == 1) percent += getSubmodPercent("alternate" + suffix, player);
        
        var first = kNum / 4;
        var last = kNum - 1 - first;
        if (dir >= first && dir <= last) percent += getSubmodPercent("cross" + suffix, player);
        
        if (ClientPrefs.downScroll) percent = 1 - percent;
        
        return percent;
    }

    public function getScrollReversePerc(dir:Int, player:Int):Float {
        return getReversePercent(dir, player);
    }

    override function getPath(visualDiff:Float, pos:Vector3, data:Int, player:Int, timeDiff:Float):Vector3 {
        var perc = getReversePercent(data, player);
        var mult = (perc * -2) + 1;
        var shift = CoolUtil.scale(perc, 0, 1, cachedUpscrollOffset, cachedDownscrollOffset);
        shift = CoolUtil.scale(getSubmodPercent("centered", player), 0, 1, shift, modMgr.state.center.y - Note.swagWidth / 2);

        pos.y = shift + (visualDiff * mult);
        return pos;
    }

    override function updateNote(note:Note, player:Int, pos:Vector3, scale:FlxPoint) {
        var perc = getScrollReversePerc(note.noteData, note.mustPress ? 0 : 1);
        if (note.isSustainNote) {
            var newFlipY = perc >= 0.5;
            if (note.flipY != newFlipY) note.flipY = newFlipY;
        }
    }

    override function getSubmods():Array<String> {
        return [
            "cross", "split", "alternate", "reverseScroll", "crossScroll", 
            "splitScroll", "alternateScroll", "centered", 
            "reverse0", "reverse1", "reverse2", "reverse3"
        ];
    }
}
