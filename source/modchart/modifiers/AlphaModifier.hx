package modchart.modifiers;

import flixel.math.FlxPoint;
import math.*;
import flixel.FlxG;
import modchart.*;

class AlphaModifier extends Modifier {
    public static var fadeDistY = 120;

    override public function getName():String
        return "stealth";

    public function new(modMgr:ModManager) {
        super(modMgr);
    }

    function getHiddenSudden(player:Int = -1) {
        return getSubmodPercent("hidden", player) * getSubmodPercent("sudden", player);
    }

    function getHiddenEnd(player:Int = -1) {
        return (FlxG.height * 0.5) + fadeDistY * CoolUtil.scale(getHiddenSudden(player), 0, 1, -1, -1.25) + (FlxG.height * 0.5) * getSubmodPercent("hiddenOffset", player);
    }

    function getHiddenStart(player:Int = -1) {
        return (FlxG.height * 0.5) + fadeDistY * CoolUtil.scale(getHiddenSudden(player), 0, 1, 0, -0.25) + (FlxG.height * 0.5) * getSubmodPercent("hiddenOffset", player);
    }

    function getSuddenEnd(player:Int = -1) {
        return (FlxG.height * 0.5) + fadeDistY * CoolUtil.scale(getHiddenSudden(player), 0, 1, 1, 1.25) + (FlxG.height * 0.5) * getSubmodPercent("suddenOffset", player);
    }

    function getSuddenStart(player:Int = -1) {
        return (FlxG.height * 0.5) + fadeDistY * CoolUtil.scale(getHiddenSudden(player), 0, 1, 0, 0.25) + (FlxG.height * 0.5) * getSubmodPercent("suddenOffset", player);
    }

    function getVisibility(yPos:Float, player:Int, note:Note):Float {
        var distFromCenter = yPos;
        var alpha:Float = 0;

        if (yPos < 0 && getSubmodPercent("stealthPastReceptors", player) == 0)
            return 1.0;

        var time = Conductor.songPosition / 1000;

        if (getSubmodPercent("hidden", player) != 0) {
            var hiddenAdjust = CoolUtil.clamp(CoolUtil.scale(yPos, getHiddenStart(player), getHiddenEnd(player), 0, -1), -1, 0);
            alpha += getSubmodPercent("hidden", player) * hiddenAdjust;
        }

        if (getSubmodPercent("sudden", player) != 0) {
            var suddenAdjust = CoolUtil.clamp(CoolUtil.scale(yPos, getSuddenStart(player), getSuddenEnd(player), 0, -1), -1, 0);
            alpha += getSubmodPercent("sudden", player) * suddenAdjust;
        }

        if (getPercent(player) != 0)
            alpha -= getPercent(player);

        if (getSubmodPercent("blink", player) != 0) {
            var f = CoolUtil.quantizeAlpha(FlxMath.fastSin(time * 10), 0.3333);
            alpha += CoolUtil.scale(f, 0, 1, -1, 0);
        }

        if (getSubmodPercent("randomVanish", player) != 0) {
            var realFadeDist:Float = 240;
            alpha += CoolUtil.scale(Math.abs(distFromCenter), realFadeDist, 2 * realFadeDist, -1, 0) * getSubmodPercent("randomVanish", player);
        }

        return CoolUtil.clamp(alpha + 1, 0, 1);
    }

    function getGlow(visible:Float) {
        return CoolUtil.clamp(CoolUtil.scale(visible, 1, 0.5, 0, 1.3), 0, 1);
    }

    function getAlpha(visible:Float) {
        return CoolUtil.clamp(CoolUtil.scale(visible, 0.5, 0, 1, 0), 0, 1);
    }

    override public function shouldExecute(player:Int, val:Float):Bool return true;

    override public function updateNote(note:Note, player:Int, pos:Vector3, scale:FlxPoint) {
        var player = note.mustPress ? 0 : 1;
        var speed = PlayState.instance.songSpeed * note.multSpeed;
        var yPos:Float = modMgr.getVisPos(Conductor.songPosition, note.strumTime, speed) + 50;

        note.colorSwap.flash = 0;
        var alphaMod = (1 - getSubmodPercent("alpha", player)) * (1 - getSubmodPercent('alpha${note.noteData}', player)) * (1 - getSubmodPercent("noteAlpha", player)) * (1 - getSubmodPercent('noteAlpha${note.noteData}', player));
        var alpha = getVisibility(yPos, player, note);

        if (getSubmodPercent("dontUseStealthGlow", player) == 0) {
            note.alphaMod = getAlpha(alpha);
            note.colorSwap.flash = getGlow(alpha);
        } else {
            note.alphaMod = alpha;
        }

        note.alphaMod *= alphaMod;
    }

    override public function updateReceptor(receptor:StrumNote, player:Int, pos:Vector3, scale:FlxPoint) {
        var alpha = (1 - getSubmodPercent("alpha", player)) * (1 - getSubmodPercent('alpha${receptor.noteData}', player));
        if (getSubmodPercent("dark", player) != 0 || getSubmodPercent('dark${receptor.noteData}', player) != 0) {
            alpha *= (1 - getSubmodPercent("dark", player)) * (1 - getSubmodPercent('dark${receptor.noteData}', player));
        }

        @:privateAccess
        receptor.colorSwap.daAlpha = alpha;
    }

    override public function getSubmods():Array<String> {
        var subMods:Array<String> = ["noteAlpha", "alpha", "hidden", "hiddenOffset", "sudden", "suddenOffset", "blink", "randomVanish", "dark", "useStealthGlow", "stealthPastReceptors"];
        for (i in 0...4) {
            subMods.push('noteAlpha$i');
            subMods.push('alpha$i');
            subMods.push('dark$i');
        }
        return subMods;
    }
}
