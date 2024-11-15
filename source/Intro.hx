package;

import flixel.graphics.FlxGraphic;
#if sys
import sys.FileSystem;
#end
import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import flixel.util.FlxSave;

#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0")
import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec == "2.6.1")
import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0")
import VideoHandler as VideoHandler;
#elseif hxvlc
import hxvlc.flixel.FlxVideo as VideoHandler;
#else
import vlc.VideoHandler;
#end
#end

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end

class Intro extends MusicBeatState
{
    override public function create()
    {
	    FlxG.mouse.visible = false;

        var save:FlxSave;

        save = new FlxSave();
        save.bind('Intro');
        if (save.data.seenIntro == null) save.data.seenIntro = false;

        if (save.data.seenIntro) {
            FlxG.sound.muteKeys = TitleState.muteKeys;
            FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
            FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
        } else {
            FlxG.sound.muteKeys = [];
            FlxG.sound.volumeDownKeys = [];
            FlxG.sound.volumeUpKeys = [];
            FlxG.sound.volume = 10;
        }

        var video:VideoHandler = new VideoHandler();
        #if (hxCodec >= "3.0.0")
        video.onEndReached.add(function()
        {   
            FlxG.save.data.seenIntro = true; 
            save.flush();
            MusicBeatState.switchState(new TitleState());
        });
        video.play(Paths.video("II_Intro"));
        #else
        video.canSkip = save.data.seenIntro;
        video.finishCallback = function()
        {
            FlxG.save.data.seenIntro = true; 
            save.flush();
            MusicBeatState.switchState(new TitleState());
        }
        video.playVideo(Paths.video("II_Intro"));
        #end

		super.create();
        
    }
    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
