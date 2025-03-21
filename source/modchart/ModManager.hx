// @author Nebula_Zorua

package modchart;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxG;
import math.Vector3;
import modchart.Modifier.ModifierType;
import modchart.modifiers.*;
import modchart.events.*;

class ModManager {
    public var state:PlayState;
    public var receptors:Array<Array<StrumNote>> = [[], []];
    public var timeline:EventTimeline = new EventTimeline();

    public var register:Map<String, Modifier> = [];
    public var notemodRegister:Map<String, Modifier> = [];
    public var miscmodRegister:Map<String, Modifier> = [];
    public var modArray:Array<Modifier> = [];
    public var activeMods:Array<Array<String>> = [[], []]; // by player

    public function new(state:PlayState) {
        this.state = state;
    }

    public function setReceptors() {
        for (data in 0...state.playerStrums.length) 
            receptors[0][state.playerStrums.members[data].noteData] = state.playerStrums.members[data];

        for (data in 0...state.opponentStrums.length) 
            receptors[1][state.opponentStrums.members[data].noteData] = state.opponentStrums.members[data];
    }

    public function registerDefaultModifiers()
    {
		var quickRegs:Array<Any> = [
			FlipModifier,
			ReverseModifier,
			InvertModifier,
			DrunkModifier,
			BeatModifier,
			AlphaModifier,
			ReceptorScrollModifier, 
			ScaleModifier, 
			SpiralModifier,
			ConfusionModifier, 
			OpponentModifier, 
			TransformModifier, 
			InfinitePathModifier, 
			PerspectiveModifier,
			TornadoModifier,
			AccelModifier, 
			XModifier
		];
		for (mod in quickRegs)
			quickRegister(Type.createInstance(mod, [this]));

	    quickRegister(new RotateModifier(this));
	    quickRegister(new RotateModifier(this, 'center', new Vector3((FlxG.width* 0.5) - (Note.swagWidth/2), (FlxG.height* 0.5) - Note.swagWidth/2)));
	    quickRegister(new LocalRotateModifier(this, 'local'));
	    quickRegister(new SubModifier("noteSpawnTime", this));
	    setValue("noteSpawnTime", 2000);
	    setValue("xmod", 1);
	    for(i in 0...4)
			setValue('xmod$i', 1);
    }

    inline public function quickRegister(mod:Modifier)
        registerMod(mod.getName(), mod);

    public function registerMod(modName:String, mod:Modifier) {
        if (register.exists(modName)) return;
        register.set(modName, mod);

        switch (mod.getModType()) {
            case NOTE_MOD: notemodRegister.set(modName, mod);
            case MISC_MOD: miscmodRegister.set(modName, mod);
        }

        timeline.addMod(modName);
        modArray.push(mod);
        setValue(modName, 0);
        modArray.sort((a, b) -> Std.int(a.getOrder() - b.getOrder()));
    }

    inline public function get(modName:String)
        return register.get(modName);

    public function setValue(modName:String, val:Float, player:Int = -1) {
        if (player == -1) {
            for (pN in 0...2) setValue(modName, val, pN);
            return;
        }

        var mod = register.get(modName);
        if (mod == null) return;

        mod.setValue(val, player);

        var modList = activeMods[player];
        if (!modList.contains(modName) && mod.shouldExecute(player, val)) {
            modList.push(modName);
        } else if (!mod.shouldExecute(player, val)) {
            modList.remove(modName);
        }

        modList.sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
    }

    public function update(elapsed:Float) {
        for (mod in modArray) {
            if (mod.active && mod.doesUpdate())
                mod.update(elapsed);
        }
    }

    public function updateTimeline(curStep:Float)
        timeline.update(curStep);

    inline public function getVisPos(songPos:Float=0, strumTime:Float=0, songSpeed:Float=1){
		return -(0.45 * (songPos - strumTime) * songSpeed);
    }

    public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, data:Int, player:Int, obj:FlxSprite, ?exclusions:Array<String>, ?pos:Vector3):Vector3 {
        if (!obj.active) return pos == null ? new Vector3() : pos;
        if (exclusions == null) exclusions = [];
        if (pos == null) pos = new Vector3();

        pos.x = getBaseX(data, player);
        pos.y = 50 + diff;
        pos.z = 0;

        for (name in activeMods[player]) {
            if (exclusions.contains(name)) continue;
            var mod = notemodRegister.get(name);
            if (mod != null) pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
        }
        return pos;
    }

    public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int) {
        if (!obj.active) return;

        for (name in activeMods[player]) {
            var mod = notemodRegister.get(name);
            if (mod != null) {
                if (obj is Note) mod.updateNote(beat, cast obj, pos, player);
                else if (obj is StrumNote) mod.updateReceptor(beat, cast obj, pos, player);
            }
        }

        if (obj is Note) obj.updateHitbox();
        obj.centerOrigin();
        obj.centerOffsets();
    }

    public function removeMod(modName:String, player:Int = -1) {
        if (player == -1) {
        // Remove it for both
            removeMod(modName, 0);
            removeMod(modName, 1);
        } else {
            if (activeMods[player].contains(modName)) {
                activeMods[player].remove(modName);
            }
        }
    
        if (register.exists(modName)) {
            register.remove(modName);
        }

        if (notemodRegister.exists(modName)) {
            notemodRegister.remove(modName);
        }

        if (miscmodRegister.exists(modName)) {
            miscmodRegister.remove(modName);
        }

        timeline.removeModEvents(modName);
    }

    public function queueEase(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
        if (player == -1) {
            queueEase(step, endStep, modName, percent, style, 0, startVal);
            queueEase(step, endStep, modName, percent, style, 1, startVal);
            return;
        }

        var easeFunc = Reflect.field(FlxEase, style) ?? FlxEase.linear;
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

    public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void) {
        timeline.addEvent(new StepCallbackEvent(step, endStep, callback, this));
    }

    public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void) {
        timeline.addEvent(new CallbackEvent(step, callback, this));
    }

    public function getBaseX(direction:Int, player:Int):Float {
        var x = (FlxG.width * 0.5) - Note.swagWidth - 54 + Note.swagWidth * direction;
        if (player == 0) x += FlxG.width * 0.5 - Note.swagWidth * 2 - 100;
        else if (player == 1) x -= FlxG.width * 0.5 - Note.swagWidth * 2 - 100;
        return x - 56;
    }
}
