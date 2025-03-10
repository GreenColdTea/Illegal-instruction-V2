package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import shaders.ColorSwap;

class NoteHoldSplash {
    
    private var holdfolders:String = "holdCover";
    private var notedatas:Array<String> = ["Purple", "Blue", "Green", "Red"];
    
    private var holdSprites:Map<String, FlxSprite> = [];
    private var holdEndSprites:Map<String, FlxSprite> = [];
    private var visiblehold:Array<Bool> = [false, false, false, false];
    private var oppovisiblehold:Array<Bool> = [false, false, false, false];

    private var holdOffsets = { x: -110, y: -93 };
    private var holdEndOffsets = { x: -110, y: -93 };

    public function new() {
        if (PlayState.instance == null || !ClientPrefs.noteSplashes) return;

        for (i in 0...notedatas.length) {
            var name = notedatas[i];
            var sprite = createAnimatedSprite("holdCoverEnd" + name, holdfolders + name, -2000, -2000, "holdend", i);
            sprite.visible = false;
            holdEndSprites.set(name, sprite);
            FlxG.state.add(sprite);
        }
    }

    private function createAnimatedSprite(name:String, path:String, x:Float, y:Float, anim:String, noteData:Int):FlxSprite {
        var sprite = new FlxSprite(x, y);
        sprite.frames = Paths.getSparrowAtlas(path, "shared");
        sprite.animation.addByPrefix(anim, "holdCoverEnd" + name, 24, false);
        sprite.animation.play(anim);
        sprite.setGraphicSize(Std.int(sprite.width * 0.8));
        sprite.updateHitbox();
        sprite.scrollFactor.set();

        var colorSwap = new ColorSwap();
        colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
        colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
        colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
        sprite.shader = colorSwap.shader;
        
        return sprite;
    }

    public function goodNoteHit(id:Int, direction:Int, noteType:String, isSustainNote:Bool) {
        if (!isSustainNote || !ClientPrefs.noteSplashes) return;

        var strums = PlayState.instance.playerStrums.members;
        if (strums == null || direction >= strums.length) return;

        var posX = strums[direction].x;
        var posY = strums[direction].y;
        var noteName = notedatas[direction];

        var sprite = holdSprites.get(noteName);
        if (PlayState.instance.notes.members[id].animation.curAnim.name.toLowerCase().indexOf("end") != -1) {
            visiblehold[direction] = false;
            if (sprite != null) sprite.visible = false;

            var holdEndSprite = holdEndSprites.get(noteName);
            if (holdEndSprite != null) {
                holdEndSprite.setPosition(posX + holdEndOffsets.x, posY + holdEndOffsets.y);
                holdEndSprite.visible = true;
                holdEndSprite.animation.play("holdend");

                new FlxTimer().start(0.56, function(_) {
                    holdEndSprite.visible = false;
                });
            }
        } else {
            if (!visiblehold[direction]) {
                visiblehold[direction] = true;

                if (sprite == null) {
                    sprite = createAnimatedSprite("holdCover" + noteName, holdfolders + noteName, posX + holdOffsets.x, posY + holdOffsets.y, "hold", direction);
                    sprite.visible = true;
                    holdSprites.set(noteName, sprite);
                    FlxG.state.add(sprite);
                }
                
                sprite.setPosition(posX + holdOffsets.x, posY + holdOffsets.y);
                sprite.visible = true;
                sprite.animation.play("hold");
            }
        }
    }

    public function opponentNoteHit(id:Int, direction:Int, noteType:String, isSustainNote:Bool) {
        if (!isSustainNote || !ClientPrefs.noteSplashes) return;

        var strums = PlayState.instance.opponentStrums.members;
        if (strums == null || direction >= strums.length) return;

        var posX = strums[direction].x;
        var posY = strums[direction].y;
        var noteName = notedatas[direction];

        if (PlayState.instance.notes.members[id].animation.curAnim.name.toLowerCase().indexOf("end") != -1) {
            oppovisiblehold[direction] = false;
            var sprite = holdSprites.get("OppoHoldCover" + noteName);
            if (sprite != null) sprite.visible = false;
        } else {
            var sprite = holdSprites.get("OppoHoldCover" + noteName);
            if (sprite == null) {
                sprite = createAnimatedSprite("OppoHoldCover" + noteName, holdfolders + noteName, posX + holdOffsets.x, posY + holdOffsets.y, "hold", direction);
                sprite.visible = true;
                holdSprites.set("OppoHoldCover" + noteName, sprite);
            }

            sprite.setPosition(posX + holdOffsets.x, posY + holdOffsets.y);
            sprite.visible = true;
            sprite.animation.play("hold");
        }
    }

    public function update(elapsed:Float) {

        if (!ClientPrefs.noteSplashes) return;

        var strums = PlayState.instance.playerStrums.members;
        if (strums == null || strums.length < 4) return;

        for (i in 0...notedatas.length) {
            var noteName = notedatas[i];
            var sprite = holdSprites.get(noteName);
            if (sprite != null) {
                sprite.setPosition(strums[i].x + holdOffsets.x, strums[i].y + holdOffsets.y);
            }
        }
    }
}
