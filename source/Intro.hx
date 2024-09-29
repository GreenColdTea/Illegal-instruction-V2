package;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
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
    }
    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (FlxG.touches.justPressed)
        {
            MusicBeatState.switchState(new TitleState());
        }
    }
}