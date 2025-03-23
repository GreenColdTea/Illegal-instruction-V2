// @author Nebula_Zorua
// @optimization GCT

package modchart;

import modchart.modifiers.*;
import modchart.events.*;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.FlxSprite;
import math.Vector3;

class ModManager {
    private var state:PlayState;
    private var timeline:EventTimeline = new EventTimeline();

    private var definedMods:Map<String, Modifier> = [];
    private var activeMods:Array<Array<String>> = [[], []]; 
    private var modArray:Array<Modifier> = [];

    public var receptors:Array<Array<StrumNote>> = [[], []];
    public var infPath:Array<Array<Vector3>> = [[], [], [], []];

    public function new(state:PlayState) {
        this.state = state;
    }

    public function setReceptors() {
        for (data in 0...state.playerStrums.length) 
            receptors[0][state.playerStrums.members[data].noteData] = state.playerStrums.members[data];

        for (data in 0...state.opponentStrums.length) 
            receptors[1][state.opponentStrums.members[data].noteData] = state.opponentStrums.members[data];
    }

    public function registerDefaultModifiers() {
        var quickRegs:Array<Modifier> = [
            new FlipModifier(this),
            new ReverseModifier(this),
            new InvertModifier(this),
            new DrunkModifier(this),
            new BeatModifier(this),
            new AlphaModifier(this),
            new ReceptorScrollModifier(this),
            new ScaleModifier(this),
            new ConfusionModifier(this),
            new OpponentModifier(this),
            new TransformModifier(this),
            new InfinitePathModifier(this),
            new PerspectiveModifier(this),
            new AccelModifier(this),
            new XModifier(this)
        ];

        for (mod in quickRegs)
            defineMod(mod.getName(), mod);

        defineMod("rotateX", new RotateModifier(this));
        defineMod("centerrotateX", new RotateModifier(this, 'center', new Vector3(FlxG.width * 0.5 - Note.swagWidth / 2, FlxG.height * 0.5 - Note.swagWidth / 2)));
        defineMod("localrotateX", new LocalRotateModifier(this));

        defineBlankMod("waveTimeFactor");
        set("waveTimeFactor", 100, 0);
        set("waveTimeFactor", 100, 1);
        set("noteSpawnTime", 2000);
        set("xmod", 1);
        for(i in 0...4) set("xmod$i", 1);

        var r = 0;
        while (r < 360) {
            var rad = r * Math.PI / 180;
            for (data in 0...infPath.length) {
                infPath[data].push(new Vector3(
                    FlxG.width / 2 + Math.sin(rad) * 600,
                    FlxG.height / 2 + (Math.sin(rad) * Math.cos(rad)) * 600, 0
                ));
            }
            r += 15;
        }
        defineMod("infinite", new PathModifier(this, infPath, 1850));
    }

    public function defineMod(modName:String, modifier:Modifier) {
        if (!definedMods.exists(modName)) {
            modArray.push(modifier);
            definedMods.set(modName, modifier);
            timeline.addMod(modName);
        }
    }

    inline public function defineBlankMod(modName:String) {
        defineMod(modName, new Modifier(this), false);
    }

    inline public function removeMod(modName:String) {
        definedMods.remove(modName);
    }

    inline public function get(modName:String):Modifier {
        return definedMods[modName];
    }

    inline public function exists(modName:String):Bool {
        return definedMods.exists(modName);
    }

    public function setValue(modName:String, val:Float, player:Int = -1) {
        if (player == -1) {
            for (pN in 0...2)
                setValue(modName, val, pN);
        } else {
            var mod = definedMods.get(modName);
            if (mod == null) return;

            if (activeMods[player] == null)
                activeMods[player] = [];

            mod.setValue(val, player);

            if (!activeMods[player].contains(modName) && mod.shouldExecute(player, val)) {
                activeMods[player].push(modName);
            } else if (!mod.shouldExecute(player, val)) {
                activeMods[player].remove(modName);
            }

            activeMods[player].sort((a, b) -> Std.int(definedMods.get(a).getOrder() - definedMods.get(b).getOrder()));
        }
    }

    public function getModPercent(modName:String, player:Int):Float {
        return get(modName).getPercent(player);
    }

    public function update(elapsed:Float) {
        updateTimeline(state.curDecStep);
        for (mod in modArray)
            mod.update(elapsed);
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
            var mod = definedMods.get(modName);
            pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
        }
        return pos;
    }

    public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int) {
        for (name in activeMods[player]) {
            var mod:Modifier = definedMods.get(name);
            if (mod == null) continue;
            if (!obj.active) continue;

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

    public function queueEase(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
        if (player == -1) {
            queueEase(step, endStep, modName, percent, style, 0, startVal);
            queueEase(step, endStep, modName, percent, style, 1, startVal);
        } else {
            var easeFunc = Reflect.getProperty(FlxEase, style) ?? FlxEase.linear;
            timeline.addEvent(new EaseEvent(step, endStep, modName, percent, easeFunc, player, this, startVal));
        }
    }

    public function queueSet(step:Float, modName:String, percent:Float, player:Int = -1) {
        if (player == -1) {
            queueSet(step, modName, percent, 0);
            queueSet(step, modName, percent, 1);
        } else {
            timeline.addEvent(new SetEvent(step, modName, percent, player, this));
        }
    }

    public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
        queueEase(step, endStep, modName, percent / 100, style, player, startVal / 100);
    }

    public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1) {
        queueSet(step, modName, percent / 100, player);
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

    public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void) {
        timeline.addEvent(new StepCallbackEvent(step, endStep, callback, this));
    }

    public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void) {
        timeline.addEvent(new CallbackEvent(step, callback, this));
    }
}
