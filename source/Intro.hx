package;

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxState;
import hxvlc.flixel.FlxVideo;
import hxvlc.util.Handle;
import openfl.display.FPS;
import openfl.utils.Assets as OpenFlAssets;
import lime.app.Application;
#if sys
import sys.FileSystem;
#end

//@:nullSafety
class Intro extends MusicBeatState
{
	static final IntroVideoPH = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

	var video:Null<FlxVideo>;
	var versionInfo:Null<FlxText>;

	override function create():Void
	{
		FlxG.autoPause = false;

		video.canSkip = false;

		FlxG.mouse.visible = false;

		setupVideoAsync();

		setupUI();

		super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (video != null)
		{
			if (FlxG.save.data.seenIntro)
				video.canSkip = true;

		}

		super.update(elapsed);
	}

	private function setupUI():Void
	{
		FlxG.save.bind('funkin', 'ninjamuffin99');
		ClientPrefs.loadPrefs();
		
                PlayerSettings.init();
		
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

		#if debug
		versionInfo = new FlxText(10, FlxG.height - 10, 0, 'LibVLC ${Handle.version}', 17);
		versionInfo.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		versionInfo.font = Paths.font("chaotix.ttf");
		versionInfo.active = false;
		versionInfo.alignment = JUSTIFY;
		versionInfo.antialiasing = true;
		versionInfo.y -= versionInfo.height;
		add(versionInfo);
		#end
	}

	private function setupVideoAsync():Void
	{
		Handle.initAsync(function(success:Bool):Void
		{
			if (!success)
				return;

			video = new FlxVideo();
			video.smoothing = true;
			#if mobile
			video.onFormatSetup.add(function():Void
			{
				if (video != null)
				{
					FlxG.scaleMode = new MobileScaleMode();
				}
			});
			#end
			video.finishCallback = function() {
				video.dispose();
				FlxG.removeChild(video);
                                FlxG.save.data.seenIntro = true; 
                                FlxG.save.flush();
                                MusicBeatState.switchState(new TitleState());
                        };
			FlxG.addChildBelowMouse(video);

			try
			{
				var file:String = Paths.video("II_Intro");
				video.load(file);
			}
			catch (e:Dynamic)
				video.load(IntroVideoPH);

			new FlxTimer().start(0.001, (_) -> {
                                video.play();
                        });
		});
	}
}
