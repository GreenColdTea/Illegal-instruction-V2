package modchart;

import flixel.math.FlxPoint;
import ui.*;
import math.*;
import Section.SwagSection;

class Modifier {
  public var modMgr:ModManager;
  public var percents:Array<Float>=[0, 0];
  public var submods:Map<String, Modifier> = [];
  public function new(modMgr:ModManager) {
    this.modMgr = modMgr;
    for(submod in getSubmods()) {
      submods.set(submod, new Modifier(modMgr));
    }
  }

  public function getSubmods():Array<String>{
      return [];
  }

  public function getMod(modName:String){
      return modMgr.get(modName);
  }

  public function getModPercent(modName:String, player:Int){
      return modMgr.getModPercent(modName,player);
  }

  //yeah, this should be here
  public function getScrollReversePerc(dir:Int, player:Int):Float {
      return 0;
  }

  public function getSubmodPercent(modName:String, player:Int) {
      if (submods.exists(modName)) {
          return submods.get(modName).getPercent(player);
      } else {
          return 0;
      }
  }

  public function setSubmodPercent(modName:String, endPercent:Float, player:Int) {
      return submods.get(modName).setPercent(endPercent, player);
  }

  public function getPercent(player:Int):Float {
      return percents[player];
  }

  public function setPercent(percent:Float, player:Int=-1) {
      if (player < 0) {
          for(idx in 0...percents.length){
              percents[idx] = percent / 100;
          }
      } else {
          percents[player] = percent / 100;
      }
  }

  public function updateNote(note:Note, player:Int, pos:Vector3, scale:FlxPoint) {}
  public function updateReceptor(receptor:StrumNote, player:Int, pos:Vector3, scale:FlxPoint) {}

  public function update(elapsed:Float){};

  public function getReceptorScale(receptor:StrumNote, scale:FlxPoint, data:Int, player:Int) return scale;
  public function getNoteScale(note:Note, scale:FlxPoint, data:Int, player:Int) return scale;

  public function getPath(visualDiff:Float, pos:Vector3, data:Int, player:Int, timeDiff:Float) return pos;

  public function getAliases():Map<String,String>{return [];}
}
