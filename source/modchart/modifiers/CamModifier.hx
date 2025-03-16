package modchart.modifiers;

import modchart.*;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.FlxG;

class CamModifier extends Modifier {
  var prefix:String = "game";
  var cams:Array<FlxCamera> = [];

  public function new(modMgr:ModManager, prefix:String, ?cams:Array<FlxCamera>) {
    super(modMgr);
    if (cams == null) {
      cams = [FlxG.camera];
    }

    this.prefix = prefix;
    this.cams = cams;

    submods.set(prefix + "Pitch", new Modifier(modMgr));
    submods.set(prefix + "Yaw", new Modifier(modMgr));
    submods.set(prefix + "XOffset", new Modifier(modMgr));
    submods.set(prefix + "YOffset", new Modifier(modMgr));
    submods.set(prefix + "ScrollXOffset", new Modifier(modMgr));
    submods.set(prefix + "ScrollYOffset", new Modifier(modMgr));
    submods.set(prefix + "AngleOffset", new Modifier(modMgr));
    submods.set(prefix + "HeightOffset", new Modifier(modMgr));
    submods.set(prefix + "WidthOffset", new Modifier(modMgr));
    submods.set(prefix + "CastedHeightOffset", new Modifier(modMgr));
    submods.set(prefix + "CastedWidthOffset", new Modifier(modMgr));
  }

  override function update(elapsed:Float) {
    var pitch = getSubmodPercent(prefix + "Pitch", 0) * 100;
    var yaw = getSubmodPercent(prefix + "Yaw", 0) * 100;

    var xOffset = getSubmodPercent(prefix + "XOffset", 0) * 100;
    var yOffset = getSubmodPercent(prefix + "YOffset", 0) * 100;

    var xScrollOffset = getSubmodPercent(prefix + "ScrollXOffset", 0) * 100;
    var yScrollOffset = getSubmodPercent(prefix + "ScrollYOffset", 0) * 100;
    var angleOffset = getSubmodPercent(prefix + "AngleOffset", 0) * 100;

    for (camera in cams) {
      if (camera == null) continue;

      camera.angle = angleOffset;
      camera.x += xOffset;
      camera.y += yOffset;

      camera.scroll.x += xScrollOffset;
      camera.scroll.y += yScrollOffset;

      camera.height = Math.floor(FlxG.height + getSubmodPercent(prefix + "HeightOffset", 0) * 100);
      camera.width = Math.floor(FlxG.width + getSubmodPercent(prefix + "WidthOffset", 0) * 100);

      camera.height = Math.floor(camera.height + getSubmodPercent(prefix + "CastedHeightOffset", 0) * 100);
      camera.width = Math.floor(camera.width + getSubmodPercent(prefix + "CastedWidthOffset", 0) * 100);
    }
  }
}
