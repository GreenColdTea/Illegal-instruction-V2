// @author Nebula_Zorua
// @optimization GCN

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
    private var schedule:Map<String, Array<ModEvent>> = [];
    private var funcs:Array<FuncEvent> = [];
    private var mods:Array<Modifier> = [];

    public var state:PlayState;
    public var receptors:Array<Array<StrumNote>> = [[], []];

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
            "flip" => new FlipModifier(this),
            "invert" => new InvertModifier(this),
            "tornado" => new TornadoModifier(this),
            "drunk" => new DrunkModifier(this),
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

        var infPath:Array<Array<Vector3>> = [[], [], [], []];
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

    inline public function getList(modName:String, player:Int):Array<ModEvent> {
        return schedule.exists(modName) ? schedule[modName].filter(e -> e.player == player) : [];
    }

    inline public function getLatest(modName:String, player:Int):ModEvent {
        var list = getList(modName, player);
        return list.length > 0 ? list[list.length - 1] : new ModEvent(0, modName, 0, 0, this);
    }

    public function get(modName:String):Dynamic{
        return definedMods[modName];
    }

    inline public function getPreviousWithEvent(event:ModEvent):ModEvent {
        var list = getList(event.modName, event.player);
        var idx = list.indexOf(event);
        return (idx > 0) ? list[idx - 1] : new ModEvent(0, event.modName, 0, 0, this);
    }

    inline public function getLatestWithEvent(event:ModEvent):ModEvent {
        return getLatest(event.modName, event.player);
    }

    public function defineMod(modName:String, modifier:Modifier, defineSubmods:Bool = true) {
        if (!schedule.exists(modName)) {
            mods.push(modifier);
            schedule.set(modName, []);
            definedMods.set(modName, modifier);

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
        for (modName in schedule.keys()) {
            for (event in schedule[modName]) {
                if (!event.finished && state.curDecStep >= event.step) event.run(state.curDecStep);
            }
        }
        for (event in funcs) {
            if (!event.finished && state.curDecStep >= event.step) event.run(state.curDecStep);
        }
    }

    public function update(elapsed:Float) {
        run();
        for (mod in mods) mod.update(elapsed);
    }

    public function getPath(diff:Float, vDiff:Float, column:Int, player:Int):Vector3{
      var pos = new Vector3(state.getXPosition(diff, column, player), vDiff, 0);
      for(mod in mods){
        pos = mod.getPath(vDiff, pos, column, player, diff);
      }

      return pos;
    }

    public function getNoteScale(note:Note):FlxPoint{
      var def = note.scaleDefault;
      var scale = FlxPoint.get(def.x,def.y);
      for(mod in mods){
        scale = mod.getNoteScale(note, scale, note.noteData, note.mustPress==true?0:1);
      }
      return scale;
    }

    public function queueEase(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
        queueEvent(step, endStep, modName, percent, style, player, startVal);
    }

    public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
        queueEase(step, endStep, modName, percent / 100, style, player, startVal / 100);
	
    public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1)
	queueSet(step, modName, percent / 100, player);
	

    public function queueSet(step:Float, modName:String, percent:Float, player:Int = -1) {
        if (player == -1) {
            queueSet(step, modName, percent, 0);
            queueSet(step, modName, percent, 1);
        } else {
            schedule[modName].push(new SetEvent(step, modName, percent, player, this));
        }
    }

    private function queueEvent(step:Float, endStep:Float, modName:String, percent:Float, style:String, player:Int, ?startVal:Float) {
        if (!schedule.exists(modName)) {
            trace('$modName is not a valid mod!');
            return;
        }
        if (player == -1) {
            queueEvent(step, endStep, modName, percent, style, 0, startVal);
            queueEvent(step, endStep, modName, percent, style, 1, startVal);
        } else {
            var easeFunc = Reflect.getProperty(FlxEase, style) ?? FlxEase.linear;
            schedule[modName].push(new EaseEvent(step, endStep, modName, percent, easeFunc, player, this, startVal));
        }
    }
}
