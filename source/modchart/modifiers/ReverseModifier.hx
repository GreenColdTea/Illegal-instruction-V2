package modchart.modifiers;

import flixel.math.FlxRect;
import modchart.Modifier.ModifierOrder;
import flixel.FlxSprite;
import flixel.FlxG;
import modchart.*;
import math.*;
import meta.data.*;
import gameObjects.*;

class ReverseModifier extends NoteModifier {
    override function getOrder() return REVERSE;
    override function getName() return "reverse";

    inline function lerp(a:Float, b:Float, c:Float) return a + (b - a) * c;

    public function getReverseValue(dir:Int, player:Int, ?scrolling=false) {
        var suffix = scrolling ? "Scroll" : "";
        var receptors = modMgr.receptors[player];
        var kNum = receptors.length;
        var val:Float = 0;

        if (dir >= kNum / 2) val += getSubmodValue("split" + suffix, player);
        if ((dir % 2) == 1) val += getSubmodValue("alternate" + suffix, player);
        if (dir >= kNum / 4 && dir <= kNum - 1 - (kNum / 4)) val += getSubmodValue("cross" + suffix, player);

        if (suffix == "")
            val += getValue(player) + getSubmodValue("reverse" + Std.string(dir), player);
        else
            val += getSubmodValue("reverse" + suffix, player);

        if (getSubmodValue("unboundedReverse", player) == 0) {
            val %= 2;
            if (val > 1) val = 2 - val;
        }

        if (ClientPrefs.downScroll) val = 1 - val;
        return val;
    }

    public function getScrollReversePerc(dir:Int, player:Int)
        return getReverseValue(dir, player) * 100;

    override function shouldExecute(player:Int, val:Float) return true;
    override function ignoreUpdateNote() return false;

    override function updateNote(beat:Float, daNote:Note, pos:Vector3, player:Int) {
        var revPerc = getReverseValue(daNote.noteData, player);
        var strumLine = modMgr.receptors[player][daNote.noteData];
        var center:Float = strumLine.y + Note.swagWidth / 2;

        if (daNote.isSustainNote) {
            var y = pos.y + daNote.offsetY;
            var hit = (strumLine.sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
                (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))));

            if (hit) {
                var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

                if (revPerc >= 0.5) {
                    if (y - daNote.offset.y * daNote.scale.y + daNote.height >= center) {
                        swagRect.height = (center - y) / daNote.scale.y;
                        swagRect.y = daNote.frameHeight - swagRect.height;
                    }
                } else {
                    if (y + daNote.offset.y * daNote.scale.y <= center) {
                        swagRect.y = (center - y) / daNote.scale.y;
                        swagRect.height -= swagRect.y;

                        daNote.clipRect = swagRect;
                    }
                }
            }
        }
    }

    override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite) {
        var perc = getReverseValue(data, player);
        var shift = CoolUtil.scale(perc, 0, 1, 50, FlxG.height - 150);
        var mult = CoolUtil.scale(perc, 0, 1, 1, -1);
        shift = CoolUtil.scale(getSubmodValue("centered", player), 0, 1, shift, (FlxG.height / 2) - 56);

        pos.y = shift + (visualDiff * mult);

        if (obj is Note) {
            var note:Note = cast obj;
            if (note.isSustainNote && perc > 0) {
                pos.y = applySustainOffsets(note, pos.y);
            }
        }

        return pos;
    }

    private function applySustainOffsets(note:Note, y:Float):Float {
        var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
        var songSpeed:Float = PlayState.instance.songSpeed * note.multSpeed;

        if (note.animation.curAnim.name.endsWith("end")) {
            y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
            y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
            y -= 19;
        }

        y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
        y += 27.5 * ((PlayState.SONG.bpm / 100) - 1) * (songSpeed - 1);
        return y;
    }

    override function getSubmods() {
        var subMods:Array<String> = [
            "cross", "split", "alternate", "reverseScroll", 
            "crossScroll", "splitScroll", "alternateScroll", 
            "centered", "unboundedReverse"
        ];

        for (i in 0...4) subMods.push('reverse${i}');
        return subMods;
    }
}
