// @author Nebula_Zorua
// @optimization GCT

package modchart;

import modchart.modifiers.*;
import modchart.events.*;
import flixel.tweens.FlxEase;
import modchart.Modifier.ModifierType;
import flixel.FlxG;
import flixel.FlxSprite;
import math.Vector3;

class ModManager {
    private var state:PlayState;
    private var timeline:EventTimeline = new EventTimeline();

    private var activeMods:Array<Array<String>> = [[], []]; 
    private var modArray:Array<Modifier> = [];

    public var receptors:Array<Array<StrumNote>> = [[], []];
    public var register:Map<String, Modifier> = [];

    public function new(state:PlayState) {
        this.state = state;
    }

    /*public function setReceptors() {
        for (data in 0...state.playerStrums.length) 
            receptors[0][state.playerStrums.members[data].noteData] = state.playerStrums.members[data];

        for (data in 0...state.opponentStrums.length) 
            receptors[1][state.opponentStrums.members[data].noteData] = state.opponentStrums.members[data];
    }*/

    public function registerDefaultModifiers() {
        var quickRegs:Array<Any> = [
            FlipModifier,
            ReverseModifier,
            InvertModifier,
            DrunkModifier,
            BeatModifier,
            AlphaModifier,
            ReceptorScrollModifier, 
            ScaleModifier, 
            ConfusionModifier, 
            OpponentModifier, 
            TransformModifier, 
            InfinitePathModifier, 
            PerspectiveModifier, 
            AccelModifier, 
            XModifier
        ];

        for (mod in quickRegs)
            quickRegister(Type.createInstance(mod, [this]));

        quickRegister(new RotateModifier(this));
        quickRegister(new RotateModifier(this, 'center', new Vector3((FlxG.width * 0.5) - (Note.swagWidth / 2), (FlxG.height * 0.5) - Note.swagWidth / 2)));
        quickRegister(new LocalRotateModifier(this, 'local'));
        quickRegister(new SubModifier("noteSpawnTime", this));

        setValue("noteSpawnTime", 2000);
        setValue("xmod", 1);
        for (i in 0...4)
            setValue('xmod$i', 1);
    }

    inline public function quickRegister(mod:Modifier)
        registerMod(mod.getName(), mod);

    public function registerMod(modName:String, mod:Modifier) {
        if (register.exists(modName)) return;
        register.set(modName, mod);

        timeline.addMod(modName);
        modArray.push(mod);
        setValue(modName, 0);
        modArray.sort((a, b) -> Std.int(a.getOrder() - b.getOrder()));
    }

    public function removeMod(modName:String, player:Int = -1) {
        if (player == -1) {
            removeMod(modName, 0);
            removeMod(modName, 1);
        } else {
            activeMods[player].remove(modName);
        }

        register.remove(modName);
        timeline.removeModEvents(modName);
    }

    inline public function get(modName:String):Modifier {
        return register.get(modName);
    }

    inline public function getVisPos(songPos:Float = 0, strumTime:Float = 0, songSpeed:Float = 1) {
        return -(0.45 * (songPos - strumTime) * songSpeed);
    }

    public function setValue(modName:String, val:Float, player:Int = -1) {
        if (player == -1) {
            for (pN in 0...2) setValue(modName, val, pN);
            return;
        }

        var mod = register.get(modName);
        if (mod == null) return;

        if (!mod.shouldExecute(player, val)) {
            activeMods[player].remove(modName);
            return;
        }

        mod.setValue(val, player);
        if (!activeMods[player].contains(modName)) {
            activeMods[player].push(modName);
        }

        activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
    }

    public function update(elapsed:Float) {
        updateTimeline(state.curDecStep);
        for (mod in modArray) mod.update(elapsed);
    }

    public function updateTimeline(curStep:Float) {
        timeline.update(curStep);
    }

    public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, data:Int, player:Int, obj:FlxSprite, ?exclusions:Array<String>, ?pos:Vector3):Vector3 {
        if (exclusions == null) exclusions = [];
        if (pos == null) pos = new Vector3();

        if (!obj.active) return pos;

        pos.x = getBaseX(data, player);
        pos.y = 50 + diff;
        pos.z = 0;

        for (modName in activeMods[player]) {
            if (exclusions.contains(modName)) continue;
            var mod = register.get(modName);
            if (mod == null) continue;
            pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
        }
        return pos;
    }

    public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int) {
        for (name in activeMods[player]) {
            var mod = register.get(name);
            if (mod == null || !obj.active) continue;

            if (obj is Note) mod.updateNote(beat, cast obj, pos, player);
            else if (obj is StrumNote) mod.updateReceptor(beat, cast obj, pos, player);
        }

        if (obj is Note) obj.updateHitbox();
        obj.centerOrigin();
        obj.centerOffsets();
    }

    public function getBaseX(direction:Int, player:Int):Float {
        var x = (FlxG.width * 0.5) - Note.swagWidth - 54 + Note.swagWidth * direction;
        if (player == 0) x += FlxG.width * 0.5 - Note.swagWidth * 2 - 100;
        else if (player == 1) x -= FlxG.width * 0.5 - Note.swagWidth * 2 - 100;
        return x - 56;
    }

    public function queueEaseTime(time:Float, endTime:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
        var step:Float = time * (Conductor.bpm / 60) * 4;
        var endStep:Float = endTime * (Conductor.bpm / 60) * 4;
        queueEase(step, endStep, modName, percent / 100, style, player, startVal / 100);
    }

    public function queueSetTime(time:Float, modName:String, percent:Float, player:Int = -1) {
        var step:Float = time * (Conductor.bpm / 60) * 4;
        queueSet(step, modName, percent / 100, player);
    }

    public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
        queueEase(step, endStep, modName, percent / 100, style, player, startVal / 100);
    }

    public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1) {
        queueSet(step, modName, percent / 100, player);
    }

    public function queueEase(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
        if (player == -1) {
            queueEase(step, endStep, modName, percent, style, 0, startVal);
            queueEase(step, endStep, modName, percent, style, 1, startVal);
            return;
        }

        var easeFunc = Reflect.getProperty(FlxEase, style);
        if (easeFunc == null) easeFunc = FlxEase.linear;
        timeline.addEvent(new EaseEvent(step, endStep, modName, percent, easeFunc, player, this, startVal));
    }

    public function queueSet(step:Float, modName:String, percent:Float, player:Int = -1) {
        if (player == -1) {
            queueSet(step, modName, percent, 0);
            queueSet(step, modName, percent, 1);
            return;
        }
        timeline.addEvent(new SetEvent(step, modName, percent, player, this));
    }
}
