package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxBasic;
import openfl.utils.Assets;
import openfl.system.System;
import openfl.Lib;
import lime.app.Application;
import flixel.system.scaleModes.RatioScaleMode;
import sys.FileSystem;
#if mobile
import mobile.MobileControls;
import mobile.flixel.FlxVirtualPad;
import mobile.flixel.FlxHitbox;
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if mobile
	var mobileControls:MobileControls;
	var _virtualpad:FlxVirtualPad;
	var hitbox:FlxHitbox;
	var trackedInputsHitbox:Array<FlxActionInput> = [];
	var trackedInputsMobileControls:Array<FlxActionInput> = [];
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

	public function addMobileControls(usesDodge:Bool = false, DefaultDrawTarget:Bool = true)
	{
		if (mobileControls != null)
			removeMobileControls();

		mobileControls = new MobileControls(usesDodge);

		switch (MobileControls.mode)
		{
			case 'Pad-Right' | 'Pad-Left' | 'Pad-Custom':
				controls.setVirtualPadNOTES(mobileControls._virtualpad, RIGHT_FULL, NONE);
			case 'Pad-Duo':
				controls.setVirtualPadNOTES(mobileControls._virtualpad, BOTH_FULL, NONE);
			case 'Hitbox':
			if (usesDodge) {
				controls.setHitBox(mobileControls.hitbox, SPACE);
			} else {
			  controls.setHitBox(mobileControls.hitbox, DEFAULT);
			}
				
			case 'Keyboard': // do nothing
		}

		trackedInputsMobileControls = controls.trackedInputsNOTES;
		controls.trackedInputsNOTES = [];

		var camControls:FlxCamera = new FlxCamera();
		FlxG.cameras.add(camControls, DefaultDrawTarget);
		camControls.bgColor.alpha = 0;

		mobileControls.cameras = [camControls];
		mobileControls.visible = false;
		add(mobileControls);
	}

	public function removeMobileControls()
	{
		if (trackedInputsMobileControls.length > 0)
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

		if (mobileControls != null)
			remove(mobileControls);
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

		if (trackedInputsMobileControls.length > 0)
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

		if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);
		#end

		super.destroy();

		#if mobile
		if (_virtualpad != null)
			_virtualpad = FlxDestroyUtil.destroy(_virtualpad);

		if (mobileControls != null)
			mobileControls = FlxDestroyUtil.destroy(mobileControls);

		if (hitbox != null)
			hitbox = FlxDestroyUtil.destroy(hitbox);
		#end
	}

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		if (!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}

		#if !MODS_ALLOWED
		if (!Assets.exists("assets/images/gort.png")) {
            Application.current.window.alert("Critical Error: Where's my gort YOU FUCKING BASTARD!!!", "Duke");
            System.exit(1);
		}
		#else
		if (!FileSystem.exists("assets/images/gort.png")) {
		    Application.current.window.alert("Critical Error: Where's my gort YOU FUCKING BASTARD!!!", "Duke");
            System.exit(1);
		}
		#end

		FlxTransitionableState.skipNextTransOut = false;

		super.create();

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

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / Conductor.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
				//trace('resetted');
			} else {
				CustomFadeTransition.finishCallback = function() {
					FlxG.switchState(nextState);
				};
				//trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState() {
		FlxG.resetState();
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
