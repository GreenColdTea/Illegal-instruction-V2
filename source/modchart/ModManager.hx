// @author Nebula_Zorua
// @optimization GCT

package modchart;

import modchart.modifiers.*;
import modchart.BaseEvent.*;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import math.*;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.FlxSprite;

class ModManager {
    private var definedMods:Map<String, Modifier> = [];
    private var timeline:EventTimeline = new EventTimeline();
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
        var list = getList(modName, player);
        return list.length > 0 ? list[list.length - 1] : new ModEvent(0, modName, 0, player, this);
    }

    public function get(modName:String):Dynamic {
        return definedMods[modName];
    }

    inline public function getList(modName:String, player:Int):Array<ModEvent> {
        return timeline.modEvents.exists(modName) 
            ? timeline.modEvents.get(modName).filter(e -> e.player == player) : [];
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

    public function getModPercent(modName:String, player:Int):Float {
        return get(modName).getPercent(player);
    }

    public function getPreviousWithEvent(event:ModEvent) {
        var list:Array<ModEvent> = getList(event.modName, event.player);
        var idx = list.indexOf(event);
        return (idx > 0) ? list[idx - 1] : new ModEvent(0, event.modName, 0, 0, this);
    }

    public function getLatestWithEvent(event:ModEvent) {
        return getLatest(event.modName, event.player);
    }

    inline public function exists(modName:String):Bool return definedMods.exists(modName);

    public function set(modName:String, percent:Float, player:Int = -1) {
        if (exists(modName)) definedMods[modName].setPercent(percent, player);
    }

    inline public function setValue(modName:String, percent:Float, player:Int = -1) {
        set(modName, percent, player);
    }

    public function updateTimeline(curStep:Float) {
        timeline.update(curStep);
    }

    private function run() {
        updateTimeline(state.curDecStep);
    }

    public function update(elapsed:Float) {
        run();
        for (mod in mods) mod.update(elapsed);
    }

    public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int) {
        for (mod in mods) mod.updateObject(beat, obj, pos, player);
    }

    public inline function getVisPos(songPos:Float = 0, strumTime:Float = 0, songSpeed:Float = 1) {
        return -(0.45 * (songPos - strumTime) * songSpeed);
    }

    public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, data:Int, player:Int, obj:FlxSprite, ?exclusions:Array<String>, ?pos:Vector3):Vector3 {
        if (exclusions == null) exclusions = [];
        if (pos == null) pos = new Vector3();

        if (!obj.active) return pos;

        pos.x = state.getXPosition(diff, data, player);
        pos.y = 50 + diff;
        pos.z = 0;

        for (mod in mods) {
            if (!exclusions.contains(mod.getName()))
                pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
        }
        return pos;
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

    public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void) {
        timeline.addEvent(new StepCallbackEvent(step, endStep, callback, this));
    }

    public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void) {
        timeline.addEvent(new CallbackEvent(step, callback, this));
    }
}
