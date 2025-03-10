// TROLL MODCHART SYSTEM IN PSYCH!!!
// WRITTEN BY NEBULA_ZORUA!!
// PORTED FROM https://github.com/riconuts/FNF-Troll-Engine

package modchart;

import modchart.modifiers.*;
import modchart.Event.*;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import states.*;
import math.*;
import flixel.math.FlxMath;
import flixel.FlxG;
import ui.*;

class ModManager {
    private var definedMods:Map<String, Modifier> = [];
    private var schedule:Map<String, Array<Event>> = [];
    private var funcs:Array<FuncEvent> = [];
    private var mods:Array<Modifier> = [];
    public var infPath:Array<Array<Vector3>> = [[], [], [], []];

    public var state:PlayState;
    public var receptors:Array<Array<StrumNote>> = [[], []];

    private var easingFuncs:Map<String, Float->Float> = [
        "linear" => FlxEase.linear,

        "quadIn" => FlxEase.quadIn, "quadOut" => FlxEase.quadOut, "quadInOut" => FlxEase.quadInOut,
        "cubeIn" => FlxEase.cubeIn, "cubeOut" => FlxEase.cubeOut, "cubeInOut" => FlxEase.cubeInOut,
        "quartIn" => FlxEase.quartIn, "quartOut" => FlxEase.quartOut, "quartInOut" => FlxEase.quartInOut,
        "quintIn" => FlxEase.quintIn, "quintOut" => FlxEase.quintOut, "quintInOut" => FlxEase.quintInOut,
    
        "sineIn" => FlxEase.sineIn, "sineOut" => FlxEase.sineOut, "sineInOut" => FlxEase.sineInOut,
        "expoIn" => FlxEase.expoIn, "expoOut" => FlxEase.expoOut, "expoInOut" => FlxEase.expoInOut,
        "circIn" => FlxEase.circIn, "circOut" => FlxEase.circOut, "circInOut" => FlxEase.circInOut,

        "backIn" => FlxEase.backIn, "backOut" => FlxEase.backOut, "backInOut" => FlxEase.backInOut,
        "elasticIn" => FlxEase.elasticIn, "elasticOut" => FlxEase.elasticOut, "elasticInOut" => FlxEase.elasticInOut,
        "bounceIn" => FlxEase.bounceIn, "bounceOut" => FlxEase.bounceOut, "bounceInOut" => FlxEase.bounceInOut
    ];

    public function new(state:PlayState) {
        this.state = state;
    }

    public function setReceptors() {
        for (pl in 0...2) {
            receptors[pl] = [];
            var strums = (pl == 0 ? state.playerStrums : state.opponentStrums).members;
            for (rec in strums) {
                receptors[pl][rec.noteData] = rec;
            }
        }
    }

    public function getReceptorPos(rec:StrumNote, player:Int = 0):Vector3 {
        return getPath(0, 0, rec.noteData, player);
    }

    public function getReceptorScale(rec:StrumNote, player:Int = 0):FlxPoint {
        var def = rec.scaleDefault;
        var scale = FlxPoint.get(def.x, def.y);
        for (mod in mods) {
            scale = mod.getReceptorScale(rec, scale, rec.noteData, player);
        }
        return scale;
    }

    public function updateReceptor(rec:StrumNote, player:Int, scale:FlxPoint, pos:Vector3) {
        for (mod in mods) {
            mod.updateReceptor(rec, player, pos, scale);
        }
    }

    public function registerModifiers() {
        defineBlankMod("waveTimeFactor");
        set("waveTimeFactor", 100, 0);
        set("waveTimeFactor", 100, 1);

        defineMod("reverse", new ReverseModifier(this));
        defineMod("stealth", new AlphaModifier(this));
        defineMod("opponentSwap", new OpponentModifier(this));
        defineMod("scrollAngle", new AngleModifier(this));
        defineMod("mini", new ScaleModifier(this));
        defineMod("flip", new FlipModifier(this));
        defineMod("invert", new InvertModifier(this));
        defineMod("tornado", new TornadoModifier(this));
        defineMod("drunk", new DrunkModifier(this));
        defineMod("confusion", new ConfusionModifier(this));
        defineMod("beat", new BeatModifier(this));
        defineMod("rotateX", new RotateModifier(this));
        defineMod("centerrotateX", new RotateModifier(this, "center", new Vector3(FlxG.width / 2, FlxG.height / 2)));
        defineMod("localrotateX", new LocalRotateModifier(this));
        defineMod("boost", new AccelModifier(this));
        defineMod("transformX", new TransformModifier(this));
        defineMod("receptorScroll", new ReceptorScrollModifier(this));
        defineMod("perspective", new PerspectiveModifier(this));

        // Optimizations for infPath
        var r = 0;
        while (r < 360) {
            for (data in 0...infPath.length) {
                var rad = r * Math.PI / 180;
                infPath[data].push(new Vector3(
                    FlxG.width / 2 + (FlxMath.fastSin(rad)) * 600,
                    FlxG.height / 2 + (FlxMath.fastSin(rad) * FlxMath.fastCos(rad)) * 600, 0
                ));
            }
            r += 15;
        }
        defineMod("infinite", new PathModifier(this, infPath, 1850));
    }

    public function get(modName:String):Modifier {
        return definedMods.exists(modName) ? definedMods.get(modName) : null;
    }

    public function getList(modName:String, player:Int):Array<ModEvent> {
        if (definedMods.exists(modName)) {
            var list:Array<ModEvent> = [];
            for (e in schedule[modName]) {
                if (e.player == player) {
                    list.push(e);
                }
            }
            list.sort((a, b) -> Std.int(a.step - b.step));
            return list;
        }
        return [];
    }

    public function getLatest(modName:String, player:Int) {
        return schedule[modName] != null && schedule[modName].length > 0
            ? schedule[modName][schedule[modName].length - 1]
            : new ModEvent(0, modName, 0, 0, this);
    }

    public function getPreviousWithEvent(event:ModEvent):ModEvent {
        var list = getList(event.modName, event.player);
        var idx = list.indexOf(event);
        return (idx > 0) ? list[idx - 1] : new ModEvent(0, event.modName, 0, event.player, this);
    }

    public function getLatestWithEvent(event:ModEvent):ModEvent {
        return getLatest(cast(event, ModEvent).modName, cast(event, ModEvent).player);
    }

    public function getNoteScale(note:Note):FlxPoint {
        var def = note.scaleDefault;
        var scale = FlxPoint.get(def.x, def.y);
        for (mod in mods) {
            scale = mod.getNoteScale(note, scale, note.noteData, note.mustPress ? 0 : 1);
        }
        return scale;
    }

    public function updateNote(note:Note, player:Int, scale:FlxPoint, pos:Vector3) {
        for (mod in mods) {
            mod.updateNote(note, player, pos, scale);
        }
    }

    public function defineMod(modName:String, modifier:Modifier) {
        if (!definedMods.exists(modName)) {
            mods.push(modifier);
            schedule.set(modName, []);
            definedMods.set(modName, modifier);
        }
    }

    public function removeMod(modName:String) {
        if (definedMods.exists(modName)) {
            definedMods.remove(modName);
        }
    }

    public function defineBlankMod(modName:String) {
        defineMod(modName, new Modifier(this));
    }

    public function getModPercent(modName:String, player:Int):Float {
        return definedMods.exists(modName) ? definedMods[modName].getPercent(player) : 0;
    }

    public function exists(modName:String):Bool {
        return definedMods.exists(modName);
    }

    public function set(modName:String, percent:Float, player:Int) {
        if (exists(modName)) {
            if (percent == 0) removeMod(modName);
            else definedMods[modName].setPercent(percent, player);
        }
    }

    private function run() {
        for (modName in schedule.keys()) {
            var events = schedule[modName];
            for (event in events) {
                if (!event.finished && state.curDecStep >= event.step)
                    event.run(state.curDecStep);
            }
        }
        for (event in funcs) {
            if (!event.finished && state.curDecStep >= event.step)
                event.run(state.curDecStep);
        }
    }

    public function update(elapsed:Float) {
        run();
        for (mod in mods) mod.update(elapsed);
    }

    public function getPath(diff:Float, vDiff:Float, column:Int, player:Int):Vector3 {
        var pos = new Vector3(state.getXPosition(diff, column, player), vDiff, 0);
        for (mod in mods) pos = mod.getPath(vDiff, pos, column, player, diff);
        return pos;
    }

    public function queueEase(step:Float, endStep:Float, modName:String, percent:Float, style:String = "linear", player:Int = -1, ?startVal:Float) {
        var easeFunc = easingFuncs.exists(style) ? easingFuncs[style] : FlxEase.linear;
        if (player == -1) {
            queueEase(step, endStep, modName, percent, style, 0);
            queueEase(step, endStep, modName, percent, style, 1);
        } else {
            schedule[modName].push(new EaseEvent(step, endStep, modName, percent, easeFunc, player, this, startVal));
        }
    }

    public function queueEaseL(step:Float, length:Float, modName:String, percent:Float, style:String, player:Int = -1, ?startVal:Float) {
        if (!schedule.exists(modName)) {
            trace('$modName is not a valid mod!');
            return;
        }
        if (player == -1) {
            queueEaseL(step, length, modName, percent, style, 0);
            queueEaseL(step, length, modName, percent, style, 1);
        } else {
            var easeFunc = Reflect.getProperty(FlxEase, style);
            if (easeFunc == null) easeFunc = FlxEase.linear;
            var stepSex = Conductor.stepToSeconds(step);
            schedule[modName].push(new EaseEvent(step, Conductor.getStep(stepSex + (length * 1000)), modName, percent, easeFunc, player, this, startVal));
        }
    }

    public function queueSet(step:Float, modName:String, percent:Float, player:Int = -1) {
        if (player == -1) {
            queueSet(step, modName, percent, 0);
            queueSet(step, modName, percent, 1);
        } else {
            if (percent == 0) removeMod(modName);
            else schedule[modName].push(new SetEvent(step, modName, percent, player, this));
        }
    }

    public function queueFunc(step:Float, callback:Void->Void) {
        funcs.push(new FuncEvent(step, callback, this));
    }
}
