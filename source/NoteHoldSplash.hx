package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;

class NoteHoldSplash extends FlxSprite {
    var splash:Bool;
    var posY:Float;
    var posXP:Float;
    var posXB:Float;
    var posXG:Float;
    var posXR:Float;

    var red:FlxSprite;
    var purple:FlxSprite;
    var blue:FlxSprite;
    var green:FlxSprite;

    public function new() {
        splash = ClientPrefs.noteSplashes;
        posY = PlayState.instance.playerStrums.members[3].y;
        
        if (splash) {
            posXP = PlayState.instance.playerStrums.members[0].x;
            posXB = PlayState.instance.playerStrums.members[1].x;
            posXG = PlayState.instance.playerStrums.members[2].x;
            posXR = PlayState.instance.playerStrums.members[3].x;

            // Create hold cover sprites
            red = createSprite("red", "holdCoverRed", posXR - 107, posY - 80, "push");
            purple = createSprite("purple", "holdCoverPurple", posXP - 107, posY - 80, "idle");
            blue = createSprite("blue", "holdCoverBlue", posXB - 107, posY - 80, "push");
            green = createSprite("green", "holdCoverGreen", posXG - 107, posY - 80, "push");

            // Hide sprites initially
            red.visible = false;
            purple.visible = false;
            blue.visible = false;
            green.visible = false;

            add(red);
            add(purple);
            add(blue);
            add(green);
        }
    }

    private function createSprite(name:String, path:String, x:Float, y:Float, anim:String):FlxSprite {
        var sprite = new FlxSprite(x, y);
        sprite.frames = Paths.getSparrowAtlas(path);
        sprite.animation.addByPrefix(anim, path, 24, false);
        sprite.animation.play(anim);
        return sprite;
    }

    public function goodNoteHit(noteData:Int, isSustainNote:Bool) {
        if (splash && isSustainNote) {
            switch (noteData) {
                case 0:
                    showEffect(purple, "idle", "byePurple");
                case 1:
                    showEffect(blue, "push", "byeBlue");
                case 2:
                    showEffect(green, "push", "byeGreen");
                case 3:
                    showEffect(red, "push", "byeRed");
            }
        }
    }

    private function showEffect(sprite:FlxSprite, anim:String, timerName:String) {
        sprite.visible = true;
        sprite.animation.play(anim);
        new FlxTimer().start(0.56, function(_) {
            sprite.visible = false;
        });
    }

    public function update(elapsed:Float) {
        var isPixel = PlayState.instance.isPixelStage;
        if (isPixel) {
            remove(red);
            remove(blue);
            remove(green);
            remove(purple);
        }

        // Update positions based on strum line lol
        for (i in 0...4) {
            var strum = PlayState.instance.playerStrums.members[i];
            switch (i) {
                case 0:
                    purple.x = strum.x - 107;
                    purple.y = strum.y - 80;
                case 1:
                    blue.x = strum.x - 107;
                    blue.y = strum.y - 80;
                case 2:
                    green.x = strum.x - 107;
                    green.y = strum.y - 80;
                case 3:
                    red.x = strum.x - 107;
                    red.y = strum.y - 80;
            }
        }
    }
}
