package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.Assets;
import haxe.Json;

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var flipX:Bool;
}

class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;
	private static var DEFAULT_CHARACTER:String = 'duke_menu';

	public function new(x:Float, character:String = 'duke_menu', ?idleAnim:String = "IdleAnim", ?confirmAnim:String = "ConfirmAnim")
	{
		super(x);
		changeCharacter(character, idleAnim, confirmAnim);
	}

	public function changeCharacter(?character:String = 'duke_menu', ?idleAnim:String, ?confirmAnim:String) {
		if(character == null) character = '';
		if(character == this.character) return;

		this.character = character;
		antialiasing = ClientPrefs.globalAntialiasing;
		visible = true;

		var dontPlayAnim:Bool = false;
		scale.set(1, 1);
		updateHitbox();

		hasConfirmAnimation = false;
		switch(character) {
			case '':
				visible = false;
				dontPlayAnim = true;
			default:
				var characterPath:String = 'images/scenarioMenu/characters/' + character + '.png';
				var rawJson = null;

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if(!FileSystem.exists(path)) {
					path = Paths.getPreloadPath('images/scenarioMenu/characters/' + DEFAULT_CHARACTER + '.png');
				}
				rawJson = File.getContent(path);

				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if(!Assets.exists(path)) {
					path = Paths.getPreloadPath('images/scenarioMenu/characters/' + DEFAULT_CHARACTER + '.png');
				}
				rawJson = Assets.getText(path);
				#end
				
				frames = Paths.getSparrowAtlas('images/scenarioMenu/characters/${character.toLowerCase()}_menu');
				animation.addByPrefix('idle', idleAnim, 16);
				scale.set(4, 4);

				if (confirmAnim != null && confirmAnim != idleAnim) {
					animation.addByPrefix('confirm', confirmAnim, 24, false);
					if (animation.getByName('confirm') != null)
						hasConfirmAnimation = true;
				}

				flipX = false;
				animation.play('idle');
		}
	}
}
