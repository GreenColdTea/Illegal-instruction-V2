package;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.text.TextFormat;
import Alphabet;

class AlphaCharacter extends FlxText {
    public var row:Int = 0;

    public function new(x:Float, y:Float, letter:String, textSize:Float, isBold:Bool, ?textFont:String = "chaotix.ttf") {
	this.textFont = textFont;
        super(x, y, 0, letter, Std.int(42 * textSize), true);
        //42 братуха, 42
	setFormat(Paths.font(textFont), Std.int(42 * textSize), FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        
        antialiasing = true;
    }
}
