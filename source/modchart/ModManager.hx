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

// Weird amalgamation of Schmovin' modifier system, Andromeda modifier system and my own new shit -neb

class ModManager {
	public function registerDefaultModifiers()
	{
		var quickRegs:Array<Modifier> = [
			new FlipModifier(this), new ReverseModifier(this), new InvertModifier(this), 
			new DrunkModifier(this), new BeatModifier(this), new AlphaModifier(this), 
			new ScaleModifier(this), new ConfusionModifier(this), new OpponentModifier(this), 
			new TransformModifier(this), new InfinitePathModifier(this), new PerspectiveModifier(this)
		];

		for (mod in quickRegs)
			quickRegister(mod);

		quickRegister(new RotateModifier(this));
		quickRegister(new RotateModifier(this, 'center', new Vector3((FlxG.width / 2) - (Note.swagWidth/2), (FlxG.height / 2) - Note.swagWidth/2)));
		quickRegister(new LocalRotateModifier(this, 'local'));
		quickRegister(new SubModifier("noteSpawnTime", this));
		setValue("noteSpawnTime", 1250);
	}

    private var state:PlayState;
	public var receptors:Array<Array<StrumNote>> = [];
	public var timeline:EventTimeline = new EventTimeline();

	public var notemodRegister:Map<String, Modifier> = [];
	public var miscmodRegister:Map<String, Modifier> = [];
	public var register:Map<String, Modifier> = [];
	public var modArray:Array<Modifier> = [];
	public var activeMods:Array<Array<String>> = [[], []];

	inline public function quickRegister(mod:Modifier) 
		registerMod(mod.getName(), mod);

	public function registerMod(modName:String, mod:Modifier, ?registerSubmods = true) {
		register.set(modName, mod);

		switch (mod.getModType()) {
			case NOTE_MOD: notemodRegister.set(modName, mod);
			case MISC_MOD: miscmodRegister.set(modName, mod);
		}

		timeline.addMod(modName);
		modArray.push(mod);

		if (registerSubmods) {
			for (submod in mod.submods) quickRegister(submod);
		}

		setValue(modName, 0);
		modArray.sort((a, b) -> Std.int(a.getOrder() - b.getOrder()));
	}

	inline public function get(modName:String):Modifier
		return register.get(modName);

	inline public function getPercent(modName:String, player:Int):Float
		return get(modName)?.getPercent(player) ?? 0;

	inline public function getValue(modName:String, player:Int):Float
		return get(modName)?.getValue(player) ?? 0;

	inline public function setPercent(modName:String, val:Float, player:Int=-1) 
		setValue(modName, val / 100, player);

	public function setValue(modName:String, val:Float, player:Int=-1) {
		var daMod = get(modName);
		if (daMod == null) return;

		if (player == -1) {
			for (pN in 0...2) setValue(modName, val, pN);
			return;
		}

		var mod = daMod.parent ?? daMod;
		var name = mod.getName();
		var activeList = activeMods[player];

		daMod.setValue(val, player);
		var shouldExecute = mod.shouldExecute(player, val);

		if (!activeList.contains(name) && shouldExecute) {
			if (daMod.getName() != name) activeList.push(daMod.getName());
			activeList.push(name);
		} else if (!shouldExecute) {
			activeList.remove(daMod.getName());

			// Check if other submods should keep the parent active
			if (mod.submods.exists(name)) {
				for (subname => submod in mod.submods) {
					if (submod.shouldExecute(player, submod.getValue(player))) {
						activeList.sort((a, b) -> Std.int(get(a).getOrder() - get(b).getOrder()));
						return;
					}
				}
			}
			activeList.remove(mod.getName());
		}

		activeList.sort((a, b) -> Std.int(get(a).getOrder() - get(b).getOrder()));
	}

	public function new(state:PlayState) {
		this.state = state;
	}

	public function update(elapsed:Float) {
		for (mod in modArray) if (mod.active && mod.doesUpdate()) mod.update(elapsed);
	}

	public function updateTimeline(curStep:Float)
		timeline.update(curStep);

	public function getBaseX(direction:Int, player:Int):Float {
		var x = (FlxG.width / 2) - Note.swagWidth - 54 + Note.swagWidth * direction;
		return switch (player) {
			case 0: x + FlxG.width / 2 - Note.swagWidth * 2 - 100;
			case 1: x - FlxG.width / 2 + Note.swagWidth * 2 + 100;
			default: x;
		} - 56;
	}

	public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int) {
		if (!obj.active) return;

		for (name in activeMods[player]) {
			var mod = notemodRegister.get(name);
			if (mod == null) continue;

			if (obj is Note) mod.updateNote(beat, cast obj, pos, player);
			else if (obj is StrumNote) mod.updateReceptor(beat, cast obj, pos, player);
		}

		if (obj is Note) cast(obj, Note).updateHitbox();
		obj.centerOrigin();
		obj.centerOffsets();

		if (obj is Note) {
			var note:Note = cast obj;
			note.offset.x += note.typeOffsetX;
			note.offset.y += note.typeOffsetY;
		}
	}

	public inline function getVisPos(songPos:Float = 0, strumTime:Float = 0, songSpeed:Float = 1):Float
		return -(0.45 * (songPos - strumTime) * songSpeed);

	public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, data:Int, player:Int, obj:FlxSprite, ?exclusions:Array<String>, ?pos:Vector3):Vector3 {
		if (pos == null) pos = new Vector3();
		if (!obj.active) return pos;

		pos.x = getBaseX(data, player);
		pos.y = 50 + diff;
		pos.z = 0;

		for (name in activeMods[player]) {
			if (exclusions != null && exclusions.contains(name)) continue;
			var mod = notemodRegister.get(name);
			if (mod != null) pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
		}

		return pos;
	}

	public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) 
		queueEase(step, endStep, modName, percent / 100, style, player, startVal / 100);

	public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1) 
		queueSet(step, modName, percent / 100, player);

	public function queueEase(step:Float, endStep:Float, modName:String, target:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
		if (player == -1) {
			queueEase(step, endStep, modName, target, style, 0);
			queueEase(step, endStep, modName, target, style, 1);
			return;
		}
		var easeFunc = Reflect.field(FlxEase, style) ?? FlxEase.linear;
		timeline.addEvent(new EaseEvent(step, endStep, modName, target, easeFunc, player, this));
	}

	public function randomFloat(minVal:Float, maxVal:Float):Float
		return FlxG.random.float(minVal, maxVal);
}
