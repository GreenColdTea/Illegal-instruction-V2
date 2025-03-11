// @author Nebula_Zorua

package modchart;

import flixel.FlxSprite;
import math.Vector3;

// Optimized modifier system based on Schmovin' and Andromeda

@:enum
abstract ModifierType(Int) to Int {
    var NOTE_MOD = 0; // used when the modifier affects the notes
    var MISC_MOD = 1; // used for everything else
}

@:enum
abstract ModifierOrder(Int) to Int {
    var FIRST = -1000;
    var PRE_REVERSE = -3;
    var REVERSE = -2;
    var POST_REVERSE = -1;
    var DEFAULT = 0;
    var LAST = 1000;
}

class Modifier {
    public var modMgr:ModManager;
    public var percents:Array<Float> = [0, 0];
    public var submods:Map<String, Modifier> = [];
    public var parent:Modifier;
    public var active:Bool = false;

    public function getModType():ModifierType
        return MISC_MOD;

    public function ignorePos():Bool
        return false;

    public function ignoreUpdateReceptor():Bool
        return true;

    public function ignoreUpdateNote():Bool
        return true;

    public function doesUpdate():Bool
        return getModType() == MISC_MOD;

    public function shouldExecute(player:Int, value:Float):Bool
        return value != 0;

    public function getOrder():Int
        return DEFAULT;

    public function getName():String
        return ""; 

    public function getValue(player:Int):Float
        return percents[player];

    public function getPercent(player:Int):Float
        return percents[player] * 100;

    public function setValue(value:Float, player:Int = -1) {
        if (player == -1)
            percents.fill(value);
        else
            percents[player] = value;
    }

    public function setPercent(percent:Float, player:Int = -1)
        setValue(percent / 100, player);

    public function getSubmods():Array<String>
        return [];

    public function getSubmodPercent(modName:String, player:Int):Float
        return submods.exists(modName) ? submods.get(modName).getPercent(player) : 0;

    public function getSubmodValue(modName:String, player:Int):Float
        return submods.exists(modName) ? submods.get(modName).getValue(player) : 0;

    public function setSubmodPercent(modName:String, endPercent:Float, player:Int) {
        if (submods.exists(modName))
            submods.get(modName).setPercent(endPercent, player);
    }

    public function setSubmodValue(modName:String, endValue:Float, player:Int) {
        if (submods.exists(modName))
            submods.get(modName).setValue(endValue, player);
    }

    public function new(modMgr:ModManager, ?parent:Modifier) {
        this.modMgr = modMgr;
        this.parent = parent;
        for (submod in getSubmods())
            submods.set(submod, new SubModifier(submod, modMgr, this));
    }

    // To influence the positions of notes/receptors
    public function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int) {}
    public function updateNote(beat:Float, note:Note, pos:Vector3, player:Int) {}
    public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite):Vector3
        return pos;

    // Major update for non-note modifiers
    public function update(elapsed:Float) {}
}
