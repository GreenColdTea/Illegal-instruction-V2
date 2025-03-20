package modchart.modifiers;

import flixel.math.FlxRect;
import flixel.FlxSprite;
import flixel.FlxG;
import modchart.*;
import flixel.math.FlxPoint;
import math.*;

class ReverseModifier extends Modifier {
	inline function lerp(a:Float, b:Float, c:Float) return a + (b - a) * c;

	override function getName() return 'reverse';

	public function getReverseValue(dir:Int, player:Int, ?scrolling=false) {
		var suffix = scrolling ? "Scroll" : "";
		var receptors = modMgr.receptors[player];
		var kNum = receptors.length;
		var val:Float = 0;

		if (dir >= kNum / 2) val += getSubmodPercent("split" + suffix, player);
		if ((dir % 2) == 1) val += getSubmodPercent("alternate" + suffix, player);

		var first = kNum / 4;
		var last = kNum - 1 - first;
		if (dir >= first && dir <= last) val += getSubmodPercent("cross" + suffix, player);

		if (suffix == '')
			val += getPercent(player) + getSubmodPercent("reverse" + Std.string(dir), player);
		else
			val += getSubmodPercent("reverse" + suffix, player);

		if (getSubmodPercent("unboundedReverse", player) == 0) {
			val %= 2;
			if (val > 1) val = 2 - val;
		}

		if (ClientPrefs.data.downScroll) val = 1 - val;

		return val;
	}

	public function getScrollReversePerc(dir:Int, player:Int) return getReverseValue(dir, player) * 100;

	override function updateNote(note:Note, player:Int, pos:Vector3, scale:FlxPoint) {
		if (note.isSustainNote) {
			var y = pos.y + note.offsetY;
			var revPerc = getReverseValue(note.noteData, player);
			var strumLine = modMgr.receptors[player][note.noteData];
			var hit = (strumLine.sustainReduce && note.isSustainNote && (note.mustPress || !note.ignoreNote)
				&& (!note.mustPress || (note.wasGoodHit || (note.prevNote.wasGoodHit && !note.canBeHit))));

			if (hit) {
				var center:Float = strumLine.y + Note.swagWidth * 0.5;
				var swagRect = new FlxRect(0, 0, note.frameWidth, note.frameHeight);
				if (revPerc >= 0.5) {
					if (y - note.offset.y * note.scale.y + note.height >= center) {
						swagRect.height = (center - y) / note.scale.y;
						swagRect.y = note.frameHeight - swagRect.height;
						note.clipRect = swagRect;
					}
				} else {
					if (y + note.offset.y * note.scale.y <= center) {
						swagRect.y = (center - y) / note.scale.y;
						swagRect.height -= swagRect.y;
						note.clipRect = swagRect;
					}
				}
			}
		}
	}

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite) {
		var perc = getReverseValue(data, player);
		var shift = CoolUtil.scale(perc, 0, 1, 50, FlxG.height - 150);
		var mult = CoolUtil.scale(perc, 0, 1, 1, -1);
		shift = CoolUtil.scale(getSubmodPercent("centered", player), 0, 1, shift, (FlxG.height / 2) - 56);

		pos.y = shift + (visualDiff * mult);

		// for sustain notes
		if (obj is Note) {
			var note:Note = cast obj;
			if (note.isSustainNote && perc > 0) {
				var daY = pos.y;
				var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
				var songSpeed:Float = PlayState.instance.songSpeed * note.multSpeed;
				if (note.animation.curAnim.name.endsWith('end')) {
					daY += 10.5 * (fakeCrochet * 0.0025) * 1.5 * songSpeed + (46 * (songSpeed - 1));
					daY -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
					daY -= 19;
				}
				daY += (Note.swagWidth * 0.5) - (60.5 * (songSpeed - 1));
				daY += 27.5 * ((PlayState.SONG.bpm * 0.01) - 1) * (songSpeed - 1);
				pos.y = lerp(pos.y, daY, perc);
			}
		}

		return pos;
	}

	override function getSubmods() {
		var subMods:Array<String> = ["cross", "split", "alternate", "reverseScroll", "crossScroll", "splitScroll", "alternateScroll", "centered", "unboundedReverse"];
		for (i in 0...4) subMods.push('reverse${i}');
		return subMods;
	}
}
