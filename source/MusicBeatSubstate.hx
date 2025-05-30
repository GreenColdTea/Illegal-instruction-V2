package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;
#if mobile
import mobile.flixel.FlxHitbox;
import mobile.flixel.FlxVirtualPad;
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if mobile
	var hitbox:FlxHitbox;
	var _virtualpad:FlxVirtualPad;
	var trackedInputsHitbox:Array<FlxActionInput> = [];
	var trackedInputsVirtualPad:Array<FlxActionInput> = [];

	var hitboxDiff:Dynamic;

	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		if (_virtualpad != null)
			removeVirtualPad();

		_virtualpad = new FlxVirtualPad(DPad, Action);
		add(_virtualpad);

		controls.setVirtualPadUI(_virtualpad, DPad, Action);
		trackedInputsVirtualPad = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
	}

	public function removeVirtualPad()
	{
		if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);

		if (_virtualpad != null)
			remove(_virtualpad);
	}

	public function addVirtualPadCamera(DefaultDrawTarget:Bool = true)
	{
		if (_virtualpad != null)
		{
			var camControls:FlxCamera = new FlxCamera();
			FlxG.cameras.add(camControls, DefaultDrawTarget);
			camControls.bgColor.alpha = 0;
			_virtualpad.cameras = [camControls];
		}
	}

	public function addHitbox(?usesDodge = false):Void
	{
		if (hitbox != null)
			removeHitbox();

		if (hitbox != null)
			removeHitbox();

		if (usesDodge) {
			hitbox = new FlxHitbox(SPACE);
			hitbox.visible = visible;
			add(hitbox);
			hitboxDiff = SPACE;
		} else {
			hitbox = new FlxHitbox(DEFAULT);
			hitbox.visible = visible;
			hitboxDiff = DEFAULT;
		}

		controls.setHitBox(hitbox, hitboxDiff);
		trackedInputsHitbox = controls.trackedInputsNOTES;
		controls.trackedInputsNOTES = [];
	}

	public function addHitboxCamera(DefaultDrawTarget:Bool = true):Void
	{
		if (hitbox != null)
		{
			var camControls:FlxCamera = new FlxCamera();
			FlxG.cameras.add(camControls, DefaultDrawTarget);
			camControls.bgColor.alpha = 0;
			hitbox.cameras = [camControls];
		}
	}

	public function removeHitbox():Void
	{
		if (trackedInputsHitbox.length > 0)
			controls.removeVirtualControlsInput(trackedInputsHitbox);

		if (hitbox != null)
			remove(hitbox);
	}
	#end

	override function destroy()
	{
		#if mobile
		if (trackedInputsHitbox.length > 0)
			controls.removeVirtualControlsInput(trackedInputsHitbox);

		if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);
		#end

		super.destroy();

		#if mobile
		if (_virtualpad != null)
			_virtualpad = FlxDestroyUtil.destroy(_virtualpad);
		if (hitbox != null)
			hitbox = FlxDestroyUtil.destroy(hitbox);
		#end
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();


		super.update(elapsed);
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function onFocusGained():Void
	{
		
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
