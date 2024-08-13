package android;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;

import android.FlxVirtualPad;
import android.FlxHitbox;

class Config {
	var save:FlxSave;

	public function new() {
		save = new FlxSave();
		save.bind("saved-controls");
	}

	public function getcontrolmode():Int {
		if (save.data.buttonsmode != null) 
			return save.data.buttonsmode[0];
		return 0;
	}

	public function setcontrolmode(mode:Int = 0):Int {
		if (save.data.buttonsmode == null) save.data.buttonsmode = new Array();
		save.data.buttonsmode[0] = mode;
		save.flush();
		return save.data.buttonsmode[0];
	}

	public function savecustom(_pad:FlxVirtualPad) {
		if (save.data.buttons == null)
		{
			save.data.buttons = new Array();
			for (buttons in _pad){
				save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
			}
		}else{
			var tempCount:Int = 0;
			for (buttons in _pad){
				save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				tempCount++;
			}
		}
		save.flush();
	}

	public function loadcustom(_pad:FlxVirtualPad):FlxVirtualPad {
		if (save.data.buttons == null) 
			return _pad;
		var tempCount:Int = 0;
		for(buttons in _pad){
			buttons.x = save.data.buttons[tempCount].x;
			buttons.y = save.data.buttons[tempCount].y;
			tempCount++;
		}	
		return _pad;
	}
}

class AndroidControls extends FlxSpriteGroup {
	public var mode:ControlsGroup = HITBOX;

	public var hbox:FlxHitbox;
	public var newhbox:FlxNewHitbox;
	public var vpad:FlxVirtualPad;

	var config:Config;

	public function new() {
		super();

		config = new Config();

		mode = getModeFromNumber(config.getcontrolmode());

		switch (mode){
			case HITBOX:
		    if(ClientPrefs.hitboxmode != 'New'){
				initControler(0);
		    }else{
		                initControler(5);
		    }
			case KEYBOARD:// nothing
				
			case VIRTUALPAD_RIGHT:
				initControler(1);
			case VIRTUALPAD_LEFT:
				initControler(2);
			case VIRTUALPAD_CUSTOM:
				initControler(3);
			case DUO:
				initControler(4);
		}
	}

	function initControler(vpadMode:Int) {
		switch (vpadMode){
			case 0:
				newhbox = new FlxNewHitbox();
			        add(newhbox);						
			case 1:
				vpad = new FlxVirtualPad(RIGHT_FULL, NONE, 0.75, ClientPrefs.globalAntialiasing);	
				add(vpad);			
			case 2:
				vpad = new FlxVirtualPad(LEFT_FULL, NONE, 0.75, ClientPrefs.globalAntialiasing);	
				add(vpad);
			case 3:
				vpad = new FlxVirtualPad(RIGHT_FULL, NONE, 0.75, ClientPrefs.globalAntialiasing);
				vpad = config.loadcustom(vpad);
				add(vpad);		
			case 4:
				vpad = new FlxVirtualPad(DUO, NONE, 0.75, ClientPrefs.globalAntialiasing);
				add(vpad);
			case 5:
			  
			default:
				newhbox = new FlxNewHitbox();
			        add(newhbox);					
		}
	}

	public static function getModeFromNumber(modeNum:Int):ControlsGroup {
		return switch (modeNum){
			case 0: 
				HITBOX;
			case 1: 
				VIRTUALPAD_RIGHT;
			case 2: 
				VIRTUALPAD_LEFT;
			case 3: 
				VIRTUALPAD_CUSTOM;
			case 4:	
				DUO;
			case 5: 
				KEYBOARD;
			default: 
				HITBOX;
		}
	}
}

enum ControlsGroup {
	HITBOX;
	VIRTUALPAD_RIGHT;
	VIRTUALPAD_LEFT;
	VIRTUALPAD_CUSTOM;
	DUO;
	KEYBOARD;
}
