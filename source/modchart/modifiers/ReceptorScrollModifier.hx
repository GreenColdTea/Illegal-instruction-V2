package modchart.modifiers;

import flixel.math.FlxPoint;
import flixel.FlxG;
import modchart.*;
import math.*;

class ReceptorScrollModifier extends Modifier {
	inline function lerp(a:Float, b:Float, c:Float) {
		return a + (b - a) * c;
	}

	var moveSpeed:Float = Conductor.crochet * 3;

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite) {
		var diff = timeDiff;
		var sPos = Conductor.songPosition;
		var vDiff = -(-diff - sPos) / moveSpeed;
		var reversed = Math.floor(vDiff) % 2 == 0;

		var startY = pos.y;
		var revPerc = reversed ? 1 - vDiff % 1 : vDiff % 1;

		var upscrollOffset = 50;
		var downscrollOffset = FlxG.height - 150;

		var endY = upscrollOffset + ((downscrollOffset - Note.swagWidth / 2) * revPerc);

		pos.y = lerp(startY, endY, getPercent(player));
		return pos;
	}

	override function updateNote(note:Note, player:Int, pos:Vector3, scale:FlxPoint) {
		if (getPercent(player) == 0) return;

		var speed = PlayState.instance.songSpeed * note.multSpeed;
		var timeDiff = (note.strumTime - Conductor.songPosition);

		var diff = timeDiff;
		var sPos = Conductor.songPosition;

		var songPos = sPos / moveSpeed;
		var notePos = -(-diff - sPos) / moveSpeed;

		if (Math.floor(songPos) != Math.floor(notePos)) {
			note.alphaMod *= .5;
			note.zIndex++;
		}
		if (note.wasGoodHit) note.garbage = true;
	}
}
