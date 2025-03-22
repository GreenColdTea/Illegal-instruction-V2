package modchart.modifiers;

import modchart.*;
import math.*;
import flixel.FlxSprite;
import flixel.math.FlxMath;

class SpiralModifier extends NoteModifier {
	override function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite):Vector3 {
		var spiralX = getValue(player);
		var spiralY = getSubmodValue("spiralY", player);
		var spiralZ = getSubmodValue("spiralZ", player);

		if (spiralX != 0) {
			var offset = getSubmodValue("spiralXOffset", player);
			var period = getSubmodValue("spiralXPeriod", player);
			pos.x += diff * spiralX * FlxMath.fastCos((period + 1) * diff + offset);
		}

		if (spiralY != 0) {
			var offset = getSubmodValue("spiralYOffset", player);
			var period = getSubmodValue("spiralYPeriod", player);
			pos.y += diff * spiralY * FlxMath.fastSin((period + 1) * diff + offset);
		}

		if (spiralZ != 0) {
			var offset = getSubmodValue("spiralZOffset", player);
			var period = getSubmodValue("spiralZPeriod", player);
			pos.z += diff * spiralZ * FlxMath.fastSin((period + 1) * diff + offset);
		}

		var schmovinSpiralX = getSubmodValue("schmovinSpiralX", player);
		var schmovinSpiralY = getSubmodValue("schmovinSpiralY", player);
		var schmovinSpiralZ = getSubmodValue("schmovinSpiralZ", player);
		
		// Best combined with reverse 0.5 and flip 0.5
		if (schmovinSpiralX != 0) {
			var dist = getSubmodValue("schmovinSpiralXSpacing", player) * 33.5;
			var phase = ((getSubmodValue("schmovinSpiralXSpeed", player) * beat) + getSubmodValue("schmovinSpiralXOffset", player)) * Math.PI / 4;
			var radius = (-diff / 4) + (dist * (data % 4));

			pos.x += FlxMath.fastCos(-diff / Conductor.crochet * Math.PI + phase) * radius * schmovinSpiralX;
		}
		if (schmovinSpiralY != 0) {
			var dist = getSubmodValue("schmovinSpiralYSpacing", player) * 33.5;
			var phase = ((getSubmodValue("schmovinSpiralYSpeed", player) * beat) + getSubmodValue("schmovinSpiralYOffset", player)) * Math.PI / 4;
			var radius = (-diff / 4) + (dist * (data % 4));

			pos.y += FlxMath.fastSin(-diff / Conductor.crochet * Math.PI + phase) * radius * schmovinSpiralY;
		}
		if (schmovinSpiralZ != 0) {
			var dist = getSubmodValue("schmovinSpiralZSpacing", player) * 33.5;
			var phase = ((getSubmodValue("schmovinSpiralZSpeed", player) * beat) + getSubmodValue("schmovinSpiralZOffset", player)) * Math.PI / 4;
			var radius = (-diff / 4) + (dist * (data % 4));

			pos.z += FlxMath.fastSin(-diff / Conductor.crochet * Math.PI + phase) * radius * schmovinSpiralZ;
		}

		return pos;
	}

	override function getName() {
		return "spiralX";
	}

	override function getSubmods() {
		return [
			"spiralY",
			"spiralZ",
			"spiralXOffset",
			"spiralXPeriod",
			"spiralYOffset",
			"spiralYPeriod",
			"spiralZOffset",
			"spiralZPeriod",

			"schmovinSpiralX",
			"schmovinSpiralY",
			"schmovinSpiralZ",

			"schmovinSpiralXSpeed",
			"schmovinSpiralYSpeed",
			"schmovinSpiralZSpeed",

			"schmovinSpiralXOffset",
			"schmovinSpiralYOffset",
			"schmovinSpiralZOffset",

			"schmovinSpiralXSpacing",
			"schmovinSpiralYSpacing",
			"schmovinSpiralZSpacing"
		];
	}
}
