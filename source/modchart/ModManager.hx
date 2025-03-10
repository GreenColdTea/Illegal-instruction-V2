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
    private var schedule:Map<String, Array<ModEvent>> = [];
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
        for (r in 0...360 step 15) {
            var rad = r * Math.PI / 180;
            for (data in 0...infPath.length) {
                infPath[data].push(new Vector3(
                    FlxG.width / 2 + (FlxMath.fastSin(rad)) * 600,
                    FlxG.height / 2 + (FlxMath.fastSin(rad) * FlxMath.fastCos(rad)) * 600,
                    0
                ));
            }
        }
        defineMod("infinite", new PathModifier(this, infPath, 1850));
    }

    public function getLatest(modName:String, player:Int) {
        return schedule[modName] != null && schedule[modName].length > 0
            ? schedule[modName][schedule[modName].length - 1]
            : new ModEvent(0, modName, 0, 0, this);
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
