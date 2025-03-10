package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.util.FlxTimer;
import shaders.ColorSwap;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import funkin.play.notes.Note;

class NoteHoldCover extends FlxTypedSpriteGroup<FlxSprite>
{
    static final FRAMERATE_DEFAULT:Int = 24;

    static var holdFrames:FlxFramesCollection;

    public var holdNote:Note;

    var glow:FlxSprite;
    var colorSwap:ColorSwap;

    public function new(note:Note)
    {
        super(note.x, note.y);
        this.holdNote = note;

        setup();
    }

    public static function preloadFrames():Void
    {
        holdFrames = null;
        for (direction in NoteDirection.ALL_DIRECTIONS)
        {
            var directionName = direction.colorName.toTitleCase();

            var atlas:FlxFramesCollection = Paths.getSparrowAtlas('holdCover/holdCover${directionName}', "shared");
            atlas.parent.persist = true;

            if (holdFrames != null)
                holdFrames = FlxAnimationUtil.combineFramesCollections(holdFrames, atlas);
            else
                holdFrames = atlas;
        }
    }

    function setup():Void
    {
        glow = new FlxSprite();
        add(glow);
        if (holdFrames == null) preloadFrames();
        glow.frames = holdFrames;

        for (direction in NoteDirection.ALL_DIRECTIONS)
        {
            var directionName = direction.colorName.toTitleCase();
            FlxAnimationUtil.addAtlasAnimation(glow, new AnimationData('holdCoverStart$directionName', 'holdCoverStart${directionName}0', FRAMERATE_DEFAULT, false));
            FlxAnimationUtil.addAtlasAnimation(glow, new AnimationData('holdCover$directionName', 'holdCover${directionName}0', FRAMERATE_DEFAULT, true));
            FlxAnimationUtil.addAtlasAnimation(glow, new AnimationData('holdCoverEnd$directionName', 'holdCoverEnd${directionName}0', FRAMERATE_DEFAULT, false));
        }

        glow.animation.finishCallback = this.onAnimationFinished;

        // Color swapping for custom note colors
        colorSwap = new ColorSwap();
        glow.shader = colorSwap.shader;
        updateColor();
    }

    public override function update(elapsed):Void
    {
        super.update(elapsed);
        setPosition(holdNote.x, holdNote.y);
        updateColor();
    }

    function updateColor():Void
    {
        var noteIndex = holdNote.noteData % 4;
        colorSwap.hue = ClientPrefs.arrowHSV[noteIndex][0] / 360;
        colorSwap.saturation = ClientPrefs.arrowHSV[noteIndex][1] / 100;
        colorSwap.brightness = ClientPrefs.arrowHSV[noteIndex][2] / 100;
    }

    public function playStart():Void
    {
        var direction:NoteDirection = NoteDirection.fromInt(holdNote.noteData);
        glow.animation.play('holdCoverStart${direction.colorName.toTitleCase()}');
    }

    public function playContinue():Void
    {
        var direction:NoteDirection = NoteDirection.fromInt(holdNote.noteData);
        glow.animation.play('holdCover${direction.colorName.toTitleCase()}');
    }

    public function playEnd():Void
    {
        var direction:NoteDirection = NoteDirection.fromInt(holdNote.noteData);
        glow.animation.play('holdCoverEnd${direction.colorName.toTitleCase()}');
    }

    public override function kill():Void
    {
        super.kill();
        this.visible = false;
        glow.visible = false;
    }

    public override function revive():Void
    {
        super.revive();
        this.visible = true;
        this.alpha = 1.0;
        glow.visible = true;
    }

    public function onAnimationFinished(animationName:String):Void
    {
        if (animationName.startsWith('holdCoverStart'))
            playContinue();
        else if (animationName.startsWith('holdCoverEnd'))
        {
            this.visible = false;
            this.kill();
        }
    }
}

/**
 * The direction of a note.
 * This has implicit casting set up, so you can use this as an integer.
 */
enum abstract NoteDirection(Int) from Int to Int
{
    var LEFT = 0;
    var DOWN = 1;
    var UP = 2;
    var RIGHT = 3;

    public var name(get, never):String;
    public var nameUpper(get, never):String;
    public var color(get, never):FlxColor;
    public var colorName(get, never):String;

    public static final ALL_DIRECTIONS:Array<NoteDirection> = [LEFT, DOWN, UP, RIGHT];

    @:from
    public static function fromInt(value:Int):NoteDirection
    {
        return switch (value % 4)
        {
            case 0: LEFT;
            case 1: DOWN;
            case 2: UP;
            case 3: RIGHT;
            default: LEFT;
        }
    }

    function get_name():String
    {
        return switch (abstract)
        {
            case LEFT: 'left';
            case DOWN: 'down';
            case UP: 'up';
            case RIGHT: 'right';
            default: 'unknown';
        }
    }

    function get_nameUpper():String
    {
        return abstract.name.toUpperCase();
    }

    function get_color():FlxColor
    {
        return switch (abstract)
        {
            case LEFT: FlxColor.PURPLE;
            case DOWN: FlxColor.BLUE;
            case UP: FlxColor.GREEN;
            case RIGHT: FlxColor.RED;
            default: FlxColor.WHITE;
        };
    }

    function get_colorName():String
    {
        return switch (abstract)
        {
            case LEFT: 'purple';
            case DOWN: 'blue';
            case UP: 'green';
            case RIGHT: 'red';
            default: 'unknown';
        }
    }

    public function toString():String
    {
        return abstract.name;
    }
}

/**
 * Utility class for handling animations.
 */
class FlxAnimationUtil
{
    public static function addAtlasAnimation(target:FlxSprite, anim:AnimationData)
    {
        var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
        var looped = anim.looped == null ? false : anim.looped;
        var flipX = anim.flipX == null ? false : anim.flipX;
        var flipY = anim.flipY == null ? false : anim.flipY;

        if (anim.frameIndices != null && anim.frameIndices.length > 0)
            target.animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, '', frameRate, looped, flipX, flipY);
        else
            target.animation.addByPrefix(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
    }

    public static function combineFramesCollections(a:FlxFramesCollection, b:FlxFramesCollection):FlxFramesCollection
    {
        var result:FlxFramesCollection = new FlxFramesCollection(null, ATLAS, null);
        for (frame in a.frames) result.pushFrame(frame);
        for (frame in b.frames) result.pushFrame(frame);
        return result;
    }
}
