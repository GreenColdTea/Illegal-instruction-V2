package modchart.modifiers;
import ui.*;
import modchart.*;
import flixel.math.FlxMath;
import flixel.FlxG;
import math.*;
import math.CoolMath;

class DrunkModifier extends Modifier {

  inline function adjust(axis:String, val:Float, plr:Int):Float {
    if ((axis.startsWith("Z") || axis.startsWith("TanZ")) && getModPercent("legacyZAxis", plr) > 0)
      return val / 1280;
    return val;
  }

  inline function applyDrunk(axis:String, player:Int, time:Float, visualDiff:Float, data:Float, ?mathFunc:Float->Float) {
    if (mathFunc == null) mathFunc = FlxMath.fastCos;
    var perc = axis == '' ? getPercent(player) : getSubmodPercent('drunk${axis}', player);
    var speed = getSubmodPercent('drunk${axis}Speed', player);
    var period = getSubmodPercent('drunk${axis}Period', player);
    var offset = getSubmodPercent('drunk${axis}Offset', player);

    if (perc != 0) {
      var angle = time * (1 + speed) + data * ((offset * 0.2) + 0.2) + visualDiff * ((period * 10) + 10) / FlxG.height;
      return adjust(axis, perc * (mathFunc(angle) * Note.swagWidth * 0.5), player);
    }
    return 0;
  }

  inline function applyTipsy(axis:String, player:Int, time:Float, visualDiff:Float, data:Float, ?mathFunc:Float->Float) {
    if (mathFunc == null) mathFunc = FlxMath.fastCos;
    var perc = getSubmodPercent('tipsy${axis}', player);
    var speed = getSubmodPercent('tipsy${axis}Speed', player);
    var offset = getSubmodPercent('tipsy${axis}Offset', player);

    if (perc != 0)
      return adjust(axis, perc * (mathFunc((time * ((speed * 1.2) + 1.2) + data * ((offset * 1.8) + 1.8))) * Note.swagWidth * 0.4), player);

    return 0;
  }

  inline function applyBumpy(axis:String, player:Int, time:Float, visualDiff:Float, data:Float, ?mathFunc:Float->Float) {
    if (mathFunc == null) mathFunc = FlxMath.fastSin;
    var perc = getSubmodPercent('bumpy${axis}', player);
    var period = getSubmodPercent('bumpy${axis}Period', player);
    var offset = getSubmodPercent('bumpy${axis}Offset', player);

    if (perc != 0 && period != -1) {
      var angle = (visualDiff + (100.0 * offset)) / ((period * 24.0) + 24.0);
      return adjust(axis, perc * 40 * mathFunc(angle), player);
    }
    return 0;
  }

  override function getPath(visualDiff:Float, pos:Vector3, data:Int, player:Int, timeDiff:Float) {
    var time = (Conductor.songPosition / 1000) * getModPercent("waveTimeFactor", player);

    pos.x += applyDrunk("", player, time, visualDiff, data) + applyTipsy("X", player, time, visualDiff, data) + applyBumpy("X", player, time, visualDiff, data);
    pos.y += applyDrunk("Y", player, time, visualDiff, data) + applyTipsy("", player, time, visualDiff, data) + applyBumpy("Y", player, time, visualDiff, data);
    pos.z += applyDrunk("Z", player, time, visualDiff, data) + applyTipsy("Z", player, time, visualDiff, data) + applyBumpy("", player, time, visualDiff, data);

    // for other collons (lane-specific)
    pos.x += applyDrunk('$data', player, time, visualDiff, data) + applyTipsy('X$data', player, time, visualDiff, data) + applyBumpy('X$data', player, time, visualDiff, data);
    pos.y += applyDrunk('Y$data', player, time, visualDiff, data) + applyTipsy('$data', player, time, visualDiff, data) + applyBumpy('Y$data', player, time, visualDiff, data);
    pos.z += applyDrunk('Z$data', player, time, visualDiff, data) + applyTipsy('Z$data', player, time, visualDiff, data) + applyBumpy('$data', player, time, visualDiff, data);

    // Tangents effects
    pos.x += applyDrunk("Tan", player, time, visualDiff, data, CoolMath.fastTan) + applyTipsy("TanX", player, time, visualDiff, data, CoolMath.fastTan) + applyBumpy("TanX", player, time, visualDiff, data, CoolMath.fastTan);
    pos.y += applyDrunk("TanY", player, time, visualDiff, data, CoolMath.fastTan) + applyTipsy("Tan", player, time, visualDiff, data, CoolMath.fastTan) + applyBumpy("TanY", player, time, visualDiff, data, CoolMath.fastTan);
    pos.z += applyDrunk("TanZ", player, time, visualDiff, data, CoolMath.fastTan) + applyTipsy("TanZ", player, time, visualDiff, data, CoolMath.fastTan) + applyBumpy("Tan", player, time, visualDiff, data, CoolMath.fastTan);

    return pos;
  }

  override function getSubmods() {
    var axes = ["X", "Y", "Z"];
    var props = [
      ["Speed", "Offset", "Period"],
      ["Speed", "Offset"],
      ["Offset", "Period"],
      ["Speed", "Offset", "Period"],
      ["Speed", "Offset"],
      ["Offset", "Period"]
    ];

    var modNames = ["drunk", "tipsy", "bumpy", "drunkTan", "tipsyTan", "bumpyTan"];
    var submods:Array<String> = [];

    for (i in 0...modNames.length) {
      var mod = modNames[i];
      for (a in 0...axes.length) {
        var axe = axes[a];
        if (a == (i % axes.length)) axe = '';
        submods.push('$mod$axe');
        var p = props[i];
        for (prop in p) submods.push('$mod$axe$prop');

        for (d in 0...PlayState.keyCount) {
          submods.push('$mod$axe$d');
          for (prop in p) submods.push('$mod$axe$d$prop');
        }
      }
    }

    submods.remove("drunk");
    return submods;
  }

  override function getAliases() {
    return [
      "tipZ" => "tipsyZ",
      "tipZSpeed" => "tipsyZSpeed",
      "tipZOffset" => "tipsyZOffset"
    ];
  }
}
