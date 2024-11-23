package;

import flixel.graphics.FlxGraphic;
#if sys
import sys.FileSystem;
#end
import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import lime.app.Application;
import openfl.Assets;
import flixel.util.FlxSave;

#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0")
import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec == "2.6.1")
import hxcodec.VideoHandler;
#elseif (hxCodec == "2.6.0")
import VideoHandler;
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
        initializeSettings();

	    FlxG.mouse.visible = false;
        
        FlxG.save.bind('funkin', 'ninjamuffin99');
        if (FlxG.save.data.seenIntro == null) FlxG.save.data.seenIntro = false;

        if (FlxG.save.data.seenIntro) {
            FlxG.sound.muteKeys = TitleState.muteKeys;
            FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
            FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
        } else {
            FlxG.sound.muteKeys = [];
            FlxG.sound.volumeDownKeys = [];
            FlxG.sound.volumeUpKeys = [];
            FlxG.sound.volume = 10;
        }

        #if desktop
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add (function (exitCode) {
				DiscordClient.shutdown();
			});
		}
		#end

        var video:VideoHandler = new VideoHandler();
        #if (hxCodec >= "3.0.0")
        video.onEndReached.add(function()
        {   
            FlxG.save.data.seenIntro = true; 
            FlxG.save.flush();
            MusicBeatState.switchState(new TitleState());
        });
        video.play(Paths.video("II_Intro"));
        #else
        video.canSkip = FlxG.save.data.seenIntro;
        video.finishCallback = function()
        {
            FlxG.save.data.seenIntro = true; 
            FlxG.save.flush();
            MusicBeatState.switchState(new TitleState());
        }
        video.playVideo(Paths.video("II_Intro"));
        #end

		super.create();
        
    }

    private function initializeSettings() {
        PlayerSettings.init();
        ClientPrefs.loadPrefs();
        FlxG.game.focusLostFramerate = ClientPrefs.framerate;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
