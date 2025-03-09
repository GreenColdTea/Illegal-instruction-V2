package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import shaders.ColorSwap;

class NoteHoldSplash {
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

    var colorSwap:ColorSwap;

    public function new() {
        super();
        
        if (PlayState.instance == null) return;

        splash = ClientPrefs.noteSplashes;
        colorSwap = new ColorSwap();
        
        if (splash) {
            var strums = PlayState.instance.playerStrums.members;
            if (strums.length < 4) return;

            posXP = strums[0].x;
            posXB = strums[1].x;
            posXG = strums[2].x;
            posXR = strums[3].x;
            posY = strums[3].y;

            // Create hold cover sprites
            red = createSprite(Paths.getSparrowAtlas("holdCoverRed", "shared"), posXR - 107, posY - 80, "push");
            purple = createSprite(Paths.getSparrowAtlas("holdCoverPurple", "shared"), posXP - 107, posY - 80, "idle");
            blue = createSprite(Paths.getSparrowAtlas("holdCoverBlue", "shared"), posXB - 107, posY - 80, "push");
            green = createSprite(Paths.getSparrowAtlas("holdCoverGreen", "shared"), posXG - 107, posY - 80, "push");

            // Hide sprites initially
            red.visible = false;
            purple.visible = false;
            blue.visible = false;
            green.visible = false;

            FlxG.state.add(red);
            FlxG.state.add(purple);
            FlxG.state.add(blue);
            FlxG.state.add(green);
        }
    }

    private function createSprite(frames:FlxSprite, x:Float, y:Float, anim:String):FlxSprite {
        var sprite = new FlxSprite(x, y);
        sprite.frames = frames;
        sprite.animation.addByPrefix(anim, anim, 24, false);
        sprite.animation.play(anim);
        return sprite;
    }

    public function goodNoteHit(noteData:Int, isSustainNote:Bool) {
        if (splash && isSustainNote) {
            switch (noteData) {
                case 0:
                    showEffect(purple, "idle");
                case 1:
                    showEffect(blue, "push");
                case 2:
                    showEffect(green, "push");
                case 3:
                    showEffect(red, "push");
            }
        }
    }

    private function showEffect(sprite:FlxSprite, anim:String) {
        sprite.visible = true;
        sprite.animation.play(anim);
        new FlxTimer().start(0.56, function(_) {
            sprite.visible = false;
        });
    }

    public function update(elapsed:Float) {
        if (PlayState.isPixelStage) {
            FlxG.state.remove(red);
            FlxG.state.remove(blue);
            FlxG.state.remove(green);
            FlxG.state.remove(purple);
        }

        var strums = PlayState.instance.playerStrums.members;
        if (strums.length < 4) return;

        // Update sprite positions
        purple.setPosition(strums[0].x - 107, strums[0].y - 80);
        blue.setPosition(strums[1].x - 107, strums[1].y - 80);
        green.setPosition(strums[2].x - 107, strums[2].y - 80);
        red.setPosition(strums[3].x - 107, strums[3].y - 80);
    }
}
