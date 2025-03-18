// @author Nebula_Zorua
// @optimization GCT

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

class ModManager {
    private var definedMods:Map<String, Modifier> = [];
    private var timeline:EventTimeline = new EventTimeline(); // Используем вместо schedule
    private var mods:Array<Modifier> = [];

    public var state:PlayState;
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

    public function registerModifiers() {
        defineBlankMod("waveTimeFactor");
        set("waveTimeFactor", 100, 0);
        set("waveTimeFactor", 100, 1);

        var modList = [
            "reverse" => new ReverseModifier(this),
            "stealth" => new AlphaModifier(this),
            "opponentSwap" => new OpponentModifier(this),
            "scrollAngle" => new AngleModifier(this),
            "mini" => new ScaleModifier(this),
	    "bounce" => new BounceModifier(this),
            "flip" => new FlipModifier(this),
            "invert" => new InvertModifier(this),
	    "camGame" => new CamModifier(this, "gameCam", [PlayState.instance.camGame]),
	    "camHUD" => new CamModifier(this, "HudCam", [PlayState.instance.camHUD]),
            "tornado" => new TornadoModifier(this),
            "drunk" => new DrunkModifier(this),
	    "square" => new SquareModifier(this),
            "confusion" => new ConfusionModifier(this),
            "beat" => new BeatModifier(this),
            "rotateX" => new RotateModifier(this),
            "centerrotateX" => new RotateModifier(this, 'center', new Vector3(FlxG.width / 2 - Note.swagWidth / 2, FlxG.height / 2 - Note.swagWidth / 2)),
            "localrotateX" => new LocalRotateModifier(this),
            "boost" => new AccelModifier(this),
            "transformX" => new TransformModifier(this),
            "receptorScroll" => new ReceptorScrollModifier(this),
            "perspective" => new PerspectiveModifier(this)
        ];

        for (modName => mod in modList) defineMod(modName, mod);

        var r = 0;
        while (r < 360) {
            var rad = r * Math.PI / 180;
            for (data in 0...infPath.length) {
                infPath[data].push(new Vector3(
                    FlxG.width / 2 + FlxMath.fastSin(rad) * 600,
                    FlxG.height / 2 + (FlxMath.fastSin(rad) * FlxMath.fastCos(rad)) * 600, 0
                ));
            }
            r += 15;
        }
        defineMod("infinite", new PathModifier(this, infPath, 1850));
    }

    inline public function getLatest(modName:String, player:Int):ModEvent {
        return timeline.getLatest(modName, player);
    }

    public function get(modName:String):Dynamic {
        return definedMods[modName];
    }

    public function defineMod(modName:String, modifier:Modifier, defineSubmods:Bool = true) {
        if (!definedMods.exists(modName)) {
            mods.push(modifier);
            definedMods.set(modName, modifier);
            timeline.addMod(modName);

            if (defineSubmods) {
                for (name in modifier.submods.keys()) defineMod(name, modifier.submods.get(name), false);
            }
        }
    }

    inline public function removeMod(modName:String) {
        definedMods.remove(modName);
    }

    inline public function defineBlankMod(modName:String) {
        defineMod(modName, new Modifier(this), false);
    }

    inline public function exists(modName:String):Bool return definedMods.exists(modName);

    inline public function set(modName:String, percent:Float, player:Int) {
        if (exists(modName)) definedMods[modName].setPercent(percent, player);
    }

    private function run() {
        timeline.update(state.curDecStep);
    }

    public function update(elapsed:Float) {
        run();
        for (mod in mods) mod.update(elapsed);
    }

    public function updateNote(note:Note, player:Int, scale:FlxPoint, pos:Vector3) {
        for (mod in mods) mod.updateNote(note, player, pos, scale);
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

    public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
        queueEase(step, endStep, modName, percent / 100, style, player, startVal / 100);
    }

    public function queueSet(step:Float, modName:String, percent:Float, player:Int = -1) {
        if (player == -1) {
            queueSet(step, modName, percent, 0);
            queueSet(step, modName, percent, 1);
        } else {
            timeline.addEvent(new SetEvent(step, modName, percent, player, this));
        }
    }

    public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1) {
        queueSet(step, modName, percent / 100, player);
    }

    public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void) {
        timeline.addEvent(new StepCallbackEvent(step, endStep, callback, this));
    }

    public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void) {
        timeline.addEvent(new CallbackEvent(step, callback, this));
    }
}
