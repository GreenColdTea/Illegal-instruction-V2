package;

import flixel.group.FlxSpriteGroup;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.system.FlxSound;
import openfl.media.Sound;
import openfl.text.TextFormat;
import flixel.text.FlxText;
import StringTools;

class Alphabet extends FlxSpriteGroup {
	
    // Chaotix font
	@:font("assets/fonts/chaotix.ttf")
    public static var ChaotixFont:String;

	// typing config
	public var delay:Float = 0.05;
	public var paused:Bool = false;
	
	// for position
	public var forceX:Float = Math.NEGATIVE_INFINITY;
	public var targetY:Float = 0;
	public var yMult:Float = 120;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var isMenuItem:Bool = false;
	public var textSize:Float = 1.0;

	public var text:String = "";
	var _finalText:String = "";
	var yMulti:Float = 1;
	
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;
	var splitWords:Array<String> = [];
	
	public var isBold:Bool = false;
	public var textFont:String = "chaotix.ttf";
	public var lettersArray:Array<AlphaCharacter> = [];
	
	public var finishedText:Bool = false;
	public var typed:Bool = false;
	public var typingSpeed:Float = 0.05;
	
	/**
	 * Constructor
	 * @param x          X position
	 * @param y          Y position
	 * @param text       The text to display
	 * @param bold       If true, bold font is used
	 * @param typed      If true, typing effect is applied (letter by letter)
	 * @param typingSpeed Speed of the typing effect
	 * @param textSize   Text scale (base size is 42)
	 */
	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, ?typingSpeed:Float = 0.05, ?textSize:Float = 1) {
		super(x, y);
		forceX = Math.NEGATIVE_INFINITY;
		this.textSize = textSize;
		_finalText = text;
		this.text = text;
		this.typed = typed;
		isBold = bold;
		
		if (text != "") {
			if (typed) {
				startTypedText(typingSpeed);
			} else {
				addText();
			}
		} else {
			finishedText = true;
		}
	}
	
	// Text changing
	public function changeText(newText:String, newTypingSpeed:Float = -1):Void {
		for(letter in lettersArray) {
			letter.kill();
			remove(letter);
		}
		lettersArray = [];
		splitWords = [];
		loopNum = 0;
		xPos = 0;
		curRow = 0;
		consecutiveSpaces = 0;
		xPosResetted = false;
		finishedText = false;
		lastSprite = null;
		
		var lastX = x;
		x = 0;
		_finalText = newText;
		text = newText;
		if(newTypingSpeed != -1) {
			typingSpeed = newTypingSpeed;
		}
		
		if (text != "") {
			if (typed) {
				startTypedText(typingSpeed);
			} else {
				addText();
			}
		} else {
			finishedText = true;
		}
		x = lastX;
	}
	
	public function addText():Void {
		doSplitWords();
		
		var xPos:Float = 0;
		var spacing:Float = 20 * textSize;
		
		for (character in splitWords) {
			if (character == " ") { 
				xPos += spacing;
				continue; 
			}
			
			var letter:AlphaCharacter = new AlphaCharacter(xPos, 0, character, textSize, isBold, textFont);
			// null object reference fuck
			if (PlayState.SONG != null && PlayState.SONG.song != null && PlayState.SONG.song.toLowerCase() == "found-you-legacy") {
                                textFont = "sonic-cd-menu-font.ttf";
			}
			add(letter);
			lettersArray.push(letter);
			
			xPos += letter.width + 2;
		}
	}
	
	
	
	function doSplitWords():Void {
		splitWords = _finalText.split("");
	}
	
	var loopNum:Int = 0;
	var xPos:Float = 0;
	public var curRow:Int = 0;
	var dialogueSound:FlxSound = null;
	private static var soundDialog:Sound = null;
	var consecutiveSpaces:Int = 0;
	
	public static function setDialogueSound(name:String = ""):Void {
		if(name == null || StringTools.trim(name) == "") name = "dialogue";
	}
	
	var typeTimer:FlxTimer = null;
	
	// typing effect
	public function startTypedText(speed:Float):Void {
		_finalText = text;
		doSplitWords();
		
		if(soundDialog == null) {
			Alphabet.setDialogueSound();
		}
		
		if(speed <= 0) {
			while(!finishedText) { 
				timerCheck();
			}
			if(dialogueSound != null) dialogueSound.stop();
			dialogueSound = FlxG.sound.play(soundDialog);
		} else {
			typeTimer = new FlxTimer().start(0.1, function(tmr:FlxTimer):Void {
				typeTimer = new FlxTimer().start(speed, function(tmr:FlxTimer):Void {
					timerCheck(tmr);
				}, 0);
			});
		}
	}
	
	var LONG_TEXT_ADD:Float = -24; // for long text
	public function timerCheck(?tmr:FlxTimer = null):Void {
		var autoBreak:Bool = false;
		if ((loopNum <= splitWords.length - 2 && splitWords[loopNum] == "\\" && splitWords[loopNum+1] == "n") ||
			((autoBreak = true) && xPos >= FlxG.width * 0.65 && splitWords[loopNum] == ' ' )) {
			if(autoBreak) {
				if(tmr != null) tmr.loops -= 1;
				loopNum += 1;
			} else {
				if(tmr != null) tmr.loops -= 2;
				loopNum += 2;
			}
			yMulti += 1;
			xPosResetted = true;
			xPos = 0;
			curRow += 1;
			if(curRow == 2) y += LONG_TEXT_ADD;
		}
		
		if(loopNum < splitWords.length && splitWords[loopNum] != null) {
			var spaceChar:Bool = (splitWords[loopNum] == " " || (isBold && splitWords[loopNum] == "_"));
			if (spaceChar) {
				consecutiveSpaces++;
			}
			if (splitWords[loopNum] != " ") {
				if (lastSprite != null && !xPosResetted) {
					xPos += lastSprite.width + 3;
				} else {
					xPosResetted = false;
				}
				if (consecutiveSpaces > 0) {
					xPos += 20 * consecutiveSpaces * textSize;
				}
				consecutiveSpaces = 0;
				
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti, splitWords[loopNum], textSize, isBold);
				letter.row = curRow;
				letter.x += 90;
				
				if(tmr != null) {
					if(dialogueSound != null) dialogueSound.stop();
					dialogueSound = FlxG.sound.play(soundDialog);
				}
				
				add(letter);
				lettersArray.push(letter);
				lastSprite = letter;
			}
		}
		
		loopNum++;
		if(loopNum >= splitWords.length) {
			if(tmr != null) {
				typeTimer = null;
				tmr.cancel();
				tmr.destroy();
			}
			finishedText = true;
		}
	}
	
	override public function update(elapsed:Float):Void {
		if (isMenuItem) {
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
			var lerpVal:Float = Math.min(elapsed * 9.6, 1);
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);
			if(forceX != Math.NEGATIVE_INFINITY) {
				x = forceX;
			} else {
				x = FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal);
			}
		}
		super.update(elapsed);
	}
	
	public function killTheTimer():Void {
		if(typeTimer != null) {
			typeTimer.cancel();
			typeTimer.destroy();
		}
		typeTimer = null;
	}
}
