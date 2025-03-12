// @author Nebula_Zorua
// @modified by GCT

package modchart;

import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.FlxG;
import math.Vector3;
import modchart.Modifier.ModifierType;
import modchart.modifiers.*;
import modchart.events.*;

class ModManager {
	public static var canMorchartOnLua:Bool = false;
	public function registerDefaultModifiers()
	{
		var quickRegs = [
			FlipModifier, TornadoModifier, ReverseModifier, InvertModifier, DrunkModifier,
			BeatModifier, AlphaModifier, ScaleModifier, ConfusionModifier, OpponentModifier,
			TransformModifier, InfinitePathModifier, PerspectiveModifier
		];
		for (mod in quickRegs) quickRegister(Type.createInstance(mod, [this]));

		quickRegister(new RotateModifier(this));
		quickRegister(new RotateModifier(this, 'center', new Vector3((FlxG.width / 2) - (Note.swagWidth/2), (FlxG.height / 2) - Note.swagWidth/2)));
		quickRegister(new LocalRotateModifier(this, 'local'));
		quickRegister(new SubModifier("noteSpawnTime", this));
		setValue("noteSpawnTime", 1250);

		canMorchartOnLua = true;
	}

	private var state:PlayState;
	public var receptors:Array<Array<StrumNote>> = [];
	public var timeline:EventTimeline = new EventTimeline();
	public var notemodRegister:Map<String, Modifier> = [];
	public var miscmodRegister:Map<String, Modifier> = [];
	public var register:Map<String, Modifier> = [];
	public var modArray:Array<Modifier> = [];
	public var activeMods:Array<Array<String>> = [[], []];

	inline public function quickRegister(mod:Modifier) registerMod(mod.getName(), mod);

	public function registerMod(modName:String, mod:Modifier, ?registerSubmods = true){
		register.set(modName, mod);
		switch (mod.getModType()){
			case NOTE_MOD: notemodRegister.set(modName, mod);
			case MISC_MOD: miscmodRegister.set(modName, mod);
		}
		timeline.addMod(modName);
		modArray.push(mod);

		if (registerSubmods) {
			for (name in mod.submods.keys()) quickRegister(mod.submods.get(name));
		}

		setValue(modName, 0);
		modArray.sort((a, b) -> Std.int(a.getOrder() - b.getOrder()));
	}

	inline public function get(modName:String) return register.get(modName);
	inline public function getPercent(modName:String, player:Int) return get(modName).getPercent(player);
	inline public function getValue(modName:String, player:Int) return get(modName).getValue(player);
	inline public function setPercent(modName:String, val:Float, player:Int=-1) setValue(modName, val / 100, player);

	public function setValue(modName:String, val:Float, player:Int=-1){
		if (player == -1) {
			for (pN in 0...2) setValue(modName, val, pN);
			return;
		}

		if (activeMods[player] == null) activeMods[player] = [];
		var mod = register.get(modName);
		if (mod == null) {
			PlayState.instance.addTextToDebug("Error: Modifier '" + modName + "' not found!", FlxColor.YELLOW);
			return;
		}

		mod.setValue(val, player);
		var parent = mod.parent == null ? mod : mod.parent;
		var name = parent.getName();

		if (!activeMods[player].contains(name) && mod.shouldExecute(player, val)) {
			if (mod.getName() != name) activeMods[player].push(mod.getName());
			activeMods[player].push(name);
		} else if (!mod.shouldExecute(player, val)) {
			if (parent != null) {
				for (subname => submod in parent.submods) {
					if (submod.shouldExecute(player, submod.getValue(player))) {
						activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
						return;
					}
				}
				activeMods[player].remove(parent.getName());
			} else {
				activeMods[player].remove(mod.getName());
			}
		}
		activeMods[player].sort((a, b) -> Std.int(register.get(a).getOrder() - register.get(b).getOrder()));
	}

	public function new(state:PlayState) {
		this.state = state;
	}

	public function update(elapsed:Float) {
		for (mod in modArray) {
			if (mod.active && mod.doesUpdate()) mod.update(elapsed);
		}
	}

	public function updateTimeline(curStep:Float) timeline.update(curStep);

	public function getBaseX(direction:Int, player:Int):Float {
		var x:Float = (FlxG.width / 2) - Note.swagWidth - 54 + Note.swagWidth * direction;
		if (player == 0) x += FlxG.width / 2 - Note.swagWidth * 2 - 100;
		if (player == 1) x -= FlxG.width / 2 - Note.swagWidth * 2 - 100;
		return x - 56;
	}

	public function updateObject(beat:Float, obj:FlxSprite, pos:Vector3, player:Int){
		for (name in activeMods[player]) {
			var mod = notemodRegister.get(name);
			if (mod == null || !obj.active) continue;
			if (obj is Note) mod.updateNote(beat, cast obj, pos, player);
			else if (obj is StrumNote) mod.updateReceptor(beat, cast obj, pos, player);
		}
		if (obj is Note) obj.updateHitbox();
		obj.centerOrigin();
		obj.centerOffsets();
		if (obj is Note) {
			var note = cast obj;
			note.offset.x += note.typeOffsetX;
			note.offset.y += note.typeOffsetY;
		}
	}

	inline public function getVisPos(songPos:Float = 0, strumTime:Float = 0, songSpeed:Float = 1) {
		return -(0.45 * (songPos - strumTime) * songSpeed);
	}

	public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, data:Int, player:Int, obj:FlxSprite, ?exclusions:Array<String>, ?pos:Vector3):Vector3 {
		if (exclusions == null) exclusions = [];
		if (pos == null) pos = new Vector3();
		if (!obj.active) return pos;

		pos.x = getBaseX(data, player);
		pos.y = 50 + diff;
		pos.z = 0;
		for (name in activeMods[player]) {
			if (exclusions.contains(name)) continue;
			var mod = notemodRegister.get(name);
			if (mod != null && obj.active) pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
		}
		return pos;
	}

	public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float) {
		queueEase(step, endStep, modName, percent / 100, style, player, startVal / 100);
	}

	public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1) {
		queueSet(step, modName, percent / 100, player);
	}

	public function queueEase(step:Float, endStep:Float, modName:String, target:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
	{
		if (player == -1) {
			queueEase(step, endStep, modName, target, style, 0);
			queueEase(step, endStep, modName, target, style, 1);
		} else {
			var easeFunc = FlxEase.linear;

			try
			{
				var newEase = Reflect.getProperty(FlxEase, style);
				if (newEase != null)
					easeFunc = newEase;
			}
			

			timeline.addEvent(new EaseEvent(step, endStep, modName, target, easeFunc, player, this));

		}
	}

	public function queueSet(step:Float, modName:String, target:Float, player:Int = -1)
	{
		if (player == -1)
		{
			queueSet(step, modName, target, 0);
			queueSet(step, modName, target, 1);
		}
		else
			timeline.addEvent(new SetEvent(step, modName, target, player, this));
		
	}

	public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void)
	{
		timeline.addEvent(new StepCallbackEvent(step, endStep, callback, this));
	}
    
	public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void)
	{
		timeline.addEvent(new CallbackEvent(step, callback, this));
	}

	public function randomFloat(minVal:Float, maxVal:Float):Float {
		return FlxG.random.float(minVal, maxVal);
	}
}
