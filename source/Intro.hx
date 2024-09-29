package;

import flixel.graphics.FlxGraphic;
import sys.FileSystem;
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
import hxcodec.VideoHandler;
#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end

class Intro extends MusicBeatState
{
    override public function create()
    {
	FlxG.mouse.visible = false;
	FlxG.sound.volume = 10;

        FlxG.sound.muteKeys = [];
        FlxG.sound.volumeDownKeys = [];
        FlxG.sound.volumeUpKeys = [];
        
        var video = new VideoHandler();
        video.canSkip = true;
        video.finishCallback = function()
        {
            FlxG.sound.muteKeys = TitleState.muteKeys;
            FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
            FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;    
            MusicBeatState.switchState(new TitleState());
        }
        video.playVideo(Paths.video('II_Intro'));
	#if android
	addVirtualPad(NONE, NONE);
	#end
    }
    override public function update(elapsed:Float)
    {
        super.update(elapsed);

	#if mobile
        for (touch in FlxG.touches.list)
	{
	    if (touch.justPressed)
	    {
                LoadingState.loadAndSwitchState(new TitleState());
	    }
        }
	#end
    }
}
