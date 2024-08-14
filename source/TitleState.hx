package;

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
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
import lime.utils.Assets as LimeAssets;
import haxe.ValueException;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	var easterEggKeys:Array<String> = [
		'SHADOW', 'RIVER', 'SHUBS', 'BBPANZU'
	];
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	var mustUpdate:Bool = false;
	
	var speedFactor:Float = 1.5;
	
	public static var updateVersion:String = '';

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
 
                #if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();
		
		//trace(path, FileSystem.exists(path));

		/*#if (polymod && !html5)
		if (sys.FileSystem.exists('mods/')) {
			var folders:Array<String> = [];
			for (file in sys.FileSystem.readDirectory('mods/')) {
				var path = haxe.io.Path.join(['mods/', file]);
				if (sys.FileSystem.isDirectory(path)) {
					folders.push(file);
				}
			}
			if(folders.length > 0) {
				polymod.Polymod.init({modRoot: "mods", dirs: folders});
			}
		}
		#end*/
		
		#if CHECK_FOR_UPDATES
		if(!closedState) {
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/main/gitVersion.txt");
			
			http.onData = function (data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.psychEngineVersion.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion) {
					trace('versions arent matching!');
					mustUpdate = true;
				}
			}
			
			http.onError = function (error) {
				trace('error: $error');
			}
			
			http.request();
		}
		#end

		FlxG.game.focusLostFramerate = ClientPrefs.framerate;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		super.create();

		FlxG.save.bind('funkin', 'ninjamuffin99');
		
		ClientPrefs.loadPrefs();
		
		Highscore.load();

		if(!initialized && FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
			//trace('LOADED FULLSCREEN SETTING!!');
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		/*if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {*/
			#if desktop
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add (function (exitCode) {
					DiscordClient.shutdown();
				});
			}
			#end

			// da gort check :>
			#if mobile
                        if (!LimeAssets.exists("assets/images/gort.png")) {
                            throw new ValueException("why the hell u delete gort..");
                        }
                        #else
                        if (!Paths.fileExists('images/gort.png', IMAGE)) {
                            throw new ValueException("why the hell u delete gort..");
                        }
                        #end

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		//}
		#end
	}

	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	var floorStuff:FlxSprite;
	var logoTower:FlxSprite;
	var bgStuff:FlxSprite;

	var wechniaMenu:FlxSprite;
	var dukeMenu:FlxSprite;
	var chaotixMenu:FlxSprite;
	var wechMenu:FlxSprite;
	var ashuraMenu:FlxSprite;
	var chotixMenu:FlxSprite;

	function startIntro()
	{
		if (!initialized)
		{
			/*var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
				
			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;*/

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('freakyMenu'));
			// FlxG.sound.list.add(music);
			// music.play();

			if(FlxG.sound.music == null) {
				new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
					});
			
			}
		}

		Conductor.changeBPM(160);
		persistentUpdate = true;

		bgStuff = new FlxSprite();
		bgStuff.loadGraphic(Paths.image('title/bgthing'));
		bgStuff.scale.x = 0.75;
		bgStuff.scale.y = 0.75;
		bgStuff.antialiasing = false;
		bgStuff.screenCenter();

		logoTower = new FlxSprite();
		logoTower.loadGraphic(Paths.image('title/logothing'));
		logoTower.scale.x = 0.61;
		logoTower.scale.y = 0.61;
		logoTower.antialiasing = false;
		logoTower.screenCenter();
		logoTower.y -= 42;

		floorStuff = new FlxSprite(0, 0);
		floorStuff.frames = Paths.getSparrowAtlas('title/floor');
		floorStuff.antialiasing = false;
		floorStuff.animation.addByPrefix('lol', "floor", 24, true);
		floorStuff.updateHitbox();
		floorStuff.screenCenter();

		wechniaMenu = new FlxSprite();
		wechniaMenu.frames = Paths.getSparrowAtlas('title/wechniamenu');
		wechniaMenu.antialiasing = false;
		wechniaMenu.screenCenter();
		wechniaMenu.animation.addByPrefix('idle', 'wechniamenu', 24, true);
		wechniaMenu.scale.x = 3;
		wechniaMenu.scale.y = 3;
		wechniaMenu.updateHitbox();

		chaotixMenu = new FlxSprite();
		chaotixMenu.frames = Paths.getSparrowAtlas('title/chaotixmenu');
		chaotixMenu.antialiasing = false;
		chaotixMenu.screenCenter();
		chaotixMenu.animation.addByPrefix('idle', 'chaotixmenu', 25, true);
		chaotixMenu.scale.x = 3;
		chaotixMenu.scale.y = 3;
		chaotixMenu.x -= 250;
		chaotixMenu.y += 25;
		chaotixMenu.updateHitbox();

		wechMenu = new FlxSprite();
		wechMenu.frames = Paths.getSparrowAtlas('title/wechmenu');
		wechMenu.screenCenter();
		wechMenu.antialiasing = false;
		wechMenu.scale.x = 3;
		wechMenu.scale.y = 3;
		wechMenu.x += 80;
		wechMenu.y += 25;
		wechMenu.animation.addByPrefix('idle', 'wechmenu', 25, true);
		wechMenu.updateHitbox();

		dukeMenu = new FlxSprite();
		dukeMenu.screenCenter();
		dukeMenu.scale.x = 3;
		dukeMenu.scale.y = 3;
		dukeMenu.x -= 75;
		dukeMenu.y += 50;
		dukeMenu.frames = Paths.getSparrowAtlas('title/dukemenu');
		dukeMenu.antialiasing = false;
		dukeMenu.animation.addByPrefix('idle', 'DUKEMENU', 25, true);
		dukeMenu.updateHitbox();

		ashuraMenu = new FlxSprite();
		ashuraMenu.screenCenter();
		ashuraMenu.scale.x = 3;
		ashuraMenu.scale.y = 3;
		ashuraMenu.x -= 475;
		ashuraMenu.y += 45;
		ashuraMenu.frames = Paths.getSparrowAtlas('title/ashuramenu');
		ashuraMenu.antialiasing = false;
		ashuraMenu.animation.addByPrefix('idle', 'ashuramenu', 25, true);
		ashuraMenu.updateHitbox();

		chotixMenu = new FlxSprite();
		chotixMenu.screenCenter();
		chotixMenu.scale.x = 3;
		chotixMenu.scale.y = 3;
		chotixMenu.x += 135;
		chotixMenu.y += 35;
		chotixMenu.frames = Paths.getSparrowAtlas('title/chotixmenu');
		chotixMenu.antialiasing = false;
		chotixMenu.animation.addByPrefix('idle', 'chotixmenu', 24, true);
		chotixMenu.updateHitbox();
		
		add(bgStuff);
		add(floorStuff);
		add(logoTower);

		add(wechniaMenu);
		add(chaotixMenu);
		add(wechMenu);
		add(dukeMenu);
		add(ashuraMenu);
		add(chotixMenu);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.screenCenter();
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

            FlxG.sound.play(Paths.sound('theShits'), 0, false, null, false, function()
            {
                skipIntro();
            });

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		if (wrchniaMenu != null) 
                        wechniaMenu.x = 0 + 80 * FlxMath.fastCos((currentBeat / speedFactor) * Math.PI);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		// EASTER EGG

		if (!transitioning && skippedIntro)
		{
			if(pressedEnter)
			{
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(FlxColor.PURPLE, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		/*if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}*/

		super.update(elapsed);
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		/*if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					#if PSYCH_WATERMARKS
					createCoolText(['Psych Engine by'], 15);
					#else
					createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
					#end
				// credTextShit.visible = true;
				case 3:
					#if PSYCH_WATERMARKS
					addMoreText('Shadow Mario', 15);
					addMoreText('RiverOaken', 15);
					addMoreText('shubs', 15);
					#else
					addMoreText('present');
					#end
				// credTextShit.text += '\npresent...';
				// credTextShit.addText();
				case 4:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = 'In association \nwith';
				// credTextShit.screenCenter();
				case 5:
					#if PSYCH_WATERMARKS
					createCoolText(['Not associated', 'with'], -40);
					#else
					createCoolText(['In association', 'with'], -40);
					#end
				case 7:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				// credTextShit.text += '\nNewgrounds';
				case 8:
					deleteCoolText();
					ngSpr.visible = false;
				// credTextShit.visible = false;

				// credTextShit.text = 'Shoutouts Tom Fulp';
				// credTextShit.screenCenter();
				case 9:
					createCoolText([curWacky[0]]);
				// credTextShit.visible = true;
				case 11:
					addMoreText(curWacky[1]);
				// credTextShit.text += '\nlmao';
				case 12:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = "Friday";
				// credTextShit.screenCenter();
				case 13:
					addMoreText('Friday');
				// credTextShit.visible = true;
				case 14:
					addMoreText('Night');
				// credTextShit.text += '\nNight';
				case 15:
					addMoreText('Funkin'); // credTextShit.text += '\nFunkin';

				case 16:
					skipIntro();
			}
		}*/
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
				remove(ngSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.PURPLE, 4);
				floorStuff.animation.play('lol');
			        wechniaMenu.animation.play('idle');
			        chaotixMenu.animation.play('idle');
			        wechMenu.animation.play('idle');
			        dukeMenu.animation.play('idle');
			        ashuraMenu.animation.play('idle');
			        chotixMenu.animation.play('idle');
			        skippedIntro = true;
		}
	}
}
