package;

import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxState;
import hxvlc.flixel.FlxVideoSprite;
import hxvlc.util.Handle;
import openfl.display.FPS;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;

@:nullSafety
class Intro extends MusicBeatState
{
	static final IntroVideoPH = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

	var video:Null<FlxVideoSprite>;
	var versionInfo:Null<FlxText>;

	override function create():Void
	{
		FlxG.autoPause = false;

		FlxG.mouse.visible = false;

		setupVideoAsync();

		setupUI();

		super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (video != null && video.bitmap != null)
		{
			if ((FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER #if mobile || FlxG.touches.justReleased() #end) && FlxG.save.data.seenIntro)
				video.destroy();

		}

		super.update(elapsed);
	}

	private function setupUI():Void
	{
                FlxG.save.bind('funkin', 'Intro');
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
		
		versionInfo = new FlxText(10, FlxG.height - 10, 0, 'LibVLC ${Handle.version}', 17);
		versionInfo.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		versionInfo.font = Paths.font("chaotix.ttf");
		versionInfo.active = false;
		versionInfo.alignment = JUSTIFY;
		versionInfo.antialiasing = true;
		versionInfo.y -= versionInfo.height;
		add(versionInfo);
	}

	private function setupVideoAsync():Void
	{
		Handle.initAsync(function(success:Bool):Void
		{
			if (!success)
				return;

			video = new FlxVideoSprite(0, 0);
			video.active = false;
			video.antialiasing = true;
			video.bitmap.onFormatSetup.add(function():Void
			{
				if (video.bitmap != null && video.bitmap.bitmapData != null)
				{
					final scale:Float = Math.min(FlxG.width / video.bitmap.bitmapData.width, FlxG.height / video.bitmap.bitmapData.height);

					video.setGraphicSize(video.bitmap.bitmapData.width * scale, video.bitmap.bitmapData.height * scale);
					video.updateHitbox();
					video.screenCenter();
				}
			});
			video.onEndReached.add(function() {
				video.destroy();
                                FlxG.save.data.seenIntro = true; 
                                FlxG.save.flush();
                                MusicBeatState.switchState(new TitleState());
                        });

			try
			{
				var file:String = Paths.video("II_Intro");

				if (OpenFlAssets.exists(file))
					video.load(file);
				else
					video.load(IntroVideoPH);
			}
			catch (e:Dynamic)
				video.load(IntroVideoPH);

			if (versionInfo != null)
				insert(members.indexOf(versionInfo), video);

			new FlxTimer().start(0.001, (_) -> {
                                video.play();
                        });
		});
	}
}
