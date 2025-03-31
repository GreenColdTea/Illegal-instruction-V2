package;

import editors.ChartingState;
import editors.CharacterEditorState;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.effects.FlxFlicker;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.addons.plugin.screengrab.FlxScreenGrab;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import flixel.util.FlxSave;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.Shader;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import Section.SwagSection;
import Song.SwagSong;
import Shaders;
import shaders.GlitchShader.Fuck;
import shaders.GlitchShader.GlitchShaderA;
import shaders.GlitchShader.GlitchShaderB;
import shaders.*;
import modchart.*;

import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;

import WiggleEffect.WiggleEffectType;

#if mobile
import mobile.MobileControls;
#end

#if sys
import sys.FileSystem;
#end
	
import SonicNumber.SonicNumberDisplay;

#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0")
import hxcodec.flixel.FlxVideo as MP4Handler;
#elseif (hxCodec == "2.6.1")
import hxcodec.VideoHandler as MP4Handler;
#elseif (hxCodec == "2.6.0")
import VideoHandler as MP4Handler;
#elseif hxvlc
import hxvlc.flixel.FlxVideo as MP4Handler;
#else
import vlc.MP4Handler;
#end
#end

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

using StringTools;

// used to save checkpoint data in songs w/ checkpoints!!
// this is so when you die, it goes back to the checkpoint and I dont have 50 different variables for checkpoint stuff, just 1 typedef!
typedef CheckpointData = {
	var time:Float;
	var score:Int;
	var combo:Int;
	var hits:Int;
	var totalPlayed:Int;
	var misses:Int;
	var sicks:Int;
	var goods:Int;
	var bads:Int;
	var shits:Int;
	var health:Float;
}

class PlayState extends MusicBeatState
{
	var targetHP:Float = 1;

	var noteRows:Array<Array<Array<Note>>> = [[],[],[]];

	//Some sexy shaders babeeee
	var camGlitchShader:GlitchShaderB;
	var camFuckShader:Fuck;
	var camGlitchFilter:BitmapFilter;
	var camFuckFilter:BitmapFilter;

	var barrelDistortionShader:BarrelDistortionShader;
	var barrelDistortionFilter:BitmapFilter;
	var jigglyOiledUpBlackMen:WiggleEffect;
	var glitchinTime:Bool = false;

        // IN THE SETUPMODCHART FUNCTION
	public static var songIsModcharted:Bool = false;

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
        public var spawnTime:Float = 3000;

	public var center:FlxPoint;

	//Rating shit
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	public var piss:Array<FlxTween> = [];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	//Singer's positions
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
        public static var isFreeplay:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var pauseRenderPrefix:Array<String> = ['', ''];

	public var vocals:FlxSound;
	
	public var dadGhostTween:FlxTween = null;
	public var bfGhostTween:FlxTween = null;
	public var dadGhost:FlxSprite = null; // Come out come out wherever you are!
	public var bfGhost:FlxSprite = null; // Just kidding, I already found you! 
	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	public var reversedStrumScroll:Bool = ClientPrefs.downScroll;

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done---ShadowMario
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var playFields:FlxTypedGroup<PlayField>;
	@:isVar
	public var strumLineNotes(get, null):Array<StrumNote>;
	function get_strumLineNotes(){
		var notes:Array<StrumNote> = [];
		if(playFields!=null && playFields.length>0){
			for(field in playFields.members){
				for(sturm in field.members)
					notes.push(sturm);
				
			}
		}
		return notes;
	}
	public var opponentStrums:PlayField;
	public var playerStrums:PlayField;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	//private var noteHoldCovers:Map<Note, NoteHoldCover> = [];

	private var curSong:String = "";

	//Gf's dancing speed(default: 1)
	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	public var healthBarOver:FlxSprite;
	var songPercent:Float = 0;
	var fakeSongPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	public var fakeTimeBar:FlxBar;

	//judgments score
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//shader things
	public var shaderUpdates:Array<Float->Void> = [];
        public var camGameShaders:Array<ShaderEffect> = [];
        public var camHUDShaders:Array<ShaderEffect> = [];
        public var camOtherShaders:Array<ShaderEffect> = [];

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camGame2:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var songNameHUD:FlxText;

	public var curTime:Float;

	public var curMS:Float;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	//Modmanager shit
        public var modManager:ModManager;
        public var upscrollOffset = 50;
	public var downscrollOffset = FlxG.height - 150;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;
	public var barSongLength:Float = 0; // hi neb i like ur code g :D
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	// HUD
	// TODO: diff HUD designs
	var isPixelHUD:Bool = false;
	var chaotixHUD:FlxSpriteGroup;
	var fcLabel:FlxSprite;
	var ringsLabel:FlxSprite;
	var hudDisplays:Map<String, SonicNumberDisplay> = [];
	// What Pixel HUD style should we add for songs
	var hudStyle:Map<String, String> = [
		"soulless-endeavors" => "chaotix",
		"meltdown" => "chotix",
		"long-sky-legacy" => "chotix",
		"my-horizon-legacy" => "chaotix",
		"our-horizon-legacy" => "chaotix",
		"soulless-endeavors-legacy" => "chaotix"
	];
	// for the time counter
	var hudMinute:SonicNumber;
	var hudSeconds:SonicNumberDisplay;
	var hudMS:SonicNumberDisplay;
	//intro stuff
	var startCircle:FlxSprite;
	var startText:FlxSprite;
	var blackFuck:FlxSprite;
	var whiteFuck:FlxSprite;
	var whiteFuckDos:FlxSprite;
	var redFuck:FlxSprite;
	
	// chaotix shit
	var vistaBG:FlxSprite;
	var vistaFloor:FlxSprite;
	var vistaGrass:FlxSprite;
	var vistaBush:FlxSprite;
	var vistaTree:FlxSprite;
	var vistaFlower:FlxSprite;

	var amyBop:FlxSprite;
	var charmyBop:FlxSprite;
	var espioBop:FlxSprite;
	var knuxBop:FlxSprite;
	var mightyBop:FlxSprite;
	var vectorBop:FlxSprite;
	// fucked mode!
	var fuckedBG:FlxSprite;
	var fuckedFloor:FlxSprite;
	var fuckedGrass:FlxSprite;
	var fuckedBush:FlxSprite;
	var fuckedTree:FlxSprite;
	var fuckedFlower:FlxSprite;
	var fuckedTails:FlxSprite;
	private var finalStretchTrail:FlxTrail;

	var amyBopFucked:FlxSprite;
	var charmyBopFucked:FlxSprite;
	var espioBopFucked:FlxSprite;
	var knuxBopFucked:FlxSprite;
	var mightyBopFucked:FlxSprite;
	var vectorBopFucked:FlxSprite;

	var fucklesBeats:Bool = true;
	var fuckedBar:Bool = false;
	// fuckles
	public var fucklesDrain:Float = 0;
	public var fucklesMode:Bool = false;
	public var drainMisses:Float = 0; // EEE OOO EH OO EE AAAAAAAAA
	// glad my comment above stayed lmao -neb
	//general stuff (statics n shit...)
	var theStatic:FlxSprite;  //THE FUNNY THE FUNNY!!!!
	var staticlol:StaticShader;
	var staticlmao:StaticShader;
	var staticOverlay:ShaderFilter;
	var glitchThingy:DistortGlitchShader;
	var glitchOverlay:ShaderFilter;
	private var staticAlpha:Float = 1;

	//duke shit
	//entrance (uu ee ayy uu)
	var entranceBG:FlxSprite;
	var entranceOver:FlxSprite;
	var entranceClock:FlxSprite;
	var entranceFloor:FlxSprite;
	var entranceIdk:FlxSprite;
	//entrance but legacy lol
	var entranceBGLegacy:FlxSprite;
	var entranceTowersLegacy:FlxSprite;
	var entranceClockLegacy:FlxSprite;
	var entranceFloorLegacy:FlxSprite;
	var entrancePointersLegacy:FlxSprite;

	// spooky shit
	var entranceSpookyBG:FlxSprite;
	var entranceSpookyOver:FlxSprite;
	var entranceSpookyClock:FlxSprite;
	var entranceSpookyFloor:FlxSprite;
	var entranceSpookyIdk:FlxSprite;
	//soulless endevors (ee oo ayy eh)
	var soulSky:FlxSprite;
	var soulBalls:FlxSprite; 
	//Hahahaha its balls, get it
	var bfSEFeet:FlxSprite;
	var soulRocks:FlxSprite;
	var soulKai:FlxSprite;
	var soulFrontRocks:FlxSprite;
	var soulPixelBg:FlxSprite;
	var soulPixelBgBg:FlxSprite;
	// hellspawn but legacy
	var soulBgLegacy:FlxSprite;
	var soulFogLegacy:FlxSprite;
	var soulGroundLegacy:FlxSprite;
	var soulSpiritsLegacy:FlxSprite;
	var soulPixelBgLegacy:FlxSprite;
	var soulPixelBgBgLegacy:FlxSprite;
	//final frontier
	var frontierBgLegacy:BGSprite;
	var frontierGroundLegacy:BGSprite;
	var frontierMasterEmeraldLegacy:FlxSprite;
	var frontierEmeraldsLegacy:FlxSprite;
	//GRRRR I HATE MATH I HA
	var dadFly:Character;
	var itemFly:FlxSprite;
	var itemFly2:FlxSprite;
	
	var emeraldTween:Float = 0; 
	var masterEmeraldTween:Float = 0;
	var dukeTween:Float = 0;
	//typed group my behatred
	var frontierDebris:FlxTypedGroup<BGSprite>;
	// horizon legacy 
	var fucklesBGPixelLegacy:FlxSprite;
	var fucklesFGPixelLegacy:FlxSprite;
	var fucklesAmyBgLegacy:FlxSprite;
	var fucklesVectorBgLegacy:FlxSprite;
	var fucklesKnuxBgLegacy:FlxSprite;
	var fucklesEspioBgLegacy:FlxSprite;
	var fucklesCharmyBgLegacy:FlxSprite;
	var fucklesMightyBgLegacy:FlxSprite;
	var fucklesFuckedUpBgLegacy:FlxSprite;
	var fucklesFuckedUpFgLegacy:FlxSprite;
	var fucklesTheHealthHogLegacy:Array<Float>;

	//horizon but real
	var horizonBgLegacy:FlxSprite;
	var horizonFloorLegacy:FlxSprite;
	var horizonTreesLegacy:FlxSprite;
	var horizonTrees2Legacy:FlxSprite;

	var horizonPurpurLegacy:FlxSprite;
	var horizonYellowLegacy:FlxSprite;
	var horizonRedLegacy:FlxSprite;
	
	var horizonAmyLegacy:FlxSprite;
	var horizonKnucklesLegacy:FlxSprite;
	var horizonEspioLegacy:FlxSprite;
	var horizonMightyLegacy:FlxSprite;
	var horizonCharmyLegacy:FlxSprite;
	var horizonVectorLegacy:FlxSprite;

	// normal shit
	private var metalTrail:FlxTrail;
	private var amyTrail:FlxTrail;
	private var normalTrail:FlxTrail;
	var soulGlassTime:Bool = false;
	var normalBg:FlxSprite;
	var normalFg:FlxSprite;
	var normalTv:FlxSprite;
	var normalVg:FlxSprite;
	var normalShadow:FlxSprite;
	var normalDoor:FlxSprite;
	var normalScreen:FlxSprite;
	var normalChars:FlxSprite;

	public var normalCharShit:Int;
	public var normalBool:Bool = false;

	//curse shit (just admit it!!!!)
	var hexTimer:Float = 0;
	var hexes:Float = 0;
	var fucklesSetHealth:Float = 0;
	var barbedWires:FlxTypedGroup<ShakableSprite>;
	var wireVignette:FlxSprite;
	//the fucking actual assets
	var curseStatic:FlxSprite;
	var curseFloor:FlxSprite;
	var curseSky:FlxSprite;
	var curseTrees:FlxSprite;
	var curseTreesTwo:FlxSprite;
	var curseFountain:FlxSprite;

	// old aughhhhhhhhhhhhhhhh
	var hellBgLegacy:FlxSprite;
	// aughhhhhhhhhhhhhhhh
	var hellBg:FlxSprite;
	// I AM WECHINDAAAAAAAAAA
	var horizonBGp1:FlxSprite;
	var horizonBGp2:FlxSprite;
	var horizonBGp3:FlxSprite;
	var horizonBGp4:FlxSprite;
	var horizonMG:FlxSprite;
	var horizonFGp1:FlxSprite;
	var horizonFGp2:FlxSprite;
	var horizonFGp3:FlxSprite;
	var horizonFGp4:FlxSprite;
	//scary wech bg
	var horizonSpookyBGp1:FlxSprite;
	var horizonSpookyBGp2:FlxSprite;
	var horizonSpookyBGp3:FlxSprite;
	var horizonSpookyBGp4:FlxSprite;
	var horizonSpookyFloor:FlxSprite;
	var horizonSpookyFGp1:FlxSprite;
	var horizonSpookyFGp2:FlxSprite;
	//HELP ME MIGHTY-----!!!!!!
	var wechniaP1:FlxSprite;
	var wechniaP2:FlxSprite;
	var wechniaP3:FlxSprite;
	var wechniaP4:FlxSprite;
	var wechniaP5:FlxSprite;
	var wechniaP6:FlxSprite;
	var wechniaP7:FlxSprite;
	var wechniaP8:FlxSprite;
	var wechniaP9:FlxSprite;
	var wechniaP10:FlxSprite;
	var wechniaP11:FlxSprite;

	//mazin (THE FUN IS INFINITE)
	var mazinBgLegacy:BGSprite;
	var mazinTreesLegacy:BGSprite;
	var mazinPlatformLegacy:BGSprite;
	var mazinPlatformBushesLegacy:BGSprite;
	var mazinLeftPlatformLegacy:BGSprite;
	var mazinRightPlatformLegacy:BGSprite;
	var mazinBushesLegacy:BGSprite;
	var mazinOverlayLegacy:BGSprite;

	var funIsInfinite:Bool = false;
	var funIsForever:Bool = false;

	// - healthbar based things for mechanic use (like my horizon lol)
	var healthMultiplier:Float = 1; // fnf
	var healthDrop:Float = 0;
	var dropTime:Float = 0;
	// - camera bullshit
	var dadCamThing:Array<Int> = [0, 0];
	var bfCamThing:Array<Int> = [0, 0];
	var cameramove:Bool = FlxG.save.data.cammove;
	//zoom bullshit
	public var defaultZoomin:Bool = true;
	public var wowZoomin:Bool = false;
	public var holyFuckStopZoomin:Bool = false;
	public var pleaseStopZoomin:Bool = false;
	public var ohGodTheZooms:Bool = false;
	//anim controller
	var animController:Bool = true;

	var scoreRandom:Bool = false;

   public var noteGroup:FlxTypedGroup<FlxBasic> = new FlxTypedGroup<FlxBasic>();
   
   public function set_cpuControlled(val:Bool){
		if(playFields!=null && playFields.members.length > 0){
			for(field in playFields.members){
				if(field.isPlayer)
					field.autoPlayed = val;
				
			}
		}
		return cpuControlled = val;
	}

	override public function create()
	{
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		blackFuck = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
		startCircle = new FlxSprite();
		startText = new FlxSprite();

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camGame2 = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camGame2.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camGame2);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		//Zawardo!!!!1!1!1
		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('test');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Scenario Mode";
		}
		else if (isFreeplay)
		{
			detailsText = "Freeplay";
		}
		else 
                {
			detailsText = "Legacy Room";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		//trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

      modManager = new ModManager(this);

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'entrance':

				GameOverSubstate.characterName = 'bfii-death';
			        GameOverSubstate.loopSoundName = 'duke-loop';

				defaultCamZoom = 0.65;

                if (ClientPrefs.shaders) {
				    camGlitchShader = new GlitchShaderB();
				    camGlitchShader.iResolution.value = [FlxG.width, FlxG.height];
				    camGlitchFilter = new ShaderFilter(camGlitchShader);

				    barrelDistortionShader = new BarrelDistortionShader();
				    barrelDistortionFilter = new ShaderFilter(barrelDistortionShader);
                }

				entranceBG = new FlxSprite(-325, -50);
				entranceBG.loadGraphic(Paths.image('entrance/bg', 'exe'));
				entranceBG.scrollFactor.set(0.6, 1);
				entranceBG.scale.set(1.1, 1.1);
				entranceBG.antialiasing = ClientPrefs.globalAntialiasing;

				entranceClock = new FlxSprite(-450, -50);
				entranceClock.loadGraphic(Paths.image('entrance/clock', 'exe'));
				entranceClock.scrollFactor.set(0.8, 1);
				entranceClock.scale.set(1.1, 1.1);
				entranceClock.antialiasing = ClientPrefs.globalAntialiasing;

				entranceIdk = new FlxSprite(-355, -50);
				entranceIdk.loadGraphic(Paths.image('entrance/idk', 'exe'));
				entranceIdk.scrollFactor.set(0.7, 1);
				entranceIdk.scale.set(1.1, 1.1);
				entranceIdk.antialiasing = ClientPrefs.globalAntialiasing;

				entranceFloor = new FlxSprite(-375, -50);
				entranceFloor.loadGraphic(Paths.image('entrance/floor', 'exe'));
				entranceFloor.scrollFactor.set(1, 1);
				entranceFloor.scale.set(1.1, 1.1);
				entranceFloor.antialiasing = ClientPrefs.globalAntialiasing;

				entranceOver = new FlxSprite(-325, -125);
				entranceOver.loadGraphic(Paths.image('entrance/over', 'exe'));
				entranceOver.scrollFactor.set(1.05, 1);
				entranceOver.scale.set(1.1, 1.1);
				entranceOver.antialiasing = ClientPrefs.globalAntialiasing;

				//-- haha fuck you im hardcoding the stages!!!!!!!!

				entranceSpookyBG = new FlxSprite(-325, -50);
				entranceSpookyBG.loadGraphic(Paths.image('entrance/scary/bg2', 'exe'));
				entranceSpookyBG.scrollFactor.set(0.6, 1);
				entranceSpookyBG.scale.set(1.1, 1.1);
				entranceSpookyBG.antialiasing = ClientPrefs.globalAntialiasing;
				entranceSpookyBG.visible = false;

				entranceSpookyClock = new FlxSprite(-450, -50);
				entranceSpookyClock.loadGraphic(Paths.image('entrance/scary/clock2', 'exe'));
				entranceSpookyClock.scrollFactor.set(0.8, 1);
				entranceSpookyClock.scale.set(1.1, 1.1);
				entranceSpookyClock.antialiasing = ClientPrefs.globalAntialiasing;
				entranceSpookyClock.visible = false;

				entranceSpookyIdk = new FlxSprite(-355, -50);
				entranceSpookyIdk.loadGraphic(Paths.image('entrance/scary/idk2', 'exe'));
				entranceSpookyIdk.scrollFactor.set(0.7, 1);
				entranceSpookyIdk.scale.set(1.1, 1.1);
				entranceSpookyIdk.antialiasing = ClientPrefs.globalAntialiasing;
				entranceSpookyIdk.visible = false;

				entranceSpookyFloor = new FlxSprite(-375, -50);
				entranceSpookyFloor.loadGraphic(Paths.image('entrance/scary/floor2', 'exe'));
				entranceSpookyFloor.scrollFactor.set(1, 1);
				entranceSpookyFloor.scale.set(1.1, 1.1);
				entranceSpookyFloor.antialiasing = ClientPrefs.globalAntialiasing;
				entranceSpookyFloor.visible = false;

				entranceSpookyOver = new FlxSprite(-325, -125);
				entranceSpookyOver.loadGraphic(Paths.image('entrance/scary/over2', 'exe'));
				entranceSpookyOver.scrollFactor.set(1.05, 1);
				entranceSpookyOver.scale.set(1.1, 1.1);
				entranceSpookyOver.antialiasing = ClientPrefs.globalAntialiasing;
				entranceSpookyOver.visible = false;

				add(entranceSpookyBG);
				add(entranceSpookyIdk);
				add(entranceSpookyClock);
				add(entranceSpookyFloor);
				
				add(entranceBG);
				add(entranceIdk);
				add(entranceClock);
				add(entranceFloor);

			case "entrance-legacy":

				defaultCamZoom = 0.75;

				if (ClientPrefs.shaders) {
				    barrelDistortionShader = new BarrelDistortionShader();
				    barrelDistortionFilter = new ShaderFilter(barrelDistortionShader);
				}

				entranceBGLegacy = new FlxSprite(-300, -300);
				entranceBGLegacy.loadGraphic(Paths.image('entrance/legacy/bg', 'exe'));
				entranceBGLegacy.scrollFactor.set(0.9, 1);
				entranceBGLegacy.scale.set(1.2, 1.2);
				entranceBGLegacy.antialiasing = ClientPrefs.globalAntialiasing;
				add(entranceBGLegacy);

				entranceTowersLegacy = new FlxSprite(-350, 0);
				entranceTowersLegacy.loadGraphic(Paths.image('entrance/legacy/towers', 'exe'));
				entranceTowersLegacy.scrollFactor.set(1.05, 1);
				entranceTowersLegacy.scale.set(1.2, 1.2);
				entranceTowersLegacy.antialiasing = ClientPrefs.globalAntialiasing;
				add(entranceTowersLegacy);

				entranceClockLegacy = new FlxSprite(-350, -50);
				entranceClockLegacy.loadGraphic(Paths.image('entrance/legacy/clock', 'exe'));
				entranceClockLegacy.scrollFactor.set(1, 1);
				entranceClockLegacy.scale.set(1.2, 1.2);
				entranceClockLegacy.antialiasing = ClientPrefs.globalAntialiasing;
				add(entranceClockLegacy);

				entranceFloorLegacy = new FlxSprite(-325, -50);
				entranceFloorLegacy.loadGraphic(Paths.image('entrance/legacy/floor', 'exe'));
				entranceFloorLegacy.scrollFactor.set(1, 1);
				entranceFloorLegacy.scale.set(1.2, 1.2);
				entranceFloorLegacy.antialiasing = ClientPrefs.globalAntialiasing;
				add(entranceFloorLegacy);

				entrancePointersLegacy = new FlxSprite(-300, -50);
				entrancePointersLegacy.loadGraphic(Paths.image('entrance/legacy/pointers', 'exe'));
				entrancePointersLegacy.scrollFactor.set(1.1, 1);
				entrancePointersLegacy.scale.set(1.2, 1.2);
				entrancePointersLegacy.antialiasing = ClientPrefs.globalAntialiasing;
				add(entrancePointersLegacy);

			case 'soulless':
				GameOverSubstate.characterName = 'bfii-death';
				GameOverSubstate.loopSoundName = 'duke-loop';

				defaultCamZoom = 0.6;

				soulSky = new FlxSprite(-246, -239);
				soulSky.loadGraphic(Paths.image('soulless/sky', 'exe'));
				soulSky.scrollFactor.set(0.3, 0.3);
				soulSky.scale.set(1, 1);
				soulSky.antialiasing = ClientPrefs.globalAntialiasing;
				add(soulSky);

				soulBalls = new FlxSprite(-246, -239);
				soulBalls.loadGraphic(Paths.image('soulless/balls', 'exe'));
				soulBalls.scrollFactor.set(0.5, 0.5);
				soulBalls.scale.set(1, 1);
				soulBalls.antialiasing = ClientPrefs.globalAntialiasing;
				add(soulBalls);

				soulRocks = new FlxSprite(-355, -239);
				soulRocks.loadGraphic(Paths.image('soulless/rocks', 'exe'));
				soulRocks.scrollFactor.set(0.7, 0.7);
				soulRocks.scale.set(1, 1);
				soulRocks.antialiasing = ClientPrefs.globalAntialiasing;
				add(soulRocks);

				soulKai = new FlxSprite(-366, -239);
				soulKai.loadGraphic(Paths.image('soulless/metal', 'exe'));
				soulKai.scrollFactor.set(0.9, 0.9);
				soulKai.scale.set(1, 1);
				soulKai.antialiasing = ClientPrefs.globalAntialiasing;
				add(soulKai);

				soulFrontRocks = new FlxSprite(-246, -239);
				soulFrontRocks.loadGraphic(Paths.image('soulless/rocksFront', 'exe'));
				soulFrontRocks.scrollFactor.set(1.0, 1.0);
				soulFrontRocks.scale.set(1.2, 1.2);
				soulFrontRocks.antialiasing = ClientPrefs.globalAntialiasing;
				add(soulFrontRocks);

				//the actual bg
				soulPixelBgBg = new FlxSprite(300, 150);
				soulPixelBgBg.loadGraphic(Paths.image('soulless/pixelbg', 'exe'));
				soulPixelBgBg.scrollFactor.set(1, 1);
				soulPixelBgBg.antialiasing = false;
				soulPixelBgBg.scale.set(4, 4);
				soulPixelBgBg.visible = false;
				add(soulPixelBgBg);

				//THE FUNNY!!! THE FU
				soulPixelBg = new FlxSprite(300, 150);
				soulPixelBg.frames = Paths.getSparrowAtlas('soulless/stage_running', 'exe');
				soulPixelBg.animation.addByPrefix('idle', 'stage', 24, true);
				soulPixelBg.animation.play('idle');
				soulPixelBg.scrollFactor.set(1, 1);
				soulPixelBg.antialiasing = false;
				soulPixelBg.scale.set(4, 4);
				soulPixelBg.visible = false;
				add(soulPixelBg);

				add(bfSEFeet);

			case "soulless-legacy":

				defaultCamZoom = 0.75;

				soulBgLegacy = new FlxSprite(-300, 0);
				soulBgLegacy.loadGraphic(Paths.image('soulless/legacy/bg', 'exe'));
				soulBgLegacy.scrollFactor.set(0.9, 1);
				soulBgLegacy.scale.set(1.4, 1.4);
				soulBgLegacy.antialiasing = ClientPrefs.globalAntialiasing;
				add(soulBgLegacy);

				soulFogLegacy = new FlxSprite(-300, -300);
				soulFogLegacy.loadGraphic(Paths.image('soulless/legacy/fog', 'exe'));
				soulFogLegacy.scrollFactor.set(0.9, 1);
				soulFogLegacy.scale.set(1.2, 1.2);
				soulFogLegacy.antialiasing = ClientPrefs.globalAntialiasing;


				soulSpiritsLegacy = new FlxSprite(-200, -150);
				soulSpiritsLegacy.frames = Paths.getSparrowAtlas('soulless/legacy/Spirits', 'exe');
				soulSpiritsLegacy.animation.addByPrefix('idle', 'SpiritWavingthing', 24, true);
				soulSpiritsLegacy.animation.play('idle');
				soulSpiritsLegacy.scrollFactor.set(0.9, 1);
				soulSpiritsLegacy.scale.set(1.2, 1.2);
				soulSpiritsLegacy.antialiasing = ClientPrefs.globalAntialiasing;
				soulSpiritsLegacy.visible = false;
				add(soulSpiritsLegacy);

				soulGroundLegacy = new FlxSprite(-200, -400);
				soulGroundLegacy.loadGraphic(Paths.image('soulless/legacy/ground', 'exe'));
				soulGroundLegacy.scrollFactor.set(1, 1);
				soulGroundLegacy.scale.set(1.3, 1.3);
				soulGroundLegacy.antialiasing = ClientPrefs.globalAntialiasing;
				add(soulGroundLegacy);

				//the actual bg
				soulPixelBgBgLegacy = new FlxSprite(300, 150);
				soulPixelBgBgLegacy.loadGraphic(Paths.image('soulless/pixelbg', 'exe'));
				soulPixelBgBgLegacy.scrollFactor.set(1, 1);
				soulPixelBgBgLegacy.antialiasing = false;
				soulPixelBgBgLegacy.scale.set(4, 4);
				soulPixelBgBgLegacy.visible = false;
				add(soulPixelBgBgLegacy);

				//THE FUNNY!!! THE FU
				soulPixelBgLegacy = new FlxSprite(300, 150);
				soulPixelBgLegacy.frames = Paths.getSparrowAtlas('soulless/stage_running', 'exe');
				soulPixelBgLegacy.animation.addByPrefix('idle', 'stage', 24, true);
				soulPixelBgLegacy.animation.play('idle');
				soulPixelBgLegacy.scrollFactor.set(1, 1);
				soulPixelBgLegacy.antialiasing = false;
				soulPixelBgLegacy.scale.set(4, 4);
				soulPixelBgLegacy.visible = false;
				add(soulPixelBgLegacy);

			case 'horizon-legacy':

				GameOverSubstate.deathSoundName = 'chaotix-death';
				GameOverSubstate.loopSoundName = 'chaotix-loop';
				GameOverSubstate.endSoundName = 'chaotix-retry';
				GameOverSubstate.characterName = 'bf-chaotix-death-legacy';

				defaultCamZoom = 0.87;
				isPixelStage = true;

				fucklesBGPixelLegacy = new FlxSprite(-1450, -725);
				fucklesBGPixelLegacy.loadGraphic(Paths.image('chaotix/legacy/horizonsky', 'exe'));
				fucklesBGPixelLegacy.scrollFactor.set(1.2, 0.9);
				fucklesBGPixelLegacy.scale.set(1, 1);
				fucklesBGPixelLegacy.antialiasing = false;
				add(fucklesBGPixelLegacy);

				fucklesFuckedUpBgLegacy = new FlxSprite(-1300, -500);
				fucklesFuckedUpBgLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/corrupt_background', 'exe');
				fucklesFuckedUpBgLegacy.animation.addByPrefix('idle', 'corrupt background', 24, true);
				fucklesFuckedUpBgLegacy.animation.play('idle');
				fucklesFuckedUpBgLegacy.scale.x = 1;
				fucklesFuckedUpBgLegacy.scale.y = 1;
				fucklesFuckedUpBgLegacy.visible = false;
				fucklesFuckedUpBgLegacy.antialiasing = false;
				add(fucklesFuckedUpBgLegacy);

				fucklesFGPixelLegacy = new FlxSprite(-550, -735);
				fucklesFGPixelLegacy.loadGraphic(Paths.image('chaotix/legacy/horizonFg', 'exe'));
				fucklesFGPixelLegacy.scrollFactor.set(1, 0.9);
				fucklesFGPixelLegacy.scale.set(1, 1);
				fucklesFGPixelLegacy.antialiasing = false;
				add(fucklesFGPixelLegacy);

				fucklesFuckedUpFgLegacy = new FlxSprite(-550, -735);
				fucklesFuckedUpFgLegacy.loadGraphic(Paths.image('chaotix/legacy/horizonFuckedUp', 'exe'));
				fucklesFuckedUpFgLegacy.scrollFactor.set(1, 0.9);
				fucklesFuckedUpFgLegacy.scale.set(1, 1);
				fucklesFuckedUpFgLegacy.visible = false;
				fucklesFuckedUpFgLegacy.antialiasing = false;
				add(fucklesFuckedUpFgLegacy);


				fucklesAmyBgLegacy = new FlxSprite(1195, 630);
				fucklesAmyBgLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/BG_amy', 'exe');
				fucklesAmyBgLegacy.animation.addByPrefix('idle', 'amy bobbing', 24);
				fucklesAmyBgLegacy.animation.addByPrefix('fear', 'amy fear', 24, true);
				fucklesAmyBgLegacy.scale.x = 6;
				fucklesAmyBgLegacy.scale.y = 6;
				fucklesAmyBgLegacy.antialiasing = false;


				fucklesCharmyBgLegacy = new FlxSprite(1000, 500);
				fucklesCharmyBgLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/BG_charmy', 'exe');
				fucklesCharmyBgLegacy.animation.addByPrefix('idle', 'charmy bobbing', 24);
				fucklesCharmyBgLegacy.animation.addByPrefix('fear', 'charmy fear', 24, true);
				fucklesCharmyBgLegacy.scale.x = 6;
				fucklesCharmyBgLegacy.scale.y = 6;
				fucklesCharmyBgLegacy.antialiasing = false;


				fucklesMightyBgLegacy = new FlxSprite(590, 650);
				fucklesMightyBgLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/BG_mighty', 'exe');
				fucklesMightyBgLegacy.animation.addByPrefix('idle', 'mighty bobbing', 24);
				fucklesMightyBgLegacy.animation.addByPrefix('fear', 'mighty fear', 24, true);
				fucklesMightyBgLegacy.scale.x = 6;
				fucklesMightyBgLegacy.scale.y = 6;
				fucklesMightyBgLegacy.antialiasing = false;


				fucklesEspioBgLegacy = new FlxSprite(1400, 660);
				fucklesEspioBgLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/BG_espio', 'exe');
				fucklesEspioBgLegacy.animation.addByPrefix('idle', 'espio bobbing', 24);
				fucklesEspioBgLegacy.animation.addByPrefix('fear', 'espio fear', 24, true);
				fucklesEspioBgLegacy.scale.x = 6;
				fucklesEspioBgLegacy.scale.y = 6;
				fucklesEspioBgLegacy.antialiasing = false;


				fucklesKnuxBgLegacy = new FlxSprite(-60, 645);
				fucklesKnuxBgLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/BG_knuckles', 'exe');
				fucklesKnuxBgLegacy.animation.addByPrefix('idle', 'knuckles bobbing', 24);
				fucklesKnuxBgLegacy.animation.addByPrefix('fear', 'knuckles fear', 24, true);
				fucklesKnuxBgLegacy.scale.x = 6;
				fucklesKnuxBgLegacy.scale.y = 6;
				fucklesKnuxBgLegacy.antialiasing = false;

				whiteFuck = new FlxSprite(-600, 0).makeGraphic(FlxG.width * 6, FlxG.height * 6, FlxColor.BLACK);
				whiteFuck.alpha = 0;

				fucklesVectorBgLegacy = new FlxSprite(-250, 615);
				fucklesVectorBgLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/BG_vector', 'exe');
				fucklesVectorBgLegacy.animation.addByPrefix('idle', 'vector bobbing', 24);
				fucklesVectorBgLegacy.animation.addByPrefix('fear', 'vector fear', 24, true);
				fucklesVectorBgLegacy.scale.x = 6;
				fucklesVectorBgLegacy.scale.y = 6;
				fucklesVectorBgLegacy.antialiasing = false;

				add(fucklesAmyBgLegacy);
				add(fucklesCharmyBgLegacy);
				add(fucklesMightyBgLegacy);
				add(fucklesEspioBgLegacy);
				add(fucklesKnuxBgLegacy);
				add(fucklesVectorBgLegacy);
				add(whiteFuck);

				if (SONG.song.toLowerCase() == 'our-horizon-legacy')
					{

						horizonBgLegacy = new FlxSprite(-500, 285);
						horizonBgLegacy.loadGraphic(Paths.image('chaotix/legacy/new_horizon/starline', 'exe'));
						horizonBgLegacy.scrollFactor.set(1, 1);
						horizonBgLegacy.scale.set(1.1, 1.1);
						horizonBgLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonBgLegacy);

						horizonPurpurLegacy = new FlxSprite(-150, 425);
						horizonPurpurLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/firework/pink_firework', 'exe');
						horizonPurpurLegacy.animation.addByPrefix('idle', 'red firework', 8);
						horizonPurpurLegacy.scrollFactor.set(1, 1);
						horizonPurpurLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonPurpurLegacy);

						horizonRedLegacy = new FlxSprite(400, 425);
						horizonRedLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/firework/red_firework', 'exe');
						horizonRedLegacy.animation.addByPrefix('idle', 'red firework', 8);
						horizonRedLegacy.scrollFactor.set(1, 1);
						horizonRedLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonRedLegacy);

						horizonYellowLegacy = new FlxSprite(800, 425);
						horizonYellowLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/firework/yellow_firework', 'exe');
						horizonYellowLegacy.animation.addByPrefix('idle', 'red firework', 8);
						horizonYellowLegacy.scrollFactor.set(1, 1);
						horizonYellowLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonYellowLegacy);

						horizonFloorLegacy = new FlxSprite(-500, 285);
						horizonFloorLegacy.loadGraphic(Paths.image('chaotix/legacy/new_horizon/floor', 'exe'));
						horizonFloorLegacy.scrollFactor.set(1, 1);
						horizonFloorLegacy.scale.set(1.1, 1.1);
						horizonFloorLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonFloorLegacy);

						horizonEspioLegacy = new FlxSprite(-300, 400);
						horizonEspioLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/new_horizon/espio_bopper', 'exe');
						horizonEspioLegacy.animation.addByPrefix('idle', 'espio bopper instance 1', 24);
						horizonEspioLegacy.scrollFactor.set(1, 1);
						horizonEspioLegacy.setGraphicSize(Std.int(horizonEspioLegacy.width * 0.5));
						horizonEspioLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonEspioLegacy);

						horizonTreesLegacy = new FlxSprite(-400, 285);
						horizonTreesLegacy.loadGraphic(Paths.image('chaotix/legacy/new_horizon/trees', 'exe'));
						horizonTreesLegacy.scrollFactor.set(1, 1);
						horizonTreesLegacy.scale.set(1.1, 1.1);
						horizonTreesLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonTreesLegacy);

						horizonAmyLegacy = new FlxSprite(800, 400);
						horizonAmyLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/new_horizon/amy_bopper', 'exe');
						horizonAmyLegacy.animation.addByPrefix('idle', 'amy bopper instance 1', 24);
						horizonAmyLegacy.scrollFactor.set(1, 1);
						horizonAmyLegacy.setGraphicSize(Std.int(horizonAmyLegacy.width * 0.5));
						horizonAmyLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonAmyLegacy);

						horizonMightyLegacy = new FlxSprite(500, 400);
						horizonMightyLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/new_horizon/mighty_bopper', 'exe');
						horizonMightyLegacy.animation.addByPrefix('idle', 'mighty bopper', 24);
						horizonMightyLegacy.scrollFactor.set(1, 1);
						horizonMightyLegacy.setGraphicSize(Std.int(horizonMightyLegacy.width * 0.5));
						horizonMightyLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonMightyLegacy);

						horizonCharmyLegacy = new FlxSprite(675, 200);
						horizonCharmyLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/new_horizon/charmy_bopper', 'exe');
						horizonCharmyLegacy.animation.addByPrefix('idle', 'charmy bopper', 24);
						horizonCharmyLegacy.scrollFactor.set(1, 1);
						horizonCharmyLegacy.setGraphicSize(Std.int(horizonCharmyLegacy.width * 0.5));
						horizonCharmyLegacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonCharmyLegacy);

						horizonTrees2Legacy = new FlxSprite(-500, 285);
						horizonTrees2Legacy.loadGraphic(Paths.image('chaotix/legacy/new_horizon/trees2', 'exe'));
						horizonTrees2Legacy.scrollFactor.set(1, 1);
						horizonTrees2Legacy.scale.set(1.1, 1.1);
						horizonTrees2Legacy.antialiasing = ClientPrefs.globalAntialiasing;
						add(horizonTrees2Legacy);

						horizonKnucklesLegacy = new FlxSprite(-750, 780);
						horizonKnucklesLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/new_horizon/knuckles_bopper', 'exe');
						horizonKnucklesLegacy.animation.addByPrefix('idle', 'knuckles bopper instance 1', 24);
						horizonKnucklesLegacy.scrollFactor.set(0.9, 0.75);
						horizonKnucklesLegacy.setGraphicSize(Std.int(horizonKnucklesLegacy.width * 0.85));
						horizonKnucklesLegacy.antialiasing = ClientPrefs.globalAntialiasing;

						horizonVectorLegacy = new FlxSprite(750, 700);
						horizonVectorLegacy.frames = Paths.getSparrowAtlas('chaotix/legacy/new_horizon/vector_bopper', 'exe');
						horizonVectorLegacy.animation.addByPrefix('idle', 'vector bopper', 24);
						horizonVectorLegacy.scrollFactor.set(0.9, 0.75);
						horizonVectorLegacy.setGraphicSize(Std.int(horizonVectorLegacy.width * 0.85));
						horizonVectorLegacy.antialiasing = ClientPrefs.globalAntialiasing;

						horizonBgLegacy.visible = false;
						horizonFloorLegacy.visible = false;
						horizonTreesLegacy.visible = false;
						horizonTrees2Legacy.visible = false;

						horizonPurpurLegacy.visible = false;
						horizonYellowLegacy.visible = false;
						horizonRedLegacy.visible = false;

						horizonAmyLegacy.visible = false;
						horizonCharmyLegacy.visible = false;
						horizonEspioLegacy.visible = false;
						horizonMightyLegacy.visible = false;
						horizonKnucklesLegacy.visible = false;
						horizonVectorLegacy.visible = false;
					}

			case 'vista':
				// lol
				GameOverSubstate.loopSoundName = 'chaotix-loop';
				GameOverSubstate.endSoundName = 'chaotix-retry';

                               if (ClientPrefs.shaders) {
				    camGlitchShader = new GlitchShaderB();
				    camGlitchShader.iResolution.value = [FlxG.width, FlxG.height];
				    camGlitchFilter = new ShaderFilter(camGlitchShader);

				    staticlol = new StaticShader();
				    staticOverlay = new ShaderFilter(staticlol);
				    staticlol.iTime.value = [0];
				    staticlol.iResolution.value = [FlxG.width, FlxG.height];
				    staticlol.alpha.value = [staticAlpha];
				    staticlol.enabled.value = [false];

				    camFuckShader = new Fuck();
				    camFuckFilter = new ShaderFilter(camFuckShader);

				    camGame.setFilters([staticOverlay, camFuckFilter]);
                }

				GameOverSubstate.characterName = 'bfii-death';
				defaultCamZoom = 0.6;
				
				vistaBG = new FlxSprite(-450, -250);
				vistaBG.loadGraphic(Paths.image('chaotix/vistaBg', 'exe'));
				vistaBG.scrollFactor.set(0.6, 1);
				vistaBG.scale.set(1.1, 1.1);
				vistaBG.antialiasing = ClientPrefs.globalAntialiasing;
				add(vistaBG);

				vistaFloor = new FlxSprite(-460, -230);
				vistaFloor.loadGraphic(Paths.image('chaotix/vistaFloor', 'exe'));
				vistaFloor.scrollFactor.set(1, 1);
				vistaFloor.scale.set(1.1, 1.1);
				vistaFloor.antialiasing = ClientPrefs.globalAntialiasing;
				add(vistaFloor);

				vistaGrass = new FlxSprite(-460, -230);
				vistaGrass.loadGraphic(Paths.image('chaotix/vistaGrass', 'exe'));
				vistaGrass.scrollFactor.set(1, 1);
				vistaGrass.scale.set(1.1, 1.1);
				vistaGrass.antialiasing = ClientPrefs.globalAntialiasing;
				add(vistaGrass);

				vistaBush = new FlxSprite(-460, -230);
				vistaBush.loadGraphic(Paths.image('chaotix/vistaBush', 'exe'));
				vistaBush.scrollFactor.set(0.9, 1);
				vistaBush.scale.set(1.1, 1.1);
				vistaBush.antialiasing = ClientPrefs.globalAntialiasing;
				add(vistaBush);

				vistaTree = new FlxSprite(-460, -230);
				vistaTree.loadGraphic(Paths.image('chaotix/vistaTree', 'exe'));
				vistaTree.scrollFactor.set(0.9, 1);
				vistaTree.scale.set(1.1, 1.1);
				vistaTree.antialiasing = ClientPrefs.globalAntialiasing;
				add(vistaTree);

				vistaFlower = new FlxSprite(-460, -230);
				vistaFlower.loadGraphic(Paths.image('chaotix/vistaFlower', 'exe'));
				vistaFlower.scrollFactor.set(0.9, 1);
				vistaFlower.scale.set(1.1, 1.1);
				vistaFlower.antialiasing = ClientPrefs.globalAntialiasing;
				add(vistaFlower);

				amyBop = new FlxSprite(-150, 530);
				amyBop.frames = Paths.getSparrowAtlas('chaotix/bop/AmyBop', 'exe');
				amyBop.animation.addByPrefix('idle', 'AmyBop', 24, false);
				amyBop.scrollFactor.set(1, 1);
				amyBop.scale.set(1.0, 1.0);
				amyBop.antialiasing = ClientPrefs.globalAntialiasing;

				charmyBop = new FlxSprite(900, 0);
				charmyBop.frames = Paths.getSparrowAtlas('chaotix/bop/CharmyBop', 'exe');
				charmyBop.animation.addByPrefix('danceLeft', 'CharmyBopLeft', 24, false);
				charmyBop.animation.addByPrefix('danceRight', 'CharmyBopRight', 24, false);
				charmyBop.scrollFactor.set(1, 1);
				charmyBop.scale.set(1.0, 1.0);
				charmyBop.antialiasing = ClientPrefs.globalAntialiasing;
				add(charmyBop);

				vectorBop = new FlxSprite(1300, 80);
				vectorBop.frames = Paths.getSparrowAtlas('chaotix/bop/VectorBop', 'exe');
				vectorBop.animation.addByPrefix('idle', 'VectorBop', 24, false);
				vectorBop.scrollFactor.set(1, 1);
				vectorBop.scale.set(0.9, 0.9);
				vectorBop.antialiasing = ClientPrefs.globalAntialiasing;
				add(vectorBop);

				espioBop = new FlxSprite(1800, 250);
				espioBop.frames = Paths.getSparrowAtlas('chaotix/bop/EspioBop', 'exe');
				espioBop.animation.addByPrefix('idle', 'EspioBop', 24, false);
				espioBop.scrollFactor.set(1, 1);
				espioBop.scale.set(1.0, 1.0);
				espioBop.antialiasing = ClientPrefs.globalAntialiasing;
				add(espioBop);

				mightyBop = new FlxSprite(-350, 200);
				mightyBop.frames = Paths.getSparrowAtlas('chaotix/bop/MightyBop', 'exe');
				mightyBop.animation.addByPrefix('idle', 'MIGHTYBOP', 24, false);
				mightyBop.scrollFactor.set(1, 1);
				mightyBop.scale.set(1.0, 1.0);
				mightyBop.antialiasing = ClientPrefs.globalAntialiasing;
				add(mightyBop);

				knuxBop = new FlxSprite(-600, 250);
				knuxBop.frames = Paths.getSparrowAtlas('chaotix/bop/KnuxBop', 'exe');
				knuxBop.animation.addByPrefix('idle', 'KNUXBOP', 24, false);
				knuxBop.scrollFactor.set(1, 1);
				knuxBop.scale.set(1.0, 1.0);
				knuxBop.antialiasing = ClientPrefs.globalAntialiasing;	
				add(knuxBop);

				//the funny for the transformo shtuff

				whiteFuck = new FlxSprite(-800, -200).makeGraphic(FlxG.width * 6, FlxG.height * 6, FlxColor.BLACK);
				whiteFuck.alpha = 0;
				add(whiteFuck);

				redFuck = new FlxSprite(-800, -200).makeGraphic(FlxG.width * 6, FlxG.height * 6, FlxColor.RED);
				redFuck.alpha = 0;
				add(redFuck);

				whiteFuckDos = new FlxSprite(-800, -200).makeGraphic(FlxG.width * 6, FlxG.height * 6, FlxColor.WHITE);
				whiteFuckDos.alpha = 0;
				add(whiteFuckDos);

				//fucked mode achieved

				fuckedBG = new FlxSprite(-450, -250);
				fuckedBG.loadGraphic(Paths.image('chaotix/fucked/fuckedBg', 'exe'));
				fuckedBG.scrollFactor.set(0.6, 1);
				fuckedBG.scale.set(1.1, 1.1);
				fuckedBG.antialiasing = ClientPrefs.globalAntialiasing;
				add(fuckedBG);

				fuckedFloor = new FlxSprite(-460, -250);
				fuckedFloor.loadGraphic(Paths.image('chaotix/fucked/fuckedFloor', 'exe'));
				fuckedFloor.scrollFactor.set(1, 1);
				fuckedFloor.scale.set(1.2, 1.2);
				fuckedFloor.antialiasing = ClientPrefs.globalAntialiasing;
				add(fuckedFloor);

				fuckedGrass = new FlxSprite(-550, -220);
				fuckedGrass.loadGraphic(Paths.image('chaotix/fucked/fuckedGrass', 'exe'));
				fuckedGrass.scrollFactor.set(1, 1);
				fuckedGrass.scale.set(1.2, 1.2);
				fuckedGrass.antialiasing = ClientPrefs.globalAntialiasing;
				add(fuckedGrass);

				fuckedTree = new FlxSprite(-460, -220);
				fuckedTree.loadGraphic(Paths.image('chaotix/fucked/fuckedTrees', 'exe'));
				fuckedTree.scrollFactor.set(1, 1);
				fuckedTree.scale.set(1.1, 1.1);
				fuckedTree.antialiasing = ClientPrefs.globalAntialiasing;
				add(fuckedTree);

				fuckedBush = new FlxSprite(-460, -220);
				fuckedBush.loadGraphic(Paths.image('chaotix/fucked/fuckedBush', 'exe'));
				fuckedBush.scrollFactor.set(1, 1);
				fuckedBush.scale.set(1.1, 1.1);
				fuckedBush.antialiasing = ClientPrefs.globalAntialiasing;
				add(fuckedBush);

				fuckedFlower = new FlxSprite(-460, -220);
				fuckedFlower.loadGraphic(Paths.image('chaotix/fucked/fuckedFlower', 'exe'));
				fuckedFlower.scrollFactor.set(1, 1);
				fuckedFlower.scale.set(1.1, 1.1);
				fuckedFlower.antialiasing = ClientPrefs.globalAntialiasing;
				add(fuckedFlower);

				fuckedTails = new FlxSprite(-460, -230);
				fuckedTails.loadGraphic(Paths.image('chaotix/fucked/fuckedTails', 'exe'));
				fuckedTails.scrollFactor.set(0.9, 1);
				fuckedTails.scale.set(1.1, 1.1);
				fuckedTails.antialiasing = ClientPrefs.globalAntialiasing;

				amyBopFucked = new FlxSprite(-800, 150);
				amyBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/AmyScared', 'exe');
				amyBopFucked.animation.addByPrefix('idle', 'AmyScared instance 1', 24, false);
				amyBopFucked.scrollFactor.set(1, 1);
				amyBopFucked.scale.set(1.0, 1.0);
				amyBopFucked.antialiasing = ClientPrefs.globalAntialiasing;
				add(amyBopFucked);

				charmyBopFucked = new FlxSprite(1800, 0);
				charmyBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/CharmyScared', 'exe');
				charmyBopFucked.animation.addByPrefix('danceLeft', 'CharmyScaredBop instance 1', 24, false);
				charmyBopFucked.scrollFactor.set(1, 1);
				charmyBopFucked.scale.set(1.0, 1.0);
				charmyBopFucked.antialiasing = ClientPrefs.globalAntialiasing;
				add(charmyBopFucked);

				vectorBopFucked = new FlxSprite(1300, 120);
				vectorBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/VectorScared', 'exe');
				vectorBopFucked.animation.addByPrefix('idle', 'VectorScaredBop instance 1', 24, false);
				vectorBopFucked.scrollFactor.set(1, 1);
				vectorBopFucked.scale.set(1.0, 1.0);
				vectorBopFucked.antialiasing = ClientPrefs.globalAntialiasing;
				add(vectorBopFucked);

				espioBopFucked = new FlxSprite(1750, 400);
				espioBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/EspioScared', 'exe');
				espioBopFucked.animation.addByPrefix('idle', 'EspioScaredBop instance 1', 24, false);
				espioBopFucked.scrollFactor.set(0.9, 0.9);
				espioBopFucked.scale.set(1.0, 1.0);
				espioBopFucked.antialiasing = ClientPrefs.globalAntialiasing;
				add(espioBopFucked);

				mightyBopFucked = new FlxSprite(-150, 200);
				mightyBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/MightyScared', 'exe');
				mightyBopFucked.animation.addByPrefix('idle', 'MightyScaredBop instance 1', 24, false);
				mightyBopFucked.scrollFactor.set(1, 1);
				mightyBopFucked.scale.set(0.9, 0.9);
				mightyBopFucked.antialiasing = ClientPrefs.globalAntialiasing;
				add(mightyBopFucked);

				knuxBopFucked = new FlxSprite(-700, 340);
				knuxBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/KnuxScared', 'exe');
				knuxBopFucked.animation.addByPrefix('idle', 'KnuxScaredBop instance 1', 24, false);
				knuxBopFucked.scrollFactor.set(1, 1);
				knuxBopFucked.scale.set(0.9, 0.9);
				knuxBopFucked.antialiasing = ClientPrefs.globalAntialiasing;


				fuckedBG.visible = false;
				fuckedFloor.visible = false;
				fuckedGrass.visible = false;
				fuckedBush.visible = false;
				fuckedTree.visible = false;
				fuckedFlower.visible = false;
				fuckedTails.visible = false;

				amyBopFucked.visible = false;
				charmyBopFucked.visible = false;
				vectorBopFucked.visible = false;
				espioBopFucked.visible = false;
				mightyBopFucked.visible = false;
				knuxBopFucked.visible = false;

			case 'emerald':
                var ehzSkyFull:FlxSprite = new FlxSprite();
				ehzSkyFull.loadGraphic(Paths.image('emerald/blue', 'exe'));
				ehzSkyFull.screenCenter();
				ehzSkyFull.x -= 50;
				ehzSkyFull.y -= 100;
				ehzSkyFull.scale.set(2.5, 2.5);
				ehzSkyFull.antialiasing = ClientPrefs.globalAntialiasing;
				add(ehzSkyFull);
				
				var ehzBG:FlxSprite = new FlxSprite();
				ehzBG.loadGraphic(Paths.image('emerald/ehzback', 'exe'));
				ehzBG.screenCenter();
				ehzBG.x -= 162.5;
				ehzBG.y += 100;
				ehzBG.scrollFactor.set(0.7, 1);
				ehzBG.scale.set(1.5, 1.5);
				ehzBG.antialiasing = ClientPrefs.globalAntialiasing;
				add(ehzBG);

				var ehzGround:FlxSprite = new FlxSprite();
				ehzGround.frames = Paths.getSparrowAtlas('emerald/EHZGROUND', 'exe');
				ehzGround.animation.addByPrefix('waterfall', 'EHZGROUND', 24, true);
				ehzGround.animation.play('waterfall');
				ehzGround.scale.set(2.1, 2.1);
				ehzGround.antialiasing = ClientPrefs.globalAntialiasing;
				ehzGround.screenCenter();
				add(ehzGround);

			case 'horizon':
				horizonBGp1 = new FlxSprite(-350, -50);
				horizonBGp1.loadGraphic(Paths.image('horizon/bgpart1', 'exe'));
				horizonBGp1.scrollFactor.set(0.6, 1);
				horizonBGp1.scale.set(1.5, 1.5);
				horizonBGp1.antialiasing = ClientPrefs.globalAntialiasing;

				horizonBGp2 = new FlxSprite(-350, -150);
				horizonBGp2.loadGraphic(Paths.image('horizon/bgpart2', 'exe'));
				horizonBGp2.scrollFactor.set(0.65, 1);
				horizonBGp2.scale.set(1.5, 1.5);
				horizonBGp2.antialiasing = ClientPrefs.globalAntialiasing;

				horizonBGp3 = new FlxSprite(-350, -150);
				horizonBGp3.loadGraphic(Paths.image('horizon/bgpart3', 'exe'));
				horizonBGp3.scrollFactor.set(0.7, 1);
				horizonBGp3.scale.set(1.5, 1.5);
				horizonBGp3.antialiasing = ClientPrefs.globalAntialiasing;

				horizonBGp4 = new FlxSprite(-375, -150);
			        horizonBGp4.loadGraphic(Paths.image('horizon/bgpart4', 'exe'));
				horizonBGp4.scrollFactor.set(0.75, 1);
				horizonBGp4.scale.set(1.5, 1.5);
				horizonBGp4.antialiasing = ClientPrefs.globalAntialiasing;

				horizonFGp1 = new FlxSprite(-450, -50);
				horizonFGp1.loadGraphic(Paths.image('horizon/fgpart1', 'exe'));
				horizonFGp1.scrollFactor.set(0.8, 1);
				horizonFGp1.scale.set(1.5, 1.5);
				horizonFGp1.antialiasing = ClientPrefs.globalAntialiasing;

				horizonFGp2 = new FlxSprite(-450, -75);
				horizonFGp2.loadGraphic(Paths.image('horizon/fgpart2', 'exe'));
				horizonFGp2.scrollFactor.set(0.8, 1);
				horizonFGp2.scale.set(1.5, 1.5);
				horizonFGp2.antialiasing = ClientPrefs.globalAntialiasing;

				horizonFGp3 = new FlxSprite(-450, -50);
				horizonFGp3.loadGraphic(Paths.image('horizon/fgpart3', 'exe'));
				horizonFGp3.scale.set(1.225, 1.225);
				horizonFGp3.antialiasing = ClientPrefs.globalAntialiasing;

				horizonFGp4 = new FlxSprite(-450, -100);
				horizonFGp4.loadGraphic(Paths.image('horizon/fgpart4', 'exe'));
				horizonFGp4.scrollFactor.set(0.7, 1);
				horizonFGp4.scale.set(1.5, 1.5);
				horizonFGp4.antialiasing = ClientPrefs.globalAntialiasing;

				horizonMG = new FlxSprite(-450, -50);
				horizonMG.loadGraphic(Paths.image('horizon/midground', 'exe'));
				horizonMG.scale.set(1.5, 1.5);
				horizonMG.antialiasing = ClientPrefs.globalAntialiasing;

				horizonSpookyBGp1 = new FlxSprite(-350, -50);
				horizonSpookyBGp1.loadGraphic(Paths.image('horizon/spooky/spookyp1', 'exe'));
				horizonSpookyBGp1.scrollFactor.set(0.6, 1);
				horizonSpookyBGp1.scale.set(1.5, 1.5);
				horizonSpookyBGp1.antialiasing = ClientPrefs.globalAntialiasing;
				horizonSpookyBGp1.alpha = 0;

				horizonSpookyBGp2 = new FlxSprite(-350, -150);
				horizonSpookyBGp2.loadGraphic(Paths.image('horizon/spooky/spookyp2', 'exe'));
				horizonSpookyBGp2.scrollFactor.set(0.65, 1);
				horizonSpookyBGp2.scale.set(1.5, 1.5);
				horizonSpookyBGp2.antialiasing = ClientPrefs.globalAntialiasing;
				horizonSpookyBGp2.alpha = 0;

				horizonSpookyBGp3 = new FlxSprite(-350, -150);
				horizonSpookyBGp3.loadGraphic(Paths.image('horizon/spooky/spookyp3', 'exe'));
				horizonSpookyBGp3.scrollFactor.set(0.7, 1);
				horizonSpookyBGp3.scale.set(1.5, 1.5);
				horizonSpookyBGp3.antialiasing = ClientPrefs.globalAntialiasing;
				horizonSpookyBGp3.alpha = 0;

				horizonSpookyBGp4 = new FlxSprite(-375, -150);
				horizonSpookyBGp4.loadGraphic(Paths.image('horizon/spooky/spookyp4', 'exe'));
				horizonSpookyBGp4.scrollFactor.set(0.75, 1);
				horizonSpookyBGp4.scale.set(1.5, 1.5);
				horizonSpookyBGp4.antialiasing = ClientPrefs.globalAntialiasing;
				horizonSpookyBGp4.alpha = 0;
				
				horizonSpookyFGp1 = new FlxSprite(-450, -50);
				horizonSpookyFGp1.loadGraphic(Paths.image('horizon/spooky/spookyfg1', 'exe'));
				horizonSpookyFGp1.scale.set(1.525, 1.525);
				horizonSpookyFGp1.antialiasing = ClientPrefs.globalAntialiasing;
				horizonSpookyFGp1.alpha = 0;

				horizonSpookyFGp2 = new FlxSprite(-450, -100);
				horizonSpookyFGp2.loadGraphic(Paths.image('horizon/spooky/spookyfg2', 'exe'));
				horizonSpookyFGp2.scrollFactor.set(0.5, 1);
				horizonSpookyFGp2.scale.set(1.5, 1.5);
				horizonSpookyFGp2.antialiasing = ClientPrefs.globalAntialiasing;
				horizonSpookyFGp2.alpha = 0;
				
				horizonSpookyFloor = new FlxSprite(-325, -50);
				horizonSpookyFloor.loadGraphic(Paths.image('horizon/spooky/spookyfloor', 'exe'));
				horizonSpookyFloor.scale.set(1.5, 1.5);
				horizonSpookyFloor.antialiasing = ClientPrefs.globalAntialiasing;
				horizonSpookyFloor.alpha = 0;

				
				add(horizonSpookyBGp1);
				add(horizonSpookyBGp2);
				add(horizonSpookyBGp3);
				add(horizonSpookyBGp4);
				add(horizonSpookyFloor);
				
				add(horizonBGp1);
				add(horizonBGp2);
				add(horizonBGp3);
				add(horizonBGp4);
				add(horizonMG);

			case "wechnia":
				wechniaP1 = new FlxSprite();
				wechniaP1.loadGraphic(Paths.image('wechnia/1', 'exe'));
				wechniaP1.scrollFactor.set(0.8, 0.8);
				wechniaP1.screenCenter();
				wechniaP1.scale.set(1.1, 1.1);
				wechniaP1.antialiasing = ClientPrefs.globalAntialiasing;

			    wechniaP2 = new FlxSprite(-350, -50);
				wechniaP2.loadGraphic(Paths.image('wechnia/2', 'exe'));
				wechniaP2.scrollFactor.set(0.8, 0.8);
				wechniaP2.screenCenter();
				wechniaP2.scale.set(1.1, 1.1);
				wechniaP2.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP3 = new FlxSprite(-350, -50);
				wechniaP3.loadGraphic(Paths.image('wechnia/3', 'exe'));
				wechniaP3.screenCenter();
				wechniaP3.scale.set(1.1, 1.1);
				wechniaP3.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP4 = new FlxSprite(-350, -50);
				wechniaP4.loadGraphic(Paths.image('wechnia/4', 'exe'));
				wechniaP4.scale.set(1.1, 1.1);
				wechniaP4.screenCenter();
				wechniaP4.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP5 = new FlxSprite(-350, -50);
				wechniaP5.loadGraphic(Paths.image('wechnia/5', 'exe'));
				wechniaP5.screenCenter();
				wechniaP5.scale.set(1.1, 1.1);
				wechniaP5.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP6 = new FlxSprite(-350, -50);
				wechniaP6.loadGraphic(Paths.image('wechnia/6', 'exe'));
				wechniaP6.screenCenter();
				wechniaP6.scale.set(1.1, 1.1);
				wechniaP6.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP7 = new FlxSprite(-350, -50);
				wechniaP7.loadGraphic(Paths.image('wechnia/7', 'exe'));
				wechniaP7.screenCenter();
				wechniaP7.scale.set(1.1, 1.1);
				wechniaP7.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP8 = new FlxSprite(-350, -50);
				wechniaP8.loadGraphic(Paths.image('wechnia/8', 'exe'));
				wechniaP8.scale.set(1.1, 1.1);
				wechniaP8.screenCenter();
				wechniaP8.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP9 = new FlxSprite();
				wechniaP9.loadGraphic(Paths.image('wechnia/9', 'exe'));
				wechniaP9.scrollFactor.set(0.8, 1);
				wechniaP9.screenCenter();
				wechniaP9.y += 25;
				wechniaP9.cameras = [FlxG.camera];
				wechniaP9.scale.set(1.1, 1.1);
				wechniaP9.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP10 = new FlxSprite();
				wechniaP10.loadGraphic(Paths.image('wechnia/10', 'exe'));
				wechniaP10.scrollFactor.set(0.85, 1);
				wechniaP10.cameras = [FlxG.camera];	
				wechniaP10.screenCenter();			
				wechniaP10.scale.set(1.1, 1.1);
				wechniaP10.antialiasing = ClientPrefs.globalAntialiasing;

				wechniaP11 = new FlxSprite();
				wechniaP11.loadGraphic(Paths.image('wechnia/11', 'exe'));
				wechniaP11.screenCenter();
				wechniaP11.y += 250;
				wechniaP11.scale.set(1.2, 1.25);
				wechniaP11.antialiasing = ClientPrefs.globalAntialiasing;

				add(wechniaP1);
				add(wechniaP2);
				add(wechniaP3);
				add(wechniaP4);
				add(wechniaP5);
				add(wechniaP6);
				add(wechniaP7);
				add(wechniaP8);
				add(wechniaP11);

			case 'chotix':
				{

					GameOverSubstate.characterName = 'bfii-death';
					defaultCamZoom = 0.6;

					hellBg = new FlxSprite(-400, 0);
					hellBg.loadGraphic(Paths.image('chaotix/hell', 'exe'));
					hellBg.scrollFactor.set(1, 1);
					hellBg.scale.set(1.5, 1.5);
					hellBg.antialiasing = false;
					add(hellBg);
				}

			case 'chotix-legacy':
				{
					defaultCamZoom = 0.8;
		
					hellBgLegacy = new FlxSprite(-750, 0);
					hellBgLegacy.loadGraphic(Paths.image('chaotix/legacy/hell', 'exe'));
					hellBgLegacy.scrollFactor.set(1, 1);
					hellBgLegacy.scale.set(1.2, 1.2);
					hellBgLegacy.antialiasing = false;
					add(hellBgLegacy);
				}
          
			case 'founded':

				defaultCamZoom = 0.95;

				GameOverSubstate.loopSoundName = 'normalcd-loop';
				GameOverSubstate.endSoundName = 'normalcd-retry';
	
				normalBg = new FlxSprite(-150, -200);
				normalBg.loadGraphic(Paths.image('normal/bg', 'exe'));
				normalBg.scrollFactor.set(1, 1);
				normalBg.antialiasing = ClientPrefs.globalAntialiasing;
				normalBg.scale.set(1.2, 1.2);
				add(normalBg);
	
				normalDoor = new FlxSprite(-245, -760);
				normalDoor.frames = Paths.getSparrowAtlas('normal/doorbangin', 'exe');
				normalDoor.animation.addByPrefix('idle', 'doorbangin', 24, false);
				normalDoor.scrollFactor.set(1, 1);
				normalDoor.antialiasing = ClientPrefs.globalAntialiasing;
				normalDoor.scale.set(1.2, 1.2);
	
				normalScreen = new FlxSprite(1600, 150);
				normalScreen.frames = Paths.getSparrowAtlas('normal/bigscreen', 'exe');
				normalScreen.animation.addByPrefix('idle', 'bigscreenstaticfinal', 24, true);
				normalScreen.animation.play('idle');
				normalScreen.scrollFactor.set(1, 1);
				normalScreen.antialiasing = ClientPrefs.globalAntialiasing;
				normalScreen.alpha = 0.5;
				normalScreen.scale.set(1.2, 1.2);
					
	
				normalChars = new FlxSprite(1650, 235);
				normalChars.frames = Paths.getSparrowAtlas('normal/charactersappear', 'exe');
				normalChars.animation.addByPrefix('chaotix', 'Chaotix Appears', 24, false);
				normalChars.animation.addByPrefix('curse', 'Curse Appears', 24, false);
				normalChars.animation.addByPrefix('rex', 'Revived Appears', 24, false);
				normalChars.animation.addByPrefix('rodent', 'Rodent Appears', 24, false);
				normalChars.animation.addByPrefix('spoiled', 'Spoiled Appears', 24, false);
				normalChars.scrollFactor.set(1, 1);
				normalChars.antialiasing = ClientPrefs.globalAntialiasing;
				normalChars.scale.set(1.2, 1.2);
				add(normalChars);
				add(normalScreen);
	
				normalTv = new FlxSprite(-150, -200);
				normalTv.loadGraphic(Paths.image('normal/tv', 'exe'));
				normalTv.scrollFactor.set(1, 1);
				normalTv.antialiasing = ClientPrefs.globalAntialiasing;
				normalTv.scale.set(1.2, 1.2);
				add(normalTv);
	
				normalShadow = new FlxSprite(-150, -220);
				normalShadow.loadGraphic(Paths.image('normal/shadow', 'exe'));
				normalShadow.scrollFactor.set(1, 1);
				normalShadow.antialiasing = ClientPrefs.globalAntialiasing;
				normalShadow.scale.set(1.2, 1.2);
				normalShadow.alpha = 0.8;
				add(normalShadow);
	
				normalVg = new FlxSprite(-150, -200);
				normalVg.loadGraphic(Paths.image('normal/vignette', 'exe'));
				normalVg.scrollFactor.set(1, 1);
				normalVg.antialiasing = ClientPrefs.globalAntialiasing;
				normalVg.scale.set(1.2, 1.2);
	
				normalFg = new FlxSprite(-150, -200);
				normalFg.loadGraphic(Paths.image('normal/front', 'exe'));
				normalFg.scrollFactor.set(1.1, 1);
				normalFg.antialiasing = ClientPrefs.globalAntialiasing;
				normalFg.scale.set(1.2, 1.2);
	
				case 'curse':
					//THE CURSE OF X SEETHES AND MALDS
	
					defaultCamZoom = 0.60;
	
					curseSky = new FlxSprite(-300, -150);
					curseSky.loadGraphic(Paths.image('curse/background', 'exe'));
					curseSky.scrollFactor.set(1, 1);
					curseSky.antialiasing = ClientPrefs.globalAntialiasing;
					curseSky.scale.set(1.5, 1.5);
					add(curseSky);
	
					curseTrees = new FlxSprite(-300, -150);
					curseTrees.loadGraphic(Paths.image('curse/treesfarback', 'exe'));
					curseTrees.scrollFactor.set(1, 1);
					curseTrees.antialiasing = ClientPrefs.globalAntialiasing;
					curseTrees.scale.set(1.5, 1.5);
					add(curseTrees);
	
					curseTreesTwo = new FlxSprite(-300, -150);
					curseTreesTwo.loadGraphic(Paths.image('curse/treesback', 'exe'));
					curseTreesTwo.scrollFactor.set(1, 1);
					curseTreesTwo.antialiasing = ClientPrefs.globalAntialiasing;
					curseTreesTwo.scale.set(1.5, 1.5);
					add(curseTreesTwo);
	
					curseFountain = new FlxSprite(350, 0);
					curseFountain.frames = Paths.getSparrowAtlas('curse/goofyahfountain', 'exe');
					curseFountain.animation.addByPrefix('fotan', "fountainlol", 24, true);
					curseFountain.animation.play('fotan');
					curseFountain.scale.x = 1.4;
					curseFountain.scale.y = 1.4;
					add(curseFountain);
	
					curseFloor = new FlxSprite(-250, 700);
					curseFloor.loadGraphic(Paths.image('curse/floor', 'exe'));
					curseFloor.scrollFactor.set(1, 1);
					curseFloor.antialiasing = ClientPrefs.globalAntialiasing;
					curseFloor.scale.set(1.5, 1.5);
					add(curseFloor);
	
					curseStatic = new FlxSprite(0, 0);
					curseStatic.frames = Paths.getSparrowAtlas('curse/staticCurse', 'exe');
					curseStatic.animation.addByPrefix('stat', "menuSTATICNEW instance 1", 24, true);
					curseStatic.animation.play('stat');
					curseStatic.alpha = 0.25;
					curseStatic.screenCenter();
					curseStatic.scale.x = 4;
					curseStatic.scale.y = 4;
					curseStatic.visible = false;
					//curseStatic.blend = LIGHTEN;
					add(curseStatic);

				case 'infinity-legacy':
					defaultCamZoom = 0.6;
		
					mazinBgLegacy = new BGSprite('mazin/infinitefun', -600, -120, 1, 0.9);
					mazinBgLegacy.scale.x = 1.75;
					mazinBgLegacy.scale.y = 1.75;
					mazinBgLegacy.antialiasing = false;
					add(mazinBgLegacy);
		
					mazinTreesLegacy = new BGSprite('mazin/trees', -600, -120, 1, 0.9);
					mazinTreesLegacy.scale.x = 1.75;
					mazinTreesLegacy.scale.y = 1.75;
					add(mazinTreesLegacy);
		
					mazinBushesLegacy = new BGSprite('mazin/bushes', -600, -120, 1, 0.9);
					mazinBushesLegacy.scale.x = 1.75;
					mazinBushesLegacy.scale.y = 1.75;
					add(mazinBushesLegacy); 
		
					mazinPlatformLegacy = new BGSprite('mazin/centermotain', -500, -120, 1, 0.9);
					mazinPlatformLegacy.scale.x = 1.75;
					mazinPlatformLegacy.scale.y = 1.75;
					add(mazinPlatformLegacy);
							
					mazinRightPlatformLegacy = new BGSprite('mazin/rightmotain', -400, -50, 1.1, 0.9);
					mazinRightPlatformLegacy.scale.x = 1.45;
					mazinRightPlatformLegacy.scale.y = 1.45;
					add(mazinRightPlatformLegacy);
		
					mazinLeftPlatformLegacy = new BGSprite('mazin/leftmotain', -700, -50, 1.1, 0.9);
					mazinLeftPlatformLegacy.scale.x = 1.45;
					mazinLeftPlatformLegacy.scale.y = 1.45;
					add(mazinLeftPlatformLegacy);
		
					mazinOverlayLegacy = new BGSprite('mazin/overlaybush', -600, -120, 1, 0.9);
					mazinOverlayLegacy.scale.x = 1.75;
					mazinOverlayLegacy.scale.y = 1.75;
		
				case 'frontier-legacy':
					defaultCamZoom = 0.6;

				        luaArray.push(new FunkinLua(Paths.lua("final-frontier-legacy/script")));
		
					frontierBgLegacy = new BGSprite('frontier/sky', -600, -120, 1, 0.9);
					frontierBgLegacy.scale.x = 2.0;
					frontierBgLegacy.scale.y = 2.0;
					add(frontierBgLegacy);
	
					frontierDebris = new FlxTypedGroup<BGSprite>();
					add(frontierDebris);
		
					var debris1:BGSprite = new BGSprite('frontier/1', 1100, 0, 1, 0.9);
					debris1.scale.y = 1.1;
					debris1.scale.x = 1.1;
					frontierDebris.add(debris1);
		
					var debris2:BGSprite = new BGSprite('frontier/2', 900, -250, 1, 0.9);
					debris2.scale.y = 1.1;
					debris2.scale.x = 1.1;
					frontierDebris.add(debris2);
		
					var debris3:BGSprite = new BGSprite('frontier/3', -1000, 150, 1, 0.9);
					debris3.scale.y = 1.3;
					debris3.scale.x = 1.3;
					frontierDebris.add(debris3);
		
					var debris4:BGSprite = new BGSprite('frontier/4', -1500, -70, 1, 0.9);
					debris4.scale.y = 1.3;
					debris4.scale.x = 1.3;
					frontierDebris.add(debris4);
		
					var debris5:BGSprite = new BGSprite('frontier/5', -1500, -80, 1, 0.9);
					debris5.scale.y = 1.2;
					debris5.scale.x = 1.2;
					frontierDebris.add(debris5);
		
					var debris6:BGSprite = new BGSprite('frontier/6', 1500, 400, 1, 0.9);
					debris6.scale.y = 1.5;
					debris6.scale.x = 1.5;
					frontierDebris.add(debris6);
		
					var debris7:BGSprite = new BGSprite('frontier/7', 1650, 500, 1, 0.9);
					debris7.scale.y = 1.5;
					debris7.scale.x = 1.5;
					frontierDebris.add(debris7);
		
					var debris8:BGSprite = new BGSprite('frontier/8', 1700, 550, 1, 0.9);
					debris8.scale.y = 1.5;
					debris8.scale.x = 1.5;
					frontierDebris.add(debris8);
		
					frontierEmeraldsLegacy = new FlxSprite(-900, -160);
					frontierEmeraldsLegacy.frames = Paths.getSparrowAtlas('frontier/emeralds', 'exe');
					frontierEmeraldsLegacy.animation.addByPrefix('FUCK', 'emeraldsBOP', 24);
					frontierEmeraldsLegacy.animation.play('FUCK');
					frontierEmeraldsLegacy.scale.x = 1.4;
					frontierEmeraldsLegacy.scale.y = 1.4;
					frontierEmeraldsLegacy.scrollFactor.set(1, 1);
		
					add(frontierEmeraldsLegacy);
		
					frontierMasterEmeraldLegacy = new FlxSprite(-600, -160);
					frontierMasterEmeraldLegacy.frames = Paths.getSparrowAtlas('frontier/masteremerald', 'exe');
					frontierMasterEmeraldLegacy.animation.addByPrefix('FUCK', 'emeraldglow', 24);
					frontierMasterEmeraldLegacy.animation.play('FUCK');
					frontierMasterEmeraldLegacy.scale.x = 1.4;
					frontierMasterEmeraldLegacy.scale.y = 1.4;
					frontierMasterEmeraldLegacy.scrollFactor.set(1, 1);
					frontierMasterEmeraldLegacy.visible = false;	
					add(frontierMasterEmeraldLegacy);
		
					frontierGroundLegacy = new BGSprite('frontier/fgground', -600, -120, 1, 0.9);
					frontierGroundLegacy.scale.x = 2.0;
					frontierGroundLegacy.scale.y = 2.0;
					add(frontierGroundLegacy);

			default: //lol
				GameOverSubstate.characterName = 'bfii-death';

				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		dadGhost = new FlxSprite();
		bfGhost = new FlxSprite();

		add(gfGroup); //Needed for blammed lights(for now not)

		add(bfGhost);
		add(dadGhost);

		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end


		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [#if android Generic.returnPath() + 'assets/scripts/',#end Paths.getPreloadPath('scripts/')];
			
		#if MODS_ALLOWED 
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end


		// STAGE SCRIPTS
		#if LUA_ALLOWED
		var doPush:Bool = false;
		#if MODS_ALLOWED
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
	        #if android 
		var luaFile:String = Generic.returnPath() + 'assets/stages/' + curStage + '.lua';
		#else
		var luaFile:String = Paths.getPreloadPath('stages/') + curStage + '.lua';
		#end
		if (FileSystem.exists(luaFile)) {
		    doPush = true;
		}
		#end

		if(doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		//Gf's versions for stages(outdated for now)
		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

	        //opponent's double note ghost
		dadGhost.visible = false;
		dadGhost.antialiasing = ClientPrefs.globalAntialiasing;
		dadGhost.alpha = 0.6;
		dadGhost.scale.copyFrom(dad.scale);
		dadGhost.updateHitbox();

		//bf's double note ghost
		bfGhost.visible = false;
		bfGhost.antialiasing = ClientPrefs.globalAntialiasing;
		bfGhost.alpha = 0.6;
		bfGhost.scale.copyFrom(boyfriend.scale);
		bfGhost.updateHitbox();
						    
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		//Uzumaki yeah 
		theStatic = new FlxSprite(0, 0);
		theStatic.frames = Paths.getSparrowAtlas('staticc', 'exe');
		theStatic.animation.addByPrefix('stat', "staticc", 24, true);
		theStatic.animation.play('stat');
		theStatic.cameras = [camOther];
		theStatic.setGraphicSize(FlxG.width, FlxG.height);
		theStatic.screenCenter();

		var centerP = new FlxSprite(0, 0);
		centerP.screenCenter(XY);

		center = FlxPoint.get(centerP.x, centerP.y);

		//what should we add before singers
		switch(curStage)
		{
			case 'entrance':
				add(entranceSpookyOver);
				add(entranceOver);

				/*dad.y += 225;
				gf.x += 175;
				gf.y += 250;
				boyfriend.x += 275;
				boyfriend.y += 235;*/
				theStatic.visible = false;
				add(theStatic);

			case 'entrance-legacy':
				add(theStatic);

				gfGroup.visible = false;
				theStatic.visible = false;

			case 'infinity-legacy':
				add(mazinOverlayLegacy);
				boyfriend.x -= 140;
				boyfriend.y -= 175;
				dad.x -= 70;
				dad.y -= 175;
	
				gfGroup.visible = false;
			
			//fml bruv raz is such a mEANIE
			case 'soulless':
				/*dad.x += 15;
				gf.x += 975;
				gf.y += 75;
				boyfriend.x += 275;
				boyfriend.y += 15;*/

				dadGroup.visible = true;
				boyfriendGroup.visible = true;
				theStatic.visible = false;
				add(theStatic);

			case "soulless-legacy":
				add(theStatic);
				add(soulFogLegacy);
				gfGroup.visible = false;
				dad.x -= 60;
				boyfriend.x += 100;

				theStatic.visible = false;

			case "frontier-legacy":
				theStatic.visible = false;
				add(theStatic);

				itemFly = frontierEmeraldsLegacy;
				itemFly2 = frontierMasterEmeraldLegacy;

			case 'vista':
				add(amyBop);
				add(knuxBopFucked);
				add(fuckedTails);

			case "wechnia":
				add(wechniaP9);
				add(wechniaP10);

				if (SONG.song.toLowerCase() == "color-crash") {
					defaultZoomin = false;
				    camHUD.alpha = 0;
				}

			case "horizon":
			    add(horizonFGp1);
			    add(horizonFGp2);
			    add(horizonFGp3);
			    add(horizonFGp4);

				add(horizonSpookyFGp1);
				add(horizonSpookyFGp2);

				if (SONG.song.toLowerCase() == "my-horizon") {
				    camHUD.alpha = 0;
				}

			case 'horizon-legacy':
				boyfriend.y += 68;
				gf.x += 375;
				gf.y += 575;
				dad.x -= 90;
				dad.y += 70;
				if (SONG.song.toLowerCase() == 'our-horizon-legacy')
					{
						add(horizonKnucklesLegacy);
						add(horizonVectorLegacy);
					}

			case 'founded':
				dad.visible = false;
				dad.x -= 500;
				add(normalDoor);
				add(normalFg);
				add(normalVg);

				if (SONG.song.toLowerCase() == 'found-you-legacy')
				{
				    camHUD.visible = false;
				}

			case 'chotix-legacy':
				gf.visible = false;
				dad.setPosition(-500, 350);

			case 'curse-legacy':
				gf.x -= 50;
				gf.y -= 100;
				boyfriend.x += 70;

			case 'chotix':
				gf.y -= 50;
				dad.x -= 25;
				//dad.setPosition(-500, 350);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, upscrollOffset).makeGraphic(FlxG.width, 10);
		//if(ClientPrefs.downScroll) strumLine.y = downscrollOffset;
		strumLine.scrollFactor.set();

                add(noteGroup);

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("chaotix.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (SONG.song.toLowerCase() == 'found-you-legacy') {
			timeTxt.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song.replace("-", " ");
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;

		//this time bar for breakout faker part & for my horizon
		fakeTimeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'fakeSongPercent', 0, 100);
		fakeTimeBar.scrollFactor.set();
		fakeTimeBar.numDivisions = 1000;
		fakeTimeBar.visible = showTime;

		add(timeBarBG);
		add(timeBar);
		add(timeTxt);

		timeBarBG.sprTracker = timeBar;

		playFields = new FlxTypedGroup<PlayField>();
		noteGroup.add(playFields);
		noteGroup.add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		//Pixel bf cycling feets(For New BF)
		bfSEFeet = new FlxSprite();
		bfSEFeet.frames = Paths.getSparrowAtlas('soulless/SEbfFeet', 'exe');
		bfSEFeet.animation.addByPrefix('idle', 'SEbfFeet Run', 24, true);
		bfSEFeet.animation.play('idle');
		bfSEFeet.screenCenter();
		bfSEFeet.visible = false;
		bfSEFeet.scrollFactor.set(1, 1);
		bfSEFeet.antialiasing = false;
		bfSEFeet.scale.set(6, 6);

		barbedWires = new FlxTypedGroup<ShakableSprite>();
		for(shit in 0...6){
			var wow = shit + 1;
			var wire:ShakableSprite = new ShakableSprite().loadGraphic(Paths.image('barbedWire/' + wow));
			wire.scrollFactor.set();
			wire.antialiasing = ClientPrefs.globalAntialiasing;
			wire.setGraphicSize(FlxG.width, FlxG.height);
			wire.updateHitbox();
			wire.screenCenter(XY);
			wire.alpha = 0;
			wire.extraInfo.set("inUse",false);
			wire.cameras = [camOther];
			barbedWires.add(wire);
		}

		wireVignette = new FlxSprite().loadGraphic(Paths.image('black_vignette', 'exe'));
		wireVignette.scrollFactor.set();
		wireVignette.antialiasing = ClientPrefs.globalAntialiasing;
		wireVignette.setGraphicSize(FlxG.width, FlxG.height);
		wireVignette.updateHitbox();
		wireVignette.screenCenter(XY);
		wireVignette.alpha = 0;
		wireVignette.cameras = [camOther];
	
		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
			#else
			var luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
			        luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
			        if(FileSystem.exists(luaToLoad))
			        {
				      luaArray.push(new FunkinLua(luaToLoad));
			        }
			}
			#else
			var luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			#end
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);


		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		camGame2.follow(camFollowPos, LOCKON, 1);
		camGame2.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		// healthBar
		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'targetHP', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		healthBarOver = new FlxSprite().loadGraphic(Paths.image("healthBarOver"));
		healthBarOver.scrollFactor.set();
		healthBarOver.visible = !ClientPrefs.hideHud;
		healthBarOver.alpha = ClientPrefs.healthBarAlpha;
		add(healthBarOver);

		//player's health icon
		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		//opponent's health icon
		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("chaotix.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (SONG.song.toLowerCase() == 'found-you-legacy') {
			scoreTxt.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		if (ClientPrefs.downScroll) scoreTxt.y -= 75;
		add(scoreTxt);

		songNameHUD = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		songNameHUD.setFormat(Paths.font("chaotix.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (SONG.song.toLowerCase() == 'found-you-legacy') {
			songNameHUD.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}
		songNameHUD.scrollFactor.set();
		songNameHUD.borderSize = 1.25;
		songNameHUD.visible = !ClientPrefs.hideHud;
		if (!ClientPrefs.downScroll && SONG.song.toLowerCase().endsWith("legacy")) {
			songNameHUD.y -= 100;
		} else if (!ClientPrefs.downScroll && !SONG.song.toLowerCase().endsWith("legacy")) {
			songNameHUD.y -= 75;
		}
		add(songNameHUD);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("chaotix.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (SONG.song.toLowerCase() == 'found-you-legacy') {
			botplayTxt.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) botplayTxt.y = timeBarBG.y - 78;

		// create the custom hud
		trace(curSong.toLowerCase());
		if(hudStyle.exists(curSong.toLowerCase())){
			chaotixHUD = new FlxSpriteGroup(33, 0);
			songNameHUD.visible = !ClientPrefs.hideHud;
			var labels:Array<String> = [
				"score",
				"time",
				"misses"
			];
			var scale:Float = 3;
			var style:String = hudStyle.get(curSong.toLowerCase());
			switch(style) {
				case 'chotix':
					scale = 0.75;
			}

			for(i in 0...labels.length) {
				var name = labels[i];
				var y = 48 * (i+1);
				var label = new FlxSprite(0, y);
				switch (name){
					case 'rings':
						label.loadGraphic(Paths.image('sonicUI/$style/$name'), true, 83, 12);
						label.animation.add("blink", [0, 1], 2);
						label.animation.add("static", [0], 0);
					case 'fullcombo':
						label.loadGraphic(Paths.image('sonicUI/$style/$name'), true, 83, 12);
						label.animation.add("blink", [0, 1], 2);
					default:
						label.loadGraphic(Paths.image('sonicUI/$style/$name'));
				}

				label.setGraphicSize(Std.int(label.width * scale));
				label.updateHitbox();
				label.antialiasing=false;
				label.scrollFactor.set();
				chaotixHUD.add(label);
				var hasDisplay:Bool = false;
				var displayCount:Int = 0;
				var displayX:Float = 150;
				var dispVar:String = '';
				switch (name) {
					case 'rings':
						hasDisplay = true;
						displayCount = 3;
						displayX = 174;
						label.animation.play("blink", true);
						ringsLabel = label;
					case 'score':
						hasDisplay = true;
						displayCount = 7;
						dispVar = 'songScore';
					case 'fullcombo':
						hasDisplay = false;
						//fcLabel = label;
						label.animation.play("blink", true);
					case 'fc':
						hasDisplay = false;
						fcLabel = label;
						label.animation.play("SFC", true);
					case 'time':
						hasDisplay = false;
						hudMinute = new SonicNumber(150, y + (3 * scale), '0', style);
						hudMinute.setGraphicSize(Std.int(hudMinute.width * scale));
						hudMinute.updateHitbox();

						hudSeconds = new SonicNumberDisplay(198, y + (3 * scale), 2, scale, 0, style);
						hudMS = new SonicNumberDisplay(270, y + (3 * scale), 2, scale, 0, style);
						if(style=='chotix') {
							hudSeconds.x = 270;
							hudMS.x = 198;
							hudSeconds.blankCharacter = 'sex';
							hudMS.blankCharacter = 'sex';
						} else {
							hudSeconds.blankCharacter = '0';
							hudMS.blankCharacter = '0';
						}

						
						var singleQuote = new FlxSprite(171, y).loadGraphic(Paths.image('sonicUI/$style/colon'));
						singleQuote.setGraphicSize(Std.int(singleQuote.width * scale));
						singleQuote.updateHitbox();
						singleQuote.antialiasing=false;
						var doubleQuote = new FlxSprite(243, y).loadGraphic(Paths.image('sonicUI/$style/quote'));
						doubleQuote.setGraphicSize(Std.int(doubleQuote.width * scale));
						doubleQuote.updateHitbox();
						doubleQuote.antialiasing=false;

						singleQuote.x = 171;
						doubleQuote.x = 243;
						singleQuote.y = y;
						doubleQuote.y = y;

						chaotixHUD.add(singleQuote);
						chaotixHUD.add(doubleQuote);
						chaotixHUD.add(hudMinute);
						chaotixHUD.add(hudSeconds);
						chaotixHUD.add(hudMS);
					case 'misses':
						hasDisplay = true;
						displayCount = 3;
						displayX = 174;
						dispVar = 'songMisses';
						fcLabel = new FlxSprite(174 + ((8 * 3) * (displayCount+1)), y);
						fcLabel.loadGraphic(Paths.image('sonicUI/$style/fc'));
						fcLabel.loadGraphic(Paths.image('sonicUI/$style/fc'), true, Std.int(fcLabel.width/4), Std.int(fcLabel.height/2));
						fcLabel.animation.add("SFC", [0, 4], 0);
						fcLabel.animation.add("GFC", [1, 5], 0);
						fcLabel.animation.add("FC", [2, 6], 0);
						fcLabel.animation.add("SDCB", [3, 7], 0);
						fcLabel.setGraphicSize(Std.int(fcLabel.width * scale));
						fcLabel.updateHitbox();
						fcLabel.antialiasing=false;
						fcLabel.scrollFactor.set();
						fcLabel.animation.play("SFC", true);
						chaotixHUD.add(fcLabel);
				}
				if(hasDisplay) {
					var dis:SonicNumberDisplay = new SonicNumberDisplay(displayX, y + (3 * scale), displayCount, scale, 0, style, this, dispVar);
					hudDisplays.set(name, dis);
					chaotixHUD.add(dis);
				}
			}

			add(chaotixHUD);

			if (!ClientPrefs.downScroll) {
				for(member in chaotixHUD.members)
					member.y = (FlxG.height-member.height-member.y);
			}
			chaotixHUD.cameras = [camHUD];

		        switch (SONG.song.toLowerCase())
			{
				case 'soulless-endeavors' | 'soulless-endeavors-legacy':
			                chaotixHUD.visible = false;		
		        }
		}

		if (chaotixHUD != null && chaotixHUD.visible) {
			healthBar.x += 150;
			iconP1.x = 1025;
			iconP2.x = 400;
			healthBarBG.x += 150;
			timeBar.visible = false;
			remove(scoreTxt);
			remove(songNameHUD);
			remove(fakeTimeBar);
			remove(timeBarBG);
			remove(timeTxt);
		}
		else 
		{
		        iconP1.x = 875;
		        iconP2.x = 250;
		}

		noteGroup.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarOver.cameras = [camHUD];
		songNameHUD.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		fakeTimeBar.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		startCircle.cameras = [camOther];
		startText.cameras = [camOther];
		blackFuck.cameras = [camOther];

		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/') #if android, Generic.returnPath() + 'assets/data/' + Paths.formatToSongPath(SONG.song) + '/' #end];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
		        if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		add(barbedWires);
		add(wireVignette);

		var daSong:String = Paths.formatToSongPath(curSong);
	
                add(blackFuck);

                startCircle.loadGraphic(Paths.image('openings/' + daSong + '_title_card', 'exe'));
                startCircle.frames = Paths.getSparrowAtlas('openings/' + daSong + '_title_card', 'exe');
                startCircle.animation.addByPrefix('idle', daSong + '_title', 24, false);

		switch (SONG.song.toLowerCase())
		{
			case 'cascade':
				startCircle.scale.set(2, 1.75);
			case "my-horizon":
                                startCircle.scale.set(1, 1);
			default:
                                startCircle.scale.set(2, 1.5);
				if (SONG.song.toLowerCase().endsWith("-legacy")) {
			                startCircle.scale.set(1, 1);
				}
		}
		    
                startCircle.alpha = 0;
                startCircle.screenCenter();
                add(startCircle);

		playTitleCardAnimation(daSong);
	
		RecalculateRating();
	
		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) CoolUtil.precacheSound('hitsound');
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		if (PauseSubState.songName != null) {
			CoolUtil.precacheMusic(PauseSubState.songName);
		} else if(ClientPrefs.pauseMusic != 'None') {
			CoolUtil.precacheMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song.replace("-", " "), iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		switch (SONG.song.toLowerCase())
		{
			case "test" | "endless-legacy" | "found-you-legacy":
				startCircle.visible = false;
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		super.create();

	        Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	        #if mobile
		addMobileControls(false, true);  
                mobileControls.visible = false;
		#end
	}
        private function strumsPositions():Void {
		if (!ClientPrefs.opponentStrums) {
			opponentStrums.baseAlpha = 0;
			modManager.setValue('alpha',1,1);

		}
		else if (ClientPrefs.middleScroll) {
			opponentStrums.baseAlpha = 0.35;
			modManager.setValue('alpha',0.65,1);
			modManager.setValue('opponentSwap',0.5);
		}
		
		if (ClientPrefs.middleScroll && !ClientPrefs.opponentStrums) {
			opponentStrums.baseAlpha = 0;
			modManager.setValue('alpha', 1, 1);
			modManager.setValue('opponentSwap', 0.5);
		}
	}

        function playTitleCardAnimation(daSong:String, delay:Float = 1, fadeOutTime:Float = 2, startDelay:Float = 0.3) {
            if (daSong != "cascade") {
                new FlxTimer().start(delay, function(tmr:FlxTimer)
                {
                    FlxTween.tween(startCircle, {alpha: 1}, 0.5, {ease: FlxEase.cubeInOut});
                });

                new FlxTimer().start(2.2, function(tmr:FlxTimer)
                {
                    FlxTween.tween(blackFuck, {alpha: 0}, fadeOutTime, {
                        onComplete: function(twn:FlxTween)
                        {
                            remove(blackFuck);
                            blackFuck.destroy();
                            startCircle.animation.play('idle');
                        }
                    });
                    FlxTween.tween(startCircle, {alpha: 1}, 4.25, {
                        onComplete: function(twn:FlxTween)
                        {
                            remove(startCircle);
                            startCircle.destroy();
                        }
                    });
                });

                new FlxTimer().start(startDelay, function(tmr:FlxTimer)
                {
                    startCountdown();
                    strumsPositions();
                });
            }
            else if (SONG.song.toLowerCase() == "found-you-legacy") {
                snapCamFollowToPos(700, 400);
                new FlxTimer().start(0, function(tmr:FlxTimer)
                {
                    FlxG.camera.focusOn(camFollowPos.getPosition());
                });
                camHUD.visible = false;
                startCountdown();
                strumsPositions();
            }
            else {
                new FlxTimer().start(0.05, function(tmr:FlxTimer)
                {
                    FlxTween.tween(startCircle, {alpha: 1}, 0.225, {ease: FlxEase.cubeInOut});
                });

                new FlxTimer().start(1.125, function(tmr:FlxTimer)
                {
                    FlxTween.tween(blackFuck, {alpha: 0}, 1.725, {
                        onComplete: function(twn:FlxTween)
                        {
                            remove(blackFuck);
                            blackFuck.destroy();
                            startCircle.animation.play('idle');
                        }
                    });
                    FlxTween.tween(startCircle, {alpha: 1}, 5, {
                        onComplete: function(twn:FlxTween)
                        {
                            remove(startCircle);
                            startCircle.destroy();
                        }
                    });
                });

                new FlxTimer().start(4.7725, function(tmr:FlxTimer)
                {
                    startCountdown();
                    strumsPositions();
                });
            }
	}


	var newIcon:String;

        public function addShaderToCamera(cam:String,effect:ShaderEffect) {
	      switch(cam.toLowerCase()) {
	            case 'camhud' | 'hud':
		          camHUDShaders.push(effect);
			  var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
			  for(i in camHUDShaders) {
			        newCamEffects.push(new ShaderFilter(i.shader));
			  }
			  camHUD.setFilters(newCamEffects);
		    case 'camother' | 'other':
			  camOtherShaders.push(effect);
		          var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
			  for(i in camOtherShaders) {
			        newCamEffects.push(new ShaderFilter(i.shader));
			  }
			  camOther.setFilters(newCamEffects);
		    case 'camgame' | 'game':
			  camGameShaders.push(effect);
			  var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
			  for(i in camGameShaders) {
			        newCamEffects.push(new ShaderFilter(i.shader));
			  }
			  camGame.setFilters(newCamEffects);
		    default:
			  if (modchartSprites.exists(cam)) {
				Reflect.setProperty(modchartSprites.get(cam),"shader",effect.shader);
			  } else if (modchartTexts.exists(cam)) {
				Reflect.setProperty(modchartTexts.get(cam),"shader",effect.shader);
			  } else {
				var OBJ = Reflect.getProperty(PlayState.instance,cam);
				Reflect.setProperty(OBJ,"shader", effect.shader);
			  }	
		 }
	}

        public function removeShaderFromCamera(cam:String,effect:ShaderEffect) {
		          switch(cam.toLowerCase()) {
		                  case 'camhud' | 'hud': 
                                            camHUDShaders.remove(effect);
                                            var newCamEffects:Array<BitmapFilter>=[];
                                            for(i in camHUDShaders){
                                                    newCamEffects.push(new ShaderFilter(i.shader));
                                            }
                                   camHUD.setFilters(newCamEffects);
			           case 'camother' | 'other': 
				            camOtherShaders.remove(effect);
				            var newCamEffects:Array<BitmapFilter>=[];
				            for(i in camOtherShaders){
				                   newCamEffects.push(new ShaderFilter(i.shader));
				            }
				            camOther.setFilters(newCamEffects);
			           default: 
				            camGameShaders.remove(effect);
				            var newCamEffects:Array<BitmapFilter>=[];
				            for(i in camGameShaders){
				                    newCamEffects.push(new ShaderFilter(i.shader));
				            }
				            camGame.setFilters(newCamEffects);
		              }
	}

        public function clearShaderFromCamera(cam:String){
		             switch(cam.toLowerCase()) {
			           case 'camhud' | 'hud': 
				           camHUDShaders = [];
				           var newCamEffects:Array<BitmapFilter>=[];
				           camHUD.setFilters(newCamEffects);
			           case 'camother' | 'other': 
				           camOtherShaders = [];
				           var newCamEffects:Array<BitmapFilter>=[];
				           camOther.setFilters(newCamEffects);
			           default: 
				           camGameShaders = [];
				           var newCamEffects:Array<BitmapFilter>=[];
				           camGame.setFilters(newCamEffects);
		             }
		
	  
	}

        public function getXPosition(diff:Float, direction:Int, player:Int):Float
	{
		var x:Float = (FlxG.width / 2) - Note.swagWidth - 54 + Note.swagWidth * direction;
		if (!ClientPrefs.middleScroll)
		{
			switch (player)
			{
				case 0:
					x += FlxG.width / 2 - Note.swagWidth * 2 - 100;
				case 1:
					x -= FlxG.width / 2 - Note.swagWidth * 2 - 100;
			}
		}
		x -= 56;

		return x;
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		#if MODS_ALLOWED
		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));
		#elseif ((MODS_ALLOWED && LUA_ALLOWED) || (!MODS_ALLOWED && LUA_ALLOWED))
		#if !android
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('shaders/');
		#else
		var foldersToCheck:Array<String> = [Generic.returnPath() + 'assets/shaders/'];
	        #end
		#end

		#if MODS_ALLOWED
		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
		FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWES
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		#end

		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

        public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	function fireWorksDeluxe()
	{
		horizonRedLegacy.animation.play('idle');

		new FlxTimer().start(2, function(tmr:FlxTimer) {
			horizonPurpurLegacy.animation.play('idle');
		});

		new FlxTimer().start(0.5, function(tmr:FlxTimer) {
			horizonYellowLegacy.animation.play('idle');
		});

	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.cameras = [camHUD];
		add(bg);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		#if (hxCodec < "3.0.0")
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#elseif hxvlc
		video.load(filepath);
		video.play();
		video.onEndReached.add(function(){
			video.dispose();
			startAndEnd();
			return;
		});
		#else
		video.play(filepath);
		video.onEndReached.add(function(){
			video.dispose();
			startAndEnd();
			return;
		});
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			playTitleCardAnimation(Paths.formatToSongPath(curSong));
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countDownSprites:Array<FlxSprite> = [];
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		#if mobile
                mobileControls.visible = true;
		if (ClientPrefs.isvpad && MobileControls.mode != 'Hitbox' && MobileControls.mode != 'Keyboard'){
			addVirtualPad(NONE, NONE);
			_virtualpad.visible = true;
		}
                #end

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

                        playerStrums = new PlayField(ClientPrefs.middleScroll ? (FlxG.width / 2):(FlxG.width / 2 + (FlxG.width / 4)), strumLine.y, 4, boyfriend, true, cpuControlled, 0);
			opponentStrums = new PlayField(ClientPrefs.middleScroll?(FlxG.width / 2):(FlxG.width/2 - (FlxG.width/4)), strumLine.y, 4, dad, false, true, 1);

			if (!ClientPrefs.opponentStrums) {
				opponentStrums.baseAlpha = 0;
				
			}
			else if (ClientPrefs.middleScroll) {
				opponentStrums.baseAlpha = 0.35;
			}
			
			if (ClientPrefs.middleScroll && !ClientPrefs.opponentStrums) {
				opponentStrums.baseAlpha = 0;
			}

			opponentStrums.offsetReceptors = ClientPrefs.middleScroll;

			playerStrums.noteHitCallback = goodNoteHit;
			opponentStrums.noteHitCallback = opponentNoteHit;

			opponentStrums.generateReceptors();
			playerStrums.generateReceptors();
			
			playerStrums.fadeIn(isStoryMode || skipArrowStartTween);
			opponentStrums.fadeIn(isStoryMode || skipArrowStartTween);

			playFields.add(opponentStrums);
                        playFields.add(playerStrums);

			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(!ClientPrefs.opponentStrums) opponentStrums.members[i].visible = false;
			}

                        //modManager.setReceptors();
			modManager.receptors = [playerStrums.members, opponentStrums.members];
			modManager.registerDefaultModifiers();
			ModCharts.lesGo(this, modManager, SONG.song.toLowerCase());

			/*if (isPixelHUD)
				{
					healthBar.x += 150;
					iconP1.x += 150;
					iconP2.x += 150;
					healthBarBG.x += 150;
				}
			else
				{
					//lol
				}*/

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
					bfCamThing = [0, 0];
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
					dadCamThing = [0, 0];
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				switch (swagCounter)
				{
					case 0:
					case 1:
						var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						ready.scrollFactor.set();
						ready.updateHitbox();

						if (PlayState.isPixelStage)
							ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

						ready.screenCenter();
						ready.antialiasing = antialias;
						countDownSprites.push(ready);
						FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(ready);
								remove(ready);
								ready.destroy();
							}
						});
					case 2:
						var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						set.scrollFactor.set();

						if (PlayState.isPixelStage)
							set.setGraphicSize(Std.int(set.width * daPixelZoom));

						set.screenCenter();
						set.antialiasing = antialias;
						countDownSprites.push(set);
						FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(set);
								remove(set);
								set.destroy();
							}
						});
					case 3:
						var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						go.scrollFactor.set();

						if (PlayState.isPixelStage)
							go.setGraphicSize(Std.int(go.width * daPixelZoom));

						go.updateHitbox();

						go.screenCenter();
						go.antialiasing = antialias;
						countDownSprites.push(go);
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(go);
								remove(go);
								go.destroy();
							}
						});
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha * note.playField.baseAlpha;
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		vocals.time = time;
		vocals.play();
		Conductor.songPosition = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		barSongLength = songLength;
		if(SONG.song.toLowerCase() == 'breakout')
		{
			barSongLength = 89000;
		}

		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song.replace("-", " "), iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if (sys && MODS_ALLOWED)
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#elseif (!sys || !MODS_ALLOWES)
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		var lastBFNotes:Array<Note> = [null, null, null, null];
		var lastDadNotes:Array<Note> = [null, null, null, null];
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
			
				var pixelStage = isPixelStage;
				if(daStrumTime >= Conductor.stepToSeconds(895) && daStrumTime <= 151000 && SONG.song.toLowerCase() == 'soulless-endeavors' || daStrumTime >= Conductor.stepToSeconds(640) && daStrumTime <= 123000 && SONG.song.toLowerCase()=='soulless-endeavors-legacy')
					isPixelStage = true;
				if(SONG.song.toLowerCase() == 'our-horizon-legacy') {
					if (daStrumTime >= Conductor.stepToSeconds(2336) && daStrumTime <= Conductor.stepToSeconds(2848))
						isPixelStage = true;
					else if(daStrumTime >= Conductor.stepToSeconds(1000))
						isPixelStage = false;
	
				}	

                                var type:Dynamic = songNotes[3];
				if(!Std.isOfType(type, String)) type = ChartingState.noteTypeList[type]; 
				
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false);
				swagNote.row = Conductor.secsToRow(daStrumTime);
				if(noteRows[gottaHitNote?0:1][swagNote.row]==null)
					noteRows[gottaHitNote?0:1][swagNote.row]=[];
				noteRows[gottaHitNote ? 0 : 1][swagNote.row].push(swagNote);
				swagNote.noteType = type;
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
                                if(gottaHitNote){
					var lastBFNote = lastBFNotes[swagNote.noteData];
					if(lastBFNote!=null){
						if(Math.abs(swagNote.strumTime-lastBFNote.strumTime)<=3 ){
							swagNote.kill();
							continue;
						}
					}
					lastBFNotes[swagNote.noteData]=swagNote;
				}else{
					var lastDadNote = lastDadNotes[swagNote.noteData];
					if(lastDadNote!=null){
						if(Math.abs(swagNote.strumTime-lastDadNote.strumTime)<=3 ){
							swagNote.kill();
							continue;
						}
					}
					lastDadNotes[swagNote.noteData]=swagNote;
				}
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;
                                swagNote.ID = unspawnNotes.length;
				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						if(sustainNote==null || !sustainNote.alive) break;
						sustainNote.ID = unspawnNotes.length;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;

						unspawnNotes.push(sustainNote);
						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
				isPixelStage = pixelStage;
			}
			daBeats += 1;
		}
		lastDadNotes = null;
		lastBFNotes = null;
			
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	public var eventOccurred:Bool = false;

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
				eventOccurred = true;
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
   
   function removeStatics(player:Int)
	{
		var isPlayer:Bool = player==1;
		for(field in playFields.members){
			if(field.isPlayer==isPlayer || player==-1){
				field.clearReceptors();
			}
		}
	}

	// player 0 is opponent player 1 is player. Set to -1 to affect both players

	function resetStrumPositions(player:Int, ?baseX:Float){
		if(!generatedMusic)return;

		var isPlayer:Bool = player == 1;
		for (field in playFields.members)
		{
			if (field.isPlayer == isPlayer || player == -1)
			{
				var x = field.baseX;
				if(baseX!=null)x = baseX;

				field.forEachAlive( function(strum:StrumNote){
					strum.x = x;
					strum.postAddedToGroup();
					if (field.offsetReceptors)
						field.doReceptorOffset(strum);
				});
			}
		}
		
	}
	function regenStaticArrows(player:Int){
		var isPlayer:Bool = player==1;
		for(field in playFields.members){
			if(field.isPlayer==isPlayer || player==-1){
				field.generateReceptors();
				field.fadeIn(true);
			}
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}

			for (tween in piss)
			{
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && canResync)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (tween in piss) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;

			FlxTween.globalManager.forEach(function(tween:FlxTween)
				{
					tween.active = true;
				});
				FlxTimer.globalManager.forEach(function(timer:FlxTimer)
				{
					timer.active = true;
				});

			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song.replace("-", " "), iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song.replace("-", " "), iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song.replace("-", " "), iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song.replace("-", " "), iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song.replace("-", " "), iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var lastSection:Int = 0;
	var forFucksSake:Bool = false;

	override public function update(elapsed:Float)
	{
		switch (boyfriend.curCharacter) 
		{
			case "bf-running":
			        bfFeetAppear(1);
			        bfSEFeet.x = boyfriend.x + 350;
                                bfSEFeet.y = boyfriend.y + 262.5;
			default:
				bfSEFeet.visible = false;
			        bfFeetAppear(0);
		}
		
		/*if (boyfriend.curCharacter == "bf-running") {
			bfFeetAppear(1);
			bfSEFeet.x = boyfriend.x + 350;
                        bfSEFeet.y = boyfriend.y + 262.5;
		} else {
			bfSEFeet.visible = false;
			bfFeetAppear(0);
		}*/

		if (camGame != null)
		{
			camGame2.zoom = camGame.zoom;
			camGame2.setPosition(camGame.x,camGame.y);
		}

		if (SONG.song.toLowerCase() == "found-you-legacy" && curStep < 3359)
	        {
			changeIcon("bf", [50, 73, 127]);
		}

		/*if (!ClientPrefs.noteSplashes) {
         for (note => holdCover in noteHoldCovers) {
             remove(holdCover);
         }
         noteHoldCovers.clear();
         return;
      }*/

		//time bar personalized with dad health bar
		var dadColR = dad.healthColorArray[0];
		var dadColG = dad.healthColorArray[1];
		var dadColB = dad.healthColorArray[2];

		var dadColor = (0xFF << 24) | (dadColR << 16) | (dadColG << 8) | dadColB;

		fakeTimeBar.createFilledBar(0xFF000000, dadColor);
		timeBar.createFilledBar(0xFF000000, dadColor);

		wireVignette.alpha = FlxMath.lerp(wireVignette.alpha, hexes/6, elapsed / (1/60) * 0.2);
		if(hexes > 0){
			var hpCap = 1.6 - ((hexes-1) * 0.3);
			if(hpCap < 0)
				hpCap = 0;
			var loss = 0.005 * (elapsed/(1/120));
			var newHP = health - loss;
			if(newHP < hpCap){
				loss = health - hpCap;
				newHP = health - loss;
			}
			if(loss<0)
				loss = 0;
			if(newHP > hpCap)
				health -= loss;
		}

		emeraldTween += 0.01;
		//fjdslfdsakfkda;f;dajfdsajl;aa;jd AUUUUGHHHHH
		masterEmeraldTween += 0.02;
		dukeTween += 0.02;

		if (curStage == 'frontier-legacy')
		{
			itemFly.y += Math.sin(emeraldTween) * 0.5;
		}

		if (gray != null)
		gray.update(elapsed/2);

                if (ClientPrefs.shaders) {
		if(staticlol!=null){
			staticlol.iTime.value[0] = Conductor.songPosition / 1000;
			staticlol.alpha.value = [staticAlpha];
		}
		if(staticlmao!=null){
			staticlmao.iTime.value[0] = Conductor.songPosition / 1000;
			staticlmao.alpha.value = [staticAlpha];
		}
		
		if(glitchThingy!=null){
			glitchThingy.iTime.value[0] = Conductor.songPosition / 1000;
		}

		if(camFuckShader!=null)
			camFuckShader.iTime.value[0] = Conductor.songPosition / 1000;
		
		if(camGlitchShader!=null){
			camGlitchShader.iResolution.value = [FlxG.width, FlxG.height];
			camGlitchShader.iTime.value[0] = Conductor.songPosition / 1000;
			if(camGlitchShader.amount>=1)camGlitchShader.amount=1;
		}
		for(shader in glitchShaders){
			shader.iTime.value[0] += elapsed;
		}

		if (glitchinTime) {
			if(dad.curCharacter.startsWith("chaotix-beast-unpixel") || dad.curCharacter.startsWith("chaotix-beast-shaded"))
				camGlitchShader.amount = FlxMath.lerp(0.1, camGlitchShader.amount, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			else
				camGlitchShader.amount = FlxMath.lerp(0, camGlitchShader.amount, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}
        }

        if (ClientPrefs.timeBarType == 'Song Name' && !isPixelStage)
	    {
			songNameHUD.visible = false;
		}

		if (isPixelStage && !ClientPrefs.hideHud) 
		{
			songNameHUD.visible = true;
		}

		healthBarOver.x = healthBar.x - 4;
		healthBarOver.y = healthBar.y - 4.9;

		if (fucklesMode)
		{
			fucklesDrain = 0.00035; // copied from exe 2.0 lol sorry
			/*var reduceFactor:Float = combo / 150;
			if(reduceFactor>1)reduceFactor=1;
			reduceFactor = 1 - reduceFactor;
			health -= (fucklesDrain * (elapsed/(1/120))) * reduceFactor * drainMisses;*/
			if (SONG.song.toLowerCase() == "vista") {
				fucklesDrain = 0.00025;
			}
			if(drainMisses > 0)
				health -= (fucklesDrain * (elapsed/(1/120))) * drainMisses;
			else
				drainMisses = 0;
		}
		if(fucklesMode)
		{
			var newTarget:Float = FlxMath.lerp(targetHP, health, 0.1*(elapsed/(1/60)));
			if (Math.abs(newTarget - health)<.002)
				newTarget = health;

			targetHP = newTarget;
			
		} else 
		    targetHP = health;

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{

		}

		if (scoreRandom) {
			var timer:FlxTimer = new FlxTimer();
                        timer.start(2.5, function(timer:FlxTimer) {
                            randomizeSongName();
                            timer.start(2.5, function(timer:FlxTimer) {
                                randomizeSongName();
                            });
                        });
		} else {
			updateScoreText();
		}				

		if(hexes > 0)
		{
			hexTimer += elapsed;
			if (hexTimer >= 5)
			{
				hexTimer=0;
				hexes--;
				updateWires();
			}
		}

                modManager.update(elapsed);
                modManager.updateTimeline(curDecStep);

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			var offX:Float = 0;
			var offY:Float = 0;
			var focus:Character = boyfriend;
			if(SONG.notes[curSection] != null){
				if (gf != null && SONG.notes[curSection].gfSection)
				{
					focus = gf;
				}else if (!SONG.notes[curSection].mustHitSection)
				{
					focus = dad;
				}
			}
			if(focus.animation.curAnim != null){
				var name = focus.animation.curAnim.name;
				if(name.startsWith("singLEFT"))
					offX = -10;
				else if(name.startsWith("singRIGHT"))
					offX = 10;

				if(name.startsWith("singUP"))
					offY = -10;
				else if(name.startsWith("singDOWN"))
					offY = 10;
			}

			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x + offX, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y + offY, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE #if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause)
		{

			FlxTween.globalManager.forEach(function(tween:FlxTween)
			{
				tween.active = false;
			});

			FlxTimer.globalManager.forEach(function(timer:FlxTimer)
			{
				timer.active = false;
			});

			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}

				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song.replace("-", " "), iconP2.getCharacter());
				#end

			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			canResync = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
				{
					Conductor.songPosition += elapsed * 1000;
					if (Conductor.songPosition >= 0)
					{
						switch (curSong)
						{
							case 'my-horizon':
								startSong();
							default:
								startSong();
						}
					}
				}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					curTime = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / barSongLength);

					var songCalc:Float = (barSongLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);

					if(chaotixHUD != null) {
						curMS = Math.floor(curTime);
						var curSex:Int = Math.floor(curMS / 1000);
						if (curSex < 0)
							curSex = 0;

						var curMins = Math.floor(curSex / 60);
						curMS%=1000;
						curSex%=60;

						curMS = Math.round(curMS/10);
						var stringMins = Std.string(curMins).split("");
						if(curMins > 9) {
							hudMinute.number = '9';
							hudSeconds.displayed = 59;
							hudMS.displayed = 99;
						} else {
							hudMinute.number = stringMins[0];
							hudSeconds.displayed = curSex;
							hudMS.displayed = Std.int(curMS);
						}
					}

				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}


		if (defaultZoomin || !defaultZoomin || wowZoomin || holyFuckStopZoomin || pleaseStopZoomin || ohGodTheZooms)
		{
			var focus:Character = boyfriend;
			var curSection:Int = Math.floor(curStep / 16);
			if(SONG.notes[curSection]!=null) {
				if (gf != null && SONG.notes[curSection].gfSection)
				{
					focus = gf;
				} else if (!SONG.notes[curSection].mustHitSection)
				{
					focus = dad;
				}
			}

			switch (focus.curCharacter)
			{
				case "beast_chaotix-legacy":
					FlxG.camera.zoom = FlxMath.lerp(1.2, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
				case "dukep3-legacy":
					FlxG.camera.zoom = FlxMath.lerp(0.9, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
				default:
					FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			}
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		var roundedSpeed:Float = FlxMath.roundDecimal(SONG.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				var doSpawn:Bool= true;
				
				if(doSpawn) {
					if(dunceNote.desiredPlayfield != null)
						dunceNote.desiredPlayfield.addNote(dunceNote);
					else if (dunceNote.parent != null && dunceNote.parent.playField!=null)
						dunceNote.parent.playField.addNote(dunceNote);
					else{
						for(field in playFields.members){
							if(field.isPlayer == dunceNote.mustPress){
								field.addNote(dunceNote);
								break;
							}
						}
					}
					if(dunceNote.playField == null) {
						var deadNotes:Array<Note> = [dunceNote];
						for(note in dunceNote.tail)
							deadNotes.push(note);
						
						for(note in deadNotes) {
							note.active = false;
							note.visible = false;
							note.ignoreNote = true;

							note.kill();
							unspawnNotes.remove(note);
							note.destroy();
						}
						break;
					}
					notes.insert(0, dunceNote);
					dunceNote.spawned=true;
					var index:Int = unspawnNotes.indexOf(dunceNote);
					unspawnNotes.splice(index, 1);
				} else {
					var deadNotes:Array<Note> = [dunceNote];
					for(note in dunceNote.tail)
						deadNotes.push(note);
					
					for(note in deadNotes) {
						note.active = false;
						note.visible = false;
						note.ignoreNote = true;

						note.kill();
						unspawnNotes.remove(note);
						note.destroy();
					}
				}
			}
		}

                if (startedCountdown) {
			opponentStrums.forEachAlive(function(strum:StrumNote)
				{
					var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 1, strum, [], strum.vec3Cache);
					modManager.updateObject(curDecBeat, strum, pos, 1);
					strum.x = pos.x;
					strum.y = pos.y;
				});
				playerStrums.forEachAlive(function(strum:StrumNote)
				{
					var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, 0, strum, [], strum.vec3Cache);
					modManager.updateObject(curDecBeat, strum, pos, 0);
					strum.x = pos.x;
					strum.y = pos.y;
				});		
		}

		if (generatedMusic) {
                    if (!inCutscene) {
                        if (!cpuControlled) {
                            keyShit();
                        } else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration 
                                   && boyfriend.animation.curAnim.name.startsWith('sing') 
                                   && !boyfriend.animation.curAnim.name.endsWith('miss')) {
                            boyfriend.dance();
                        }
                    }

                    var fakeCrochet:Float = (60 / SONG.bpm) * 1000;

                    notes.forEachAlive(function(daNote:Note)
			{
				var field = daNote.playField;

				var strumX:Float = field.members[daNote.noteData].x;
				var strumY:Float = field.members[daNote.noteData].y;
				var strumAngle:Float = field.members[daNote.noteData].angle;
				var strumDirection:Float = field.members[daNote.noteData].direction;
				var strumAlpha:Float = field.members[daNote.noteData].alpha;
				var strumScroll:Bool = field.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX * (daNote.scale.x / daNote.baseScaleX);
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;
				var pN:Int = daNote.mustPress ? 0 : 1;
				var pos = modManager.getPos(daNote.strumTime, modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed),
					daNote.strumTime - Conductor.songPosition, curDecBeat, daNote.noteData, pN, daNote, [], daNote.vec3Cache);

				// trace(modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed));

				modManager.updateObject(curDecBeat, daNote, pos, pN);
				pos.x += daNote.offsetX;
				pos.y += daNote.offsetY;
				daNote.x = pos.x;
				daNote.y = pos.y;
				if (daNote.isSustainNote)
				{
					var futureSongPos = Conductor.songPosition + 75;
					var diff = daNote.strumTime - futureSongPos;
					var vDiff = modManager.getVisPos(futureSongPos, daNote.strumTime, songSpeed);

					var nextPos = modManager.getPos(daNote.strumTime, vDiff, diff, Conductor.getStep(futureSongPos) / 4, daNote.noteData, pN, daNote, [],
						daNote.vec3Cache);
					nextPos.x += daNote.offsetX;
					nextPos.y += daNote.offsetY;
					var diffX = (nextPos.x - pos.x);
					var diffY = (nextPos.y - pos.y);
					var rad = Math.atan2(diffY, diffX);
					var deg = rad * (180 / Math.PI);
					if (deg != 0)
						daNote.mAngle = (deg + 90);
					else
						daNote.mAngle = 0;
					
				}

                        	if(field.inControl && field.autoPlayed){
					if(!daNote.wasGoodHit && !daNote.ignoreNote){
						if(daNote.isSustainNote){
							if(daNote.canBeHit)
								field.noteHitCallback(daNote, field);
							
						}else{
							if(daNote.strumTime <= Conductor.songPosition)
								field.noteHitCallback(daNote, field);
							
						}
					}
					
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime){
					daNote.garbage = true;
					if (daNote.playField != null && daNote.playField.playerControls && !daNote.playField.autoPlayed && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)){
						noteMiss(daNote);
					}
				}
				if (daNote.garbage)
				{
					disposeNote(daNote);
				}
			});
                }		

		checkEventNote();

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) { //Complete the song for testing purposes lol
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		for (i in shaderUpdates){
			i(elapsed);
		}
		callOnLuas('onUpdatePost', [elapsed]);
	}

   private function disposeNote(note:Note) 
	{
		note.active = false;
		note.visible = false;
		
		note.kill();
		notes.remove(note, true);
		note.destroy();
		note = null;

		//trace('kill!' + note);

	}

	function randomizeSongName():Void {
        var randomValue:Int = FlxG.random.int(1, 15);
		#if debug
        //trace("Random text nuber: " + randomValue);
		#end
        switch(randomValue) {
			case 1:
				songNameHUD.text = 'v1sT4';
			case 2:
				songNameHUD.text = '0vVVOu';
			case 3:
				songNameHUD.text = 'duKqfdcaXs';
			case 4:
				songNameHUD.text = 'iPpj5TMNW';
			case 5:
				songNameHUD.text = '5JH1Bg7gRQ';
			case 6:
				songNameHUD.text = 'Gkpo5g7vxm';
			case 7:
				songNameHUD.text = 'NUSmyXyoyH';
			case 8:
				songNameHUD.text = '1f5VmRWPXE';
			case 9:
				songNameHUD.text = 'MLioiJtZX4';
			case 10:
				songNameHUD.text = 'WPvSwx9e5d';
			case 11:
				songNameHUD.text = 'E0U0xZuJ8p';
			case 12:
				songNameHUD.text = 'd9f8cj1Rs3';
			case 13:
				songNameHUD.text = 'Gkpo5g7vxm';
			case 14:
				songNameHUD.text = 'ZLyE8jMV62';
			case 15:
				songNameHUD.text = '9j3fOVV9Sw';
		}
    }

    function updateScoreText():Void {
        songNameHUD.text = SONG.song.replace("-", " ");
        
        if (SONG.song.endsWith("Legacy")) {
            songNameHUD.text = songNameHUD.text.replace(" Legacy", "\nLegacy");
        }

		if (SONG.song.toLowerCase() != 'found-you-legacy') {
            if(ratingName == '?') {
                scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
            } else {
                scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%' + ' - ' + ratingFC;
            }
		} else {
			if(ratingName == '?') {
                scoreTxt.text = 'Score: ' + songScore + ' - Misses: ' + songMisses + ' - Rating: ' + ratingName;
            } else {
                scoreTxt.text = 'Score: ' + songScore + ' - Misses: ' + songMisses + ' - Rating: ' + ratingName + ' ' + Highscore.floorDecimal(ratingPercent * 100, 2) + ' - ' + ratingFC;
            }
		}
    }

	public function openChartEditor()
	{
		persistentUpdate = false;
		canResync = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}


	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				canResync = false;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (tween in piss) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song, iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	function updateWires() {
		for (wireIdx in 0...barbedWires.members.length) {
			var wire = barbedWires.members[wireIdx];
			wire.screenCenter();
			var flag:Bool = wire.extraInfo.get("inUse");
			if ((wireIdx+1) <= hexes) {
				if (!flag) {
					if (wire.tweens.exists("disappear")) {wire.tweens.get("disappear").cancel();wire.tweens.remove("disappear");}
					wire.alpha=1;
					wire.shake(0.01,0.05);
					wire.extraInfo.set("inUse",true);
				}
			} else {
				if (wire.tweens.exists("disappear")){wire.tweens.get("disappear").cancel();wire.tweens.remove("disappear");}
				if (flag) {
					wire.extraInfo.set("inUse",false);
					wire.tweens.set("disappear", FlxTween.tween(wire, {
						alpha: 0,
						y: ((FlxG.height - wire.height)/2) + 75
					}, 0.2, {
						ease: FlxEase.quadIn,
						onComplete:function(tw:FlxTween) {
							if (wire.tweens.get("disappear")==tw) {
								wire.tweens.remove("disappear");
								wire.alpha=0;
							}
						}
					}));
				}
			}
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}



			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Lyrics':
				var split = value1.split("--");
				var text = value1;
				var color = FlxColor.WHITE;
				if(split.length > 1){
					text = split[0];
					color = FlxColor.fromString(split[1]);
				}
				var duration:Float = Std.parseFloat(value2);
				if (Math.isNaN(duration) || duration <= 0)
					duration = text.length * 0.5;
	
				writeLyrics(text, duration, color);

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case "Chaotix Health Randomization":
			        var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 0;
				switch (value)
				{
					case 1:
						fucklesHealthRandomize();
						camHUD.shake(0.001, 1);
					case 2:
						fucklesFinale();
						camHUD.shake(0.003, 1);
				}
			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
						        var oldChar = boyfriend;
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
                     for(field in playFields.members){
						if(field.owner==oldChar)field.owner=boyfriend;
					}
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
		                                        var oldChar = dad;
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
                     for (field in playFields.members)
					{
						if (field.owner == oldChar)
							field.owner = dad;
					}
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
			                                        var oldChar = gf;
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
                        for (field in playFields.members)
						{
							if (field.owner == oldChar)
								field.owner = gf;
						}
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		var elapsed:Float = FlxG.elapsed;
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();

			switch (dad.curCharacter)
			{
				case "beast_chaotix-legacy":
					camFollow.x -= 30;
					camFollow.y -= 50;

				default:

			}
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			switch (boyfriend.curCharacter)
			{
				default:

			}

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

     
		#if mobile
                mobileControls.visible = false;
		if (ClientPrefs.isvpad && MobileControls.mode != 'Hitbox' && MobileControls.mode != 'Keyboard'){
			addVirtualPad(NONE, NONE);
			_virtualpad.visible = true;
		}
                #end
		timeBarBG.visible = false;
		timeBar.visible = false;
		fakeTimeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		defaultZoomin = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					//FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					canResync = false;
					#if !mobile
					MusicBeatState.switchState(new StoryMenuState());
					#else
					MusicBeatState.switchState(new mobile.StoryMenuState());
					#end

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					canResync = false;

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else if (isFreeplay)
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				canResync = false;
				MusicBeatState.switchState(new BallsFreeplay());
				changedDifficulty = false;
			}
			else 
			{
				trace('OLD KINGDOM. FULL IN CALM...');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				canResync = false;
				MusicBeatState.switchState(new LegacyRoomState());
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

        public function getScrollPos(time:Float, mult:Float = 1)
	{
		var speed:Float = songSpeed * mult;
		return (-(time * (0.45 * speed)));
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				//totalNotesHit += 0;
				note.ratingMod = 0;
				score = 50;
				if(fucklesMode && SONG.song.toLowerCase() != "vista") {
					drainMisses++;
				    drainMisses -= 0.0025;
				}
				else 
				{
					drainMisses++;
					drainMisses -= 1/50 + 0.0025;
				}
				if(!note.ratingDisabled) shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				note.ratingMod = 0.5;
				score = 100;
				if(!note.ratingDisabled) bads++;
			case "good": // good
				totalNotesHit += 0.75;
				note.ratingMod = 0.75;
				score = 200;
				if(fucklesMode && SONG.song.toLowerCase() != "vista") {
					drainMisses -= 1/50;
				}
				else 
				{
					drainMisses -= 1/50 + 0.0025;
				}
				if(!note.ratingDisabled) goods++;
			case "sick": // sick
				totalNotesHit += 1;
				note.ratingMod = 1;
				if(fucklesMode && SONG.song.toLowerCase() != "vista")
					drainMisses -= 1/25;
			        else 
				{
					drainMisses -= 1/25 + 0.0025;
				}
				if(!note.ratingDisabled) sicks++;
		}
		note.rating = daRating;

		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

                var field:PlayField = note.playField;

		if(!practiceMode && !field.autoPlayed) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		
		insert(members.indexOf(playFields), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
			insert(members.indexOf(rating), numScore);

			numScore.scale.x = 0.55;
			numScore.scale.y = 0.55;

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});


			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var ghostTapped:Bool = true;
				for(field in playFields.members){
					if (field.playerControls && field.inControl && !field.autoPlayed){
						var sortedNotesList:Array<Note> = field.getTapNotes(key);
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (sortedNotesList.length > 0) {
							pressNotes.push(sortedNotesList[0]);
							field.noteHitCallback(sortedNotesList[0], field);
						}
					}
				}

				if(pressNotes.length == 0){
					if (canMiss) {
						noteMissPress(key);
						callOnLuas('noteMissPress', [key]);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			for(field in playFields.members){
				if (field.inControl && !field.autoPlayed && field.playerControls){
					var spr:StrumNote = field.members[key];
					if(spr != null && spr.animation.curAnim.name != 'confirm')
					{
						spr.playAnim('pressed');
						spr.resetAnim = 0;
					}
				}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	    }
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(startedCountdown && !paused && key > -1)
		{
			for(field in playFields.members){
				if (field.inControl && !field.autoPlayed && field.playerControls)
				{
					var spr:StrumNote = field.members[key];
					if (spr != null)
					{
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				}
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if(!daNote.playField.autoPlayed && daNote.playField.inControl && daNote.playField.playerControls){
					if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit) {
						daNote.playField.noteHitCallback(daNote, daNote.playField);
					}
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss') && gray == null)
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.playField.playerControls && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				disposeNote(note);
			}
		});
		combo = 0;

		if (!fucklesMode)
		{
			if (daNote.isSustainNote) health -= (daNote.missHealth * healthLoss) / 2.75;
		        else health -= daNote.missHealth * healthLoss;
		}
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}
		if(fucklesMode && SONG.song.toLowerCase() != "vista") {
			drainMisses++;
		} else {
			drainMisses++;
			drainMisses -= 0.00225;
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		switch (daNote.noteType)
		{
			default:
				if (!fucklesMode)
					if (daNote.isSustainNote) health -= (daNote.missHealth * healthLoss) / 2.75;
		                        else health -= daNote.missHealth * healthLoss;
				else
					drainMisses++;
		}

		if(char != null && char.hasMissAnimations)
		{
			if(char.animTimer <= 0 && !char.voicelining){
				var daAlt = '';
				if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
				char.playAnim(animToPlay, true);
				if (char.currentlyHolding) char.currentlyHolding = false;
			}
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1, anim:Bool = true):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if(ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong)
			{
				songMisses++;
				if (fucklesMode && SONG.song.toLowerCase() != "vista") {
					drainMisses++;
				} else {
					drainMisses++;
					drainMisses -= 0.0025;
				}
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations && anim) {
				if(boyfriend.animTimer <= 0 && !boyfriend.voicelining)
					boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note, playfield:PlayField):Void
	{
		var char:Character = playfield.owner;

		if(note.gfNote)
			char = gf;
		
		if(note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
			char.playAnim('hey', true);
			char.specialAnim = true;
			char.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSect:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSect] != null)
			{
				if (SONG.notes[curSect].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			iconP2.scale.set(1.2, 1.2);

			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(char.voicelining)char.voicelining=false;

			if(char != null)
			{
				char.holdTimer = 0;

				// TODO: maybe move this all away into a seperate function
				if (!note.isSustainNote
					&& noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row] != null
					&& noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row].length > 1)
				{
					// potentially have jump anims?
					var chord = noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row];
					var animNote = chord[0];
					var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + altAnim;
					if (char.mostRecentRow != note.row)
						char.playAnim(realAnim, true);

					if (note != animNote)
						char.playGhostAnim(chord.indexOf(note) - 1, animToPlay, true);

					char.mostRecentRow = note.row;
				}
				else
					char.playAnim(animToPlay, true);

				if (char.pauseAnimForSustain && ((note.nextNote?.isSustainNote || note.isSustainNote)) && !note.animation.curAnim.name.contains('end')) char.currentlyHolding = true;
				else char.currentlyHolding = false;
				switch (char.curCharacter.toLowerCase())
				{
					case 'normal':
						if (soulGlassTime)
						{
							health -= 0.00105;
							if (health <= 0.01)
							{
								health = 0.01;
							}
						}
				}
				if (glitchinTime)
					if(!note.isSustainNote && ClientPrefs.shaders){
						if (camGlitchShader != null && (char.curCharacter.startsWith('chaotix-beast-unpixel') || char.curCharacter.startsWith('chaotix-beast-pixel')))
							camGlitchShader.amount += 0.030;
					}
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		if (playfield.autoPlayed) {
			var time:Float = 0.15;
			if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
				time += 0.15;
			}
			StrumPlayAnim(playfield, Std.int(Math.abs(note.noteData)) % 4, time, note);
		} else {
			playfield.forEach(function(spr:StrumNote)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.playAnim('confirm', true, note);
				}
			});
		}

                note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.garbage = true;
		}
	}

	function goodNoteHit(note:Note, field:PlayField):Void
	{
		if (!note.wasGoodHit)
		{
                        if(field.autoPlayed && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(field.owner.animation.getByName('hurt') != null) {
							field.owner.playAnim('hurt', true);
							field.owner.specialAnim = true;
				                }
					case 'Hex Note':
						hexes++;
						FlxG.sound.play(Paths.sound("hitWire"));
						camOther.flash(0xFFAA0000, 0.35, null, true);
						hexTimer = 0;
						updateWires();
						if(hexes > barbedWires.members.length){
							health = -10000; // you are dead
						}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.garbage = true;
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			if (!fucklesMode)
			{
				if (note.isSustainNote) health += (note.hitHealth * healthGain) / 6;
			        else health += note.hitHealth * healthGain;
			}

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + daAlt;

				if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				}

				else if (field.owner.animTimer <= 0 && !field.owner.voicelining) {
				    field.owner.holdTimer = 0;
				    if (!note.isSustainNote && noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row]!=null && noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row].length > 1)
				    {
					// potentially have jump anims?
					var chord = noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row];
					var animNote = chord[0];
					var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + daAlt;
					if (field.owner.mostRecentRow != note.row)
						field.owner.playAnim(realAnim, true);
							
		
					if (note != animNote && chord.indexOf(note) != animNote.noteData)
						field.owner.playGhostAnim(chord.indexOf(note), animToPlay, true);
		
					field.owner.mostRecentRow = note.row;
				    }
				    else {
					field.owner.playAnim(animToPlay + daAlt, true);

					if (field.owner.pauseAnimForSustain && ((note.nextNote?.isSustainNote || note.isSustainNote)) && !note.animation.curAnim.name.contains('end')) field.owner.currentlyHolding = true;
					else field.owner.currentlyHolding = false;
				    }
				}
				

				if(note.noteType == 'Hey!') {
					if(field.owner.animOffsets.exists('hey')) {
						field.owner.playAnim('hey', true);
						field.owner.specialAnim = true;
						field.owner.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (field.autoPlayed) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(field, Std.int(Math.abs(note.noteData)) % 4, time, note);
			} else {
				field.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true, note);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			iconP1.scale.set(1.2, 1.2);

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.garbage = true;
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = note.playField.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt, note.playField);
		grpNoteSplashes.add(splash);
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		#if hscript
		if(FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	var glitchShaders:Array<GlitchShaderA> = [];

	function glitchKill(spr:FlxSprite,dontKill:Bool=false) {
		var shader = new GlitchShaderA();
		shader.iResolution.value = [spr.width, spr.height];
		piss.push(FlxTween.tween(shader, {amount: 1.25}, 2, {
			ease: FlxEase.cubeInOut,
			onComplete: function(tw: FlxTween){
				glitchShaders.remove(shader);
				spr.visible=false;
				if(!dontKill){
					remove(spr);
					spr.destroy();
				}
			}
		}));
		glitchShaders.push(shader);
		spr.shader = shader;
	}
	
	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}
   
    public static var lastStepHit:Int = -1;

	var gray:GrayscaleShader;
	var distortion:DistortionShader;

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20 || (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if (curStep % 2 == 0 && pleaseStopZoomin)
		{
			FlxG.camera.zoom += 0.04;
			camHUD.zoom += 0.04;
		}

		if (curStep % 1 == 0 && ohGodTheZooms)
		{
			FlxG.camera.zoom += 0.02;
			camHUD.zoom += 0.02;
		}

		switch (SONG.song.toLowerCase())
		{
			case 'breakout':
			{
			   if (curStage == "entrance")
			   {
				switch (curStep)
				{
				    case 384:
					    FlxG.camera.flash(FlxColor.BLACK, 0.75);
						wowZoomin = true;
						holyFuckStopZoomin = false;
					case 640:
						holyFuckStopZoomin = false;
						defaultZoomin = false;
					    wowZoomin = false;
					case 736:
						FlxTween.tween(camHUD, {alpha: 0}, 3, {ease: FlxEase.cubeInOut});
		            case 755:
		                //dad.y += 25;
					case 768:
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.25}, 3, {ease: FlxEase.cubeInOut});
                        if (ClientPrefs.shaders) {
						    camGame.setFilters([barrelDistortionFilter]);
						    camHUD.setFilters([barrelDistortionFilter]);
	                    }
					case 784:
		                if (ClientPrefs.shaders) {
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.75, barrelDistortion2: -0.5}, 1.5, {ease: FlxEase.quadInOut});
					    }
					case 800:
                        if (ClientPrefs.shaders) {
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 0, barrelDistortion2: 0}, 0.35,{
							ease: FlxEase.quadInOut, onComplete: function(tw:FlxTween)
							{
								camGame.setFilters([]);
								camHUD.setFilters([]);
							}});
                        }
                        //dad.y += 25;
						iShouldKickUrFuckinAss(1);
						cameraSpeed = 1.55;
						holyFuckStopZoomin = true;
                        Paths.clearUnusedMemory();
					case 1056:
						FlxG.camera.flash(FlxColor.RED, 1.5);
						holyFuckStopZoomin = false;
						wowZoomin = false;
						defaultZoomin = false;
					case 1312:
						FlxG.camera.flash(FlxColor.GREEN, 1.5);
					case 1568:
						FlxG.camera.flash(FlxColor.RED, 2);
						FlxTween.tween(camHUD, {alpha: 0}, 1, {ease: FlxEase.cubeInOut});
						wowZoomin = false;
						defaultZoomin = true;	
					case 1584:
						// :> 4axion was here!!!gdsjsgjsdjsdggs
                        defaultCamZoom = 0.9;
						dad.cameras = [camGame2];
						boyfriend.animation.pause();
                        gf.animation.pause();
						gf.animation.pause();
						gray = new GrayscaleShader();
						camGame.setFilters([new ShaderFilter(gray.shader)]);
						holyFuckStopZoomin = false;
						wowZoomin = false;
						defaultZoomin = false;
					case 1736:
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
                        if (ClientPrefs.shaders) {
						    camGame.setFilters([barrelDistortionFilter]);
						    camHUD.setFilters([barrelDistortionFilter]);
                        }
                        else
					    {
						    camGame.setFilters([]);
						    camHUD.setFilters([]);
					    }
						dad.cameras = [camGame];
						gray = null;
                        if (ClientPrefs.shaders) {
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -1.0, barrelDistortion2: -0.5}, 0.75, 
								{ease: FlxEase.quadInOut});
                        }
					case 1744:
                        if (ClientPrefs.shaders) {
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 0.0, barrelDistortion2: 0.0}, 0.35, {
							    ease: FlxEase.backOut,
							    onComplete: function(tw:FlxTween)
							    {
								    camGame.setFilters([]);
								    camHUD.setFilters([]);
							    }
						    });
                        }
						defaultCamZoom = 0.65;
						holyFuckStopZoomin = true;
						camHUD.zoom += 2;
						FlxTween.tween(camHUD, {alpha: 1}, 1, {ease: FlxEase.cubeInOut});
					case 1870:
                        if (ClientPrefs.shaders && !ClientPrefs.lowQuality) {
						    camGame.setFilters([camGlitchFilter, barrelDistortionFilter]);
						    camHUD.setFilters([camGlitchFilter, barrelDistortionFilter]);
                        } else if (ClientPrefs.shaders) {
							camGame.setFilters([barrelDistortionFilter]);
						    camHUD.setFilters([barrelDistortionFilter]);
						}
					case 1872:
                        if (ClientPrefs.shaders) {
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.05, barrelDistortion2: -0.05}, 2, {ease: FlxEase.quadInOut});
                        }
					case 2000:
						FlxG.camera.flash(FlxColor.GREEN, 1.5);
                        if (ClientPrefs.shaders) {
						    camGlitchShader.amount = 0.075;
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.1, barrelDistortion2: -0.1}, 2, {ease: FlxEase.quadInOut});
                        }
					case 2128:
						FlxG.camera.flash(FlxColor.RED, 1.5);
                        if (ClientPrefs.shaders) {
						    camGlitchShader.amount = 0.1;
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.15, barrelDistortion2: -0.15}, 2, {ease: FlxEase.quadInOut});
                        }
					case 2224:
						FlxG.camera.flash(FlxColor.GREEN, 1.5);
                        if (ClientPrefs.shaders) {
						    camGlitchShader.amount = 0.15;
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.20, barrelDistortion2: -0.20}, 2, {ease: FlxEase.quadInOut});
                        }
					case 2288: 
						FlxG.camera.flash(FlxColor.RED, 1.5);
                        if (ClientPrefs.shaders) {
						    camGlitchShader.amount = 0;
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 0.0, barrelDistortion2: 0.0}, 2.5, {
							    ease: FlxEase.backOut,
							    onComplete: function(tw:FlxTween)
							    {
								    camGame.setFilters([]);
								    camHUD.setFilters([]);
							    }
						    });
                        }
						holyFuckStopZoomin = false;
						defaultZoomin = false;
						FlxTween.tween(camHUD, {alpha: 0}, 3, {ease: FlxEase.cubeInOut});
					}
				}
			}

			case 'breakout-legacy':
			{
			   if (curStage == "entrance-legacy")
			   {
				switch (curStep)
				{
					    case 384:
						    wowZoomin = true;
					    case 512:
						    wowZoomin = false;
					    case 522:
						    FlxTween.tween(camHUD, {alpha: 0}, 1.3, {ease: FlxEase.cubeInOut});
						    FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.25}, 4, {ease: FlxEase.cubeInOut});
					    case 560:
						    FlxTween.tween(theStatic, {alpha: 0.9}, 1.5, {ease: FlxEase.quadInOut});
					    case 704:
						if (ClientPrefs.shaders) {
						    camGame.setFilters([barrelDistortionFilter]);
						    camHUD.setFilters([barrelDistortionFilter]);
						    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 1.0, barrelDistortion2: 1.0}, 0.5, {ease: FlxEase.quadInOut});
						}
						case 728:
							if (ClientPrefs.shaders) {
							    FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -1.0, barrelDistortion2: -1.0}, 0.35,
								    {ease: FlxEase.quadInOut});
				            }
						case 732:
							if (ClientPrefs.shaders) {
							FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 0.0, barrelDistortion2: 0.0}, 0.5,
								{ease: FlxEase.quadInOut, onComplete: function(tw:FlxTween){
									camGame.setFilters([]);
									camHUD.setFilters([]);
								}});
							}
						case 951:
							if (ClientPrefs.shaders) {
							camGame.setFilters([barrelDistortionFilter]);
							camHUD.setFilters([barrelDistortionFilter]);
							FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -1.0, barrelDistortion2: -0.5}, 0.75,
								{ease: FlxEase.quadInOut});
							}
						case 960:
							if (ClientPrefs.shaders) {
							FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 0.0, barrelDistortion2: 0.0}, 0.75, {
								ease: FlxEase.backOut,
								onComplete: function(tw:FlxTween)
								{
									camGame.setFilters([]);
									camHUD.setFilters([]);
								}
							});
						    }
						case 569:
							FlxFlicker.flicker(theStatic, 0.5, 0.02, false, false);
							new FlxTimer().start(0.5, function(tmr:FlxTimer) 
								{				
									theStatic.visible = false;		
									theStatic.alpha = 0;
								});
						case 576:
							FlxTween.tween(camHUD, {alpha: 1}, 0.5, {ease: FlxEase.cubeInOut});
							camHUD.zoom += 2;
							holyFuckStopZoomin = true;
							defaultZoomin = true;
						case 832:
							holyFuckStopZoomin = false;
							FlxTween.tween(camHUD, {alpha: 0.75}, 0.5, {ease: FlxEase.cubeInOut});
						case 928:
							FlxTween.tween(camHUD, {alpha: 1}, 0.5, {ease: FlxEase.cubeInOut});
							holyFuckStopZoomin = true;
						case 1216:
							holyFuckStopZoomin = false;
							FlxTween.tween(camHUD, {alpha: 0}, 3, {ease: FlxEase.cubeInOut});
						}
					}
				}

			case 'soulless-endeavors':
			{
			   if (curStage == "soulless")
			   {
				switch (curStep)
				{
					case 896:
						theStatic.visible = true;
					case 898:
				                gfGroup.visible = false;
						health = 1;
						soulSky.visible = false;
						soulBalls.visible = false;
						soulRocks.visible = false;
						soulKai.visible = false;
						soulFrontRocks.visible = false;
						soulPixelBgBg.visible = true;
						soulPixelBg.visible = true;
						theStatic.visible = false;
						isPixelStage = true;
						reloadTheNotesPls();
						healthBar.x += 150;
						iconP1.x += 150;
						iconP2.x += 150;
						healthBarBG.x += 150;
				        
						fakeTimeBar.visible = false;
						timeBar.visible = false;
						timeBarBG.visible = false;
						timeTxt.visible = false;
						chaotixHUD.visible = true;
						scoreTxt.visible = false;
						songNameHUD.x -= 1250;
						boyfriend.y -= 115;
				                boyfriend.x -= 150;
                                                dad.x -= 32.5;
				                dad.y += 150;
					case 1439:
						theStatic.visible = true;
					case 1440:
				                gfGroup.visible = true;
						healthBar.x -= 150;
						iconP1.x -= 150;
						iconP2.x -= 150;
						healthBarBG.x -= 150;
						songNameHUD.x += 1250;
						fakeTimeBar.visible = !ClientPrefs.hideHud;
						timeBar.visible = !ClientPrefs.hideHud;
						timeBarBG.visible = !ClientPrefs.hideHud;
						timeTxt.visible = !ClientPrefs.hideHud;
						chaotixHUD.visible = false;

						health = 1;
						soulSky.visible = true;
						soulBalls.visible = true;
						soulRocks.visible = true;
						soulKai.visible = true;
						soulFrontRocks.visible = true;
						soulPixelBgBg.visible = false;
						soulPixelBg.visible = false;
						scoreTxt.visible = !ClientPrefs.hideHud;
						boyfriend.y += 50;
				        boyfriend.x += 200;
				        dad.x += 1;
				        dad.y += 1;
						isPixelStage = false;
						reloadTheNotesPls();
				        Paths.clearUnusedMemory();
					case 1443:
						theStatic.visible = false;
						//bop shit lolololol
					case 256:
						wowZoomin = true;
						holyFuckStopZoomin = false;
					case 1408, 1696, 1984:
					    wowZoomin = false;
					    holyFuckStopZoomin = false;
					case 384, 1441:
					    wowZoomin = false;
					    holyFuckStopZoomin = false;
						defaultZoomin = true;
					case 128, 272, 1280, 1568, 1712:
						wowZoomin = false;
						holyFuckStopZoomin = true;
					case 1442:
						defaultCamZoom = 0.6;
					case 897:
						wowZoomin = false;
						holyFuckStopZoomin = false;
						defaultCamZoom = 0.8;
					case 2005:
						wowZoomin = false;
						holyFuckStopZoomin = false;
                        FlxG.camera.flash(FlxColor.WHITE, 3.35);
						//FlxTween.tween(camHUD, {alpha: 0}, 0.75, {ease: FlxEase.cubeInOut});
                        camHUD.alpha = 0;
                        dadGroup.alpha = 0;
                        boyfriendGroup.alpha = 0;
                        gfGroup.alpha = 0;
                        soulSky.alpha = 0;
						soulBalls.alpha = 0;
						soulRocks.alpha = 0;
						soulKai.alpha = 0;
						soulFrontRocks.alpha = 0;
					}
				}
			}

			case 'soulless-endeavors-legacy':
				{
				   if (curStage == "soulless-legacy")
				   {
					switch (curStep)
					{
						case 640:
							theStatic.visible = true;
						case 641:
							health = 1;
							soulFogLegacy.visible = false;
							soulBgLegacy.visible = false;
							soulGroundLegacy.visible = false;
							soulPixelBgBgLegacy.visible = true;
							soulPixelBgLegacy.visible = true;
							theStatic.visible = false;
							isPixelStage = true;
							songNameHUD.x -= 1250;
							reloadTheNotesPls();
							healthBar.x += 150;
							iconP1.x += 150;
							iconP2.x += 150;
							healthBarBG.x += 150;
					
							timeBar.visible = false;
							timeBarBG.visible = false;
							timeTxt.visible = false;
							chaotixHUD.visible = true;
							scoreTxt.visible = false;
						case 1152:
							theStatic.visible = true;
						case 1153:
							healthBar.x -= 150;
							iconP1.x -= 150;
							iconP2.x -= 150;
							healthBarBG.x -= 150;
							songNameHUD.x += 1250;
							timeBar.visible = !ClientPrefs.hideHud;
							timeBarBG.visible = !ClientPrefs.hideHud;
							timeTxt.visible = !ClientPrefs.hideHud;
							scoreTxt.visible = !ClientPrefs.hideHud;
							chaotixHUD.visible = false;

							health = 1;
							soulFogLegacy.visible = true;
							soulBgLegacy.visible = true;
							soulGroundLegacy.visible = true;
							soulPixelBgBgLegacy.visible = false;
							soulPixelBgLegacy.visible = false;
							soulSpiritsLegacy.visible = true;
							boyfriend.x += 100;
							isPixelStage = false;
							reloadTheNotesPls();
						case 1154:
							theStatic.visible = false;

						//bop shit lolololol
						case 64, 256, 639:
							wowZoomin = true;
							holyFuckStopZoomin = false;
						case 128, 272, 1280:
							wowZoomin = false;
							holyFuckStopZoomin = true;
						case 1281:
							defaultCamZoom = 0.75;
						case 1150:
							wowZoomin = false;
							holyFuckStopZoomin = false;
							defaultCamZoom = 0.9;
						case 1792:
							wowZoomin = false;
							holyFuckStopZoomin = false;
							FlxTween.tween(camHUD, {alpha: 0}, 1.75, {ease: FlxEase.cubeInOut});
						}
					}
				}

			case 'color-crash':
			{
			   if (curStage == "wechnia")
			   {
				switch (curStep)
				{
					case 64, 832:
						defaultZoomin = true;
						wowZoomin = true;
					case 66:
						camHUD.zoom += 0.7;
						camHUD.alpha = 1;
					case 328, 344, 360, 384, 1000, 1056:
						defaultCamZoom = 0.9;
					case 336, 352, 392, 992, 1016, 1072:
						defaultCamZoom = 0.75;
					case 368, 432, 1008, 1064:
						defaultCamZoom = 0.6;
					case 577:
                        wowZoomin = false;
					case 576, 1024, 1080:
						defaultCamZoom = 0.5;
					case 1088:
						FlxTween.tween(camHUD, {alpha: 0}, 0.25, {ease: FlxEase.linear});
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 1.75, {ease: FlxEase.cubeInOut});
					case 1104:
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
						FlxTween.tween(camHUD, {alpha: 1}, 0.25, {ease: FlxEase.linear});
					case 1360:
						wowZoomin = false;
						defaultZoomin = false;
						FlxTween.tween(camHUD, {alpha: 0}, 0.25, {ease: FlxEase.linear});
					}
				}
			}

			case "my-horizon":
			   if (curStage == "horizon")
			   {
				switch (curStep) 
				{
				    case 79:
                                            FlxTween.tween(camHUD, {alpha: 1}, 1.75, {ease: FlxEase.linear});

				    case 728:
					    FlxTween.tween(camHUD, {alpha: 0}, 1.5, {ease: FlxEase.linear});
					    FlxTween.tween(horizonBGp1, {alpha: 0}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonBGp2, {alpha: 0}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonBGp3, {alpha: 0}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonBGp4, {alpha: 0}, 1, {ease: FlxEase.linear});
                                            FlxTween.tween(dad, {alpha: 0}, 1.75, {ease: FlxEase.linear});
					    FlxTween.tween(gf, {alpha: 0}, 1.75, {ease: FlxEase.linear});
					    FlxTween.tween(boyfriend, {alpha: 0}, 1.75, {ease: FlxEase.linear});
					    FlxTween.tween(horizonFGp1, {alpha: 0}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonFGp2, {alpha: 0}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonFGp3, {alpha: 0}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonFGp4, {alpha: 0}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonMG, {alpha: 0}, 1, {ease: FlxEase.linear});

				    case 1000:
					    dad.x += 300;
					    dad.y += 65;
					    boyfriend.x -= 250;
					    boyfriend.y += 85;

				    case 1024:
					    FlxTween.tween(this, {health: 1}, 3.75, {ease: FlxEase.sineOut});
					    FlxG.camera.flash(FlxColor.RED, 1.5);
					    FlxTween.tween(horizonSpookyBGp1, {alpha: 1}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonSpookyBGp2, {alpha: 1}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonSpookyBGp3, {alpha: 1}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonSpookyBGp4, {alpha: 1}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonSpookyFGp1, {alpha: 1}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(horizonSpookyFGp2, {alpha: 1}, 1, {ease: FlxEase.linear});
			 		    FlxTween.tween(horizonSpookyFloor, {alpha: 1}, 1, {ease: FlxEase.linear});
                                            FlxTween.tween(dad, {alpha: 1}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(gf, {alpha: 1}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(boyfriend, {alpha: 1}, 1, {ease: FlxEase.linear});
					    FlxTween.tween(camHUD, {alpha: 0.9}, 1, {ease: FlxEase.linear});

					    opponentStrums.forEach(function(spr:StrumNote)
					    {
						    spr.reloadNote();
					    });
					}
				}

				case 'my-horizon-legacy':
				{
				   if (curStage == "horizon-legacy")
				   {
					switch (curStep)
					{
						case 896:
							FlxTween.tween(camHUD, {alpha: 0}, 2.2, {ease: FlxEase.linear});
						case 908:
							dad.playAnim('transformation', true);
							dad.specialAnim = true;
							defaultZoomin = false;
						case 924:
							FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.5}, 12, {ease: FlxEase.cubeInOut});
							FlxTween.tween(whiteFuck, {alpha: 1}, 6, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
								{
									remove(fucklesFGPixelLegacy);
									remove(fucklesBGPixelLegacy);
									fucklesBGPixelLegacy.destroy();
									fucklesFGPixelLegacy.destroy();
									fucklesFuckedUpBgLegacy.visible = true;
									fucklesFuckedUpFgLegacy.visible = true;
								}
							});
						case 992:
							literallyMyHorizon();
							fucklesBeats = false;
						case 1120, 1248, 1376, 1632, 1888, 1952, 2048, 2054, 2060:
							fucklesHealthRandomize();
							camHUD.shake(0.005, 1);
						case 1121, 1760:
							wowZoomin = true;
						case 1503, 2015:
							wowZoomin = false;
						case 1504, 2080:
							holyFuckStopZoomin = true;
						case 1759, 2336:
							holyFuckStopZoomin = false;
						case 2208, 2222, 2240, 2254, 2320, 2324, 2328:
							fucklesFinale();
							camHUD.shake(0.003, 1);
						case 2337:
							defaultZoomin = false;
						}
					}
				}
		
				case 'our-horizon-legacy':
					{
					   if (curStage == "horizon-legacy")
					   {
						switch (curStep)
						{
							case 765:
								FlxTween.tween(camHUD, {alpha: 0}, 1.2);
								dad.playAnim('transformation', true);
								dad.specialAnim = true;
								defaultZoomin = false;
							case 800:
								FlxTween.tween(whiteFuck, {alpha: 1}, 6, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
									{
										removeShit(1);
									}
								});
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.5}, 12, {ease: FlxEase.cubeInOut});
							case 912:
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1.5, {ease: FlxEase.cubeInOut});
								iconP2.changeIcon(dad.healthIcon);
							case 920:
								FlxTween.tween(dad, {alpha: 0}, 0.5, {ease: FlxEase.cubeInOut});
								FlxTween.tween(boyfriend, {alpha: 0}, 0.5, {ease: FlxEase.cubeInOut});
								FlxTween.tween(gf, {alpha: 0}, 0.5, {ease: FlxEase.cubeInOut});
							case 927:
								dad.specialAnim = false;
								FlxG.camera.zoom += 2;
							case 1000:
								isPixelStage = false;
								snapCamFollowToPos(700, 900);
								defaultCamZoom = 0.7;
								dad.setPosition(200, 700);
								boyfriend.setPosition(900, 950);
								literallyOurHorizon();
								timeBar.visible = !ClientPrefs.hideHud;
								removeShit(2);
							case 2848:
								isPixelStage = false;
								defaultZoomin = true;
								FlxG.camera.zoom = defaultCamZoom;
								GameOverSubstate.characterName = 'bf-holding-gf-dead';
								gf.alpha = 0;
								snapCamFollowToPos(700, 900);
								defaultCamZoom = 0.7;
								dad.setPosition(200, 700);
								boyfriend.setPosition(900, 950);

								add(timeBarBG);
			                    add(timeTxt);
			                    add(songNameHUD);

								timeBar.visible = !ClientPrefs.hideHud;
							    timeBarBG.visible = !ClientPrefs.hideHud;
							    timeTxt.visible = !ClientPrefs.hideHud;
								scoreTxt.visible = !ClientPrefs.hideHud;
			                    chaotixHUD.visible = false;

								healthBar.x -= 150;
						        iconP1.x -= 150;
						        iconP2.x -= 150;
						        healthBarBG.x -= 150;

								reloadTheNotesPls();
		
								fucklesBGPixelLegacy.visible = false;
								fucklesFGPixelLegacy.visible = false;
		
								horizonBgLegacy.visible = true; 
								horizonFloorLegacy.visible = true;
								horizonTreesLegacy.visible = true;
								horizonTrees2Legacy.visible = true;
		
								horizonPurpurLegacy.visible = true;
								horizonYellowLegacy.visible = true;
								horizonRedLegacy.visible = true;
		
								horizonAmyLegacy.visible = true;
								horizonCharmyLegacy.visible = true;
								horizonEspioLegacy.visible = true;
								horizonMightyLegacy.visible = true;
								horizonKnucklesLegacy.visible = true;
								horizonVectorLegacy.visible = true;
		
								FlxG.camera.flash(FlxColor.WHITE, 2);
		
								removeShit(2);
							case 2336:
								snapCamFollowToPos(BF_X, BF_Y + 400);
								defaultCamZoom = 0.7;
								dad.setPosition(DAD_X, DAD_Y);
								boyfriend.setPosition(BF_X, BF_Y);
								startCharacterPos(dad, true);
								startCharacterPos(boyfriend);
		
								boyfriend.y += 68;
		
								isPixelStage = true;
								GameOverSubstate.deathSoundName = 'chaotix-death';
								GameOverSubstate.loopSoundName = 'chaotix-loop';
								GameOverSubstate.endSoundName = 'chaotix-retry';
								GameOverSubstate.characterName = 'bf-chaotix-death';
		
								defaultCamZoom = 0.87;
								defaultZoomin = true;
								FlxG.camera.zoom = defaultCamZoom;
								camHUD.alpha = 1;
								dad.alpha = 1;
								boyfriend.alpha = 1;
								gf.alpha = 1;
								healthBar.x += 150;
						        iconP1.x += 150;
						        iconP2.x += 150;
						        healthBarBG.x += 150;
							    scoreTxt.visible = false;
								timeBar.visible = false;
								chaotixHUD.visible = true;

							    remove(timeBarBG);
			                    remove(timeTxt);
			                    remove(songNameHUD);
		
								fucklesEspioBgLegacy.animation.resume();
								fucklesMightyBgLegacy.animation.resume();
								fucklesCharmyBgLegacy.animation.resume();
								fucklesAmyBgLegacy.animation.resume();
								fucklesKnuxBgLegacy.animation.resume();
								fucklesVectorBgLegacy.animation.resume();
								fucklesEspioBgLegacy.visible = true;
								fucklesMightyBgLegacy.visible = true;
								fucklesCharmyBgLegacy.visible = true;
								fucklesAmyBgLegacy.visible = true;
								fucklesKnuxBgLegacy.visible = true;
								fucklesVectorBgLegacy.visible = true;
		
								fucklesBGPixelLegacy.visible = true;
								fucklesFGPixelLegacy.visible = true;
		
								horizonBgLegacy.visible = false;
								horizonFloorLegacy.visible = false;
								horizonTreesLegacy.visible = false;
								horizonTrees2Legacy.visible = false;
		
								horizonPurpurLegacy.visible = false;
								horizonYellowLegacy.visible = false;
								horizonRedLegacy.visible = false;
		
								horizonAmyLegacy.visible = false;
								horizonCharmyLegacy.visible = false;
								horizonEspioLegacy.visible = false;
								horizonMightyLegacy.visible = false;
								horizonKnucklesLegacy.visible = false;
								horizonVectorLegacy.visible = false;
		
								reloadTheNotesPls();

						        FlxG.camera.flash(FlxColor.WHITE, 2);
		
							case 2976:
								FlxTween.tween(camHUD, {alpha: 0}, 2);
							case 2992:
								var fuckinCamShit:FlxObject;
								fuckinCamShit = new FlxObject(700, 950, 1, 1);
								FlxG.camera.follow(fuckinCamShit, LOCKON, 0.06 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
								fireWorksDeluxe();
							case 3104:
								removeShit(3);
								FlxG.camera.flash(FlxColor.WHITE, 2);
							}
						}
					}
		
				    case 'found-you-legacy':
					{
					   if (curStage == "founded")
					   {
						switch (curStep)
						{
							case 1: // do it jiggle?
								normalDoor.animation.play('idle');
							case 25, 48, 56:
								FlxG.camera.zoom += 0.15;
							case 2:
								defaultCamZoom = 1.35; //1.35
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1, {ease: FlxEase.quadInOut});
							case 64, 72:
								FlxG.camera.zoom += 0.05;
							case 76:
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 2, {ease: FlxEase.cubeInOut});
							case 93:
								dad.visible = true;
								camGame.shake(0.01, 1);
								defaultCamZoom = 1.35;
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1, {ease: FlxEase.quadInOut});
							case 94:
								FlxTween.tween(dad, {x: 100}, 0.5, {ease: FlxEase.quadOut});
							case 113:
								defaultCamZoom = 0.85;
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.35, {ease: FlxEase.quadOut});
							case 160:
								normalBool = true; 
								FlxG.camera.focusOn(dad.getPosition());
								camHUD.visible = true;
								camHUD.zoom += 2;
								FlxTween.tween(camHUD, {alpha: 1}, 1);
							case 416, 1184, 1696, 2720:
								wowZoomin = true;
							case 800, 1311, 1823, 2847:
								wowZoomin = false;
							case 928, 1312, 1824, 2080, 3361, 2336, 2848, 3782:
								holyFuckStopZoomin = true;
							case 1056, 1568, 2079, 2335, 3871, 2591, 3359, 4138:
								holyFuckStopZoomin = false;
							case 2592:
								iconP1.changeIcon(gf.healthIcon);
							case 3360:
								iconP1.changeIcon('legacy/icon-duo');
								boyfriend.healthColorArray = [50, 73, 127];
								triggerEventNote("Change Character", "bf", boyfriend.curCharacter);
							// shit for da uhhhhhhhhhhhhhhhhhhhhhhhh trails
							case 2081, 2849:
								chaotixGlass(1);
							case 2719, 2977:
								chaotixGlass(1);
								chaotixGlass(3);
							case 2816, 2976:
								revivedIsPissed(1);
							case 2145:
								chaotixGlass(2);
							case 2334:
								revivedIsPissed(1);
								revivedIsPissed(2);
							case 3104:
								revivedIsPissed(3);
							case 3362:
								chaotixGlass(1);
								chaotixGlass(2);
								chaotixGlass(3);
							case 4135:
								revivedIsPissed(3);
								revivedIsPissed(2);
								revivedIsPissed(1);
						   }
						}
					}

					case 'malediction-legacy':
					{
						if (curStage == "curse")
						{
						    switch (curStep)
						    {
								case 528, 725:
									FlxTween.tween(camHUD, {alpha: 0.5}, 0.3,{ease: FlxEase.cubeInOut});
								case 558, 735:
									FlxTween.tween(camHUD, {alpha: 1}, 0.3,{ease: FlxEase.cubeInOut});
								case 736:
									FlxG.camera.flash(FlxColor.PURPLE, 0.5);
									if(curseStatic!=null)curseStatic.visible = true;
									FlxTween.tween(curseStatic, {alpha: 1}, 2, {type: FlxTweenType.PINGPONG, ease: FlxEase.quadInOut, loopDelay: 0.1});
								case 991:
									FlxG.camera.flash(FlxColor.PURPLE, 1);
									if(curseStatic!=null){
										FlxTween.tween(curseStatic, {alpha: 0}, 0.5, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
											{
												curseStatic.visible=false;
											}
										});
									}
								case 1184:
									FlxTween.tween(camHUD, {alpha: 0}, 1,{ease: FlxEase.cubeInOut});
							}
						}
					}

					case 'endless-legacy':
					{
					   if (curStage == "infinity-legacy")
					   {
						switch (curStep)
						{
							case 272, 912, 1172:
								funIsInfinite = true;
							case 528, 1039, 1423:
								funIsInfinite = false;
							case 685, 1040, 1424:
								funIsForever = true;
							case 894, 1152, 1680:
								funIsForever = false;
							case 895:
								inCutscene = true;
								camFollow.set(FlxG.width / 2 + 50, FlxG.height / 4 * 3 + 280);
								FlxTween.tween(camHUD, {alpha: 0}, 0.5);
								var fuckinCamShit:FlxObject;
								fuckinCamShit = new FlxObject(500, 400, 1, 1);
								FlxG.camera.follow(fuckinCamShit, LOCKON, 0.06 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
							case 896:
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(4);
							case 900:
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(3);
							case 904:
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(2);
							case 908:
								wowZoomin = true;
								inCutscene = false;
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.7, {ease: FlxEase.cubeInOut});
								FlxTween.tween(camHUD, {alpha: 1}, 1);
								majinSaysFuck(1);
							case 1041:
								wowZoomin = false;
								holyFuckStopZoomin = true;
								defaultCamZoom = 0.8;
							case 1153:
								defaultCamZoom = 0.6;
								holyFuckStopZoomin = false;
								FlxG.camera.flash(FlxColor.CYAN, 1);
								FlxG.camera.follow(camFollowPos, LOCKON, 1 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
							case 1425:
								defaultCamZoom = 0.8;
								FlxG.camera.flash(FlxColor.CYAN, 1);
								holyFuckStopZoomin = true;
								var fuckinCamShit:FlxObject;
								fuckinCamShit = new FlxObject(500, 400, 1, 1);
								FlxG.camera.follow(fuckinCamShit, LOCKON, 0.06 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
							case 1681:
								defaultCamZoom = 0.6;
								holyFuckStopZoomin = false;
						   }
						}
					}
				
			case 'vista':
			{
			   if (curStage == "vista")
			   {
				switch (curStep)
				{
					case 512:
						FlxTween.tween(camHUD, {alpha: 0}, 1.2);
						defaultZoomin = false;
					case 576:
						FlxTween.tween(amyBop, {alpha: 0}, 8);
						FlxTween.tween(boyfriend, {alpha: 0.75}, 11);
						FlxTween.tween(gf, {alpha: 0.75}, 11);
						FlxTween.tween(whiteFuck, {alpha: 1}, 11.5, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
							{
								iShouldKickUrFuckinAss(2);
							}
						});
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.5}, 11.5, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
							{
								literallyMyHorizon();
							}
						});
					case 694:
						FlxTween.tween(whiteFuckDos, {alpha: 1}, 0.02, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
							{	
								new FlxTimer().start(0.03, function(tmr:FlxTimer) 
									{				
										remove(whiteFuckDos);
										whiteFuckDos.destroy();
									});
								boyfriend.visible = false;
								gf.visible = false;
							}
						});

						FlxTween.tween(redFuck, {alpha: 1}, 0.02, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
							{	
								new FlxTimer().start(0.08, function(tmr:FlxTimer) 
									{				
										remove(redFuck);
										redFuck.destroy();
									});
							}
						});
					case 702:
						dadGroup.visible = false;
					case 2240:
						defaultZoomin = false;
						FlxTween.tween(fuckedBG, {alpha: 0.2}, 3);
						FlxTween.tween(camHUD, {alpha: 0}, 0.5);
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 4, {ease: FlxEase.cubeInOut});
					case 2300:
						animController = false;
					case 2301:
						glitchKill(amyBopFucked);
						glitchKill(mightyBopFucked);
						glitchKill(knuxBopFucked);
					case 2288:
						glitchKill(espioBopFucked);
						glitchKill(vectorBopFucked);
						glitchKill(charmyBopFucked);
						// imma need someone else to fix this lol
					case 2336:
						defaultCamZoom = 0.70;
						glitchinTime = true;
						camHUD.zoom += 2;
						FlxG.camera.flash(FlxColor.BLACK, 1);
						if(ClientPrefs.flashing && ClientPrefs.shaders && !ClientPrefs.lowQuality) {
							camGame.setFilters([camGlitchFilter, camFuckFilter, staticOverlay]);
							camHUD.setFilters([camGlitchFilter, camFuckFilter, staticOverlay]);
						}
                        if (ClientPrefs.shaders) {
						    camFuckShader.amount = 0.01;
                        }
						FlxTween.tween(camHUD, {alpha: 1}, 0.5);
						FlxTween.tween(this, {health: 1}, 2);
						FlxTween.tween(fuckedBG, {alpha: 1}, 2);
                        Paths.clearUnusedMemory();
					case 2561:
						scoreRandom = true;
					case 2592:
						defaultCamZoom = 0.60;
						wowZoomin = true;
						scoreRandom = true;	
						FlxG.camera.flash(FlxColor.PURPLE, 1);
                        if (ClientPrefs.shaders) {
						    camFuckShader.amount = 0.02;
                        }
						finalStretchTrail = new FlxTrail(dad, null, 2, 12, 0.20, 0.05);
						add(finalStretchTrail);
					case 2848:
						defaultCamZoom = 0.65;
						wowZoomin = false;
						holyFuckStopZoomin = true;
						FlxG.camera.flash(FlxColor.PINK, 1);
                        if (ClientPrefs.shaders) {
						    camFuckShader.amount = 0.035;
                        }
					case 3104:
						defaultCamZoom = 0.6;
                        if (ClientPrefs.shaders) {
						    camFuckShader.amount = 0.045;
                        }
					case 3264, 3328, 3520, 3584:
						FlxG.camera.flash(FlxColor.PURPLE, 1);
						defaultCamZoom = 0.70;
					case 3269, 3333, 3525, 3589: 
						FlxG.camera.flash(FlxColor.PINK, 1);
						defaultCamZoom = 0.80;
					case 3280, 3344, 3536, 3600:
						FlxG.camera.flash(FlxColor.BLACK, 1);
						defaultCamZoom = 0.6;
					case 3360:
                        if (ClientPrefs.shaders) {
						    camFuckShader.amount = 0.055;
                        }
					case 3488:
                        if (ClientPrefs.shaders) {
						    camFuckShader.amount = 0.060;
					    }
					case 3552:
                        if (ClientPrefs.shaders) {
						    camFuckShader.amount = 0.075;
                        }
					case 3668:
						FlxG.camera.flash(FlxColor.PURPLE, 1);
						FlxTween.tween(camGame, {alpha: 0}, 1);
						FlxTween.tween(camHUD, {alpha: 0}, 1);
					}
				}			
			}

                 case "cascade":
			{
				switch (curStep)
				{
					case 256, 1152, 1937: 
						wowZoomin = false;
						holyFuckStopZoomin = true;
					case 756:
						holyFuckStopZoomin = false;
						wowZoomin = true;
					case 896, 1664, 2448:
						wowZoomin = false;
						holyFuckStopZoomin = false;
					case 1920:
						defaultCamZoom = 0.9;
						FlxTween.tween(camHUD, {alpha: 0}, 0.25);
					case 1936:
						defaultCamZoom = 0.7;
						FlxTween.tween(camHUD, {alpha: 1}, 0.5);
				}
			}
                }

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	var charmyDanced:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if(fcLabel!=null) {
			if(fcLabel.animation.curAnim != null) {
				var frame = fcLabel.animation.curAnim.curFrame;
				frame += 1;
				frame %= 2;
				fcLabel.animation.curAnim.curFrame = frame;
			}
		}

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (curBeat % 2 == 0 && curStage == 'vista')
		{
			amyBop.animation.play('idle');
			espioBop.animation.play('idle');
			knuxBop.animation.play('idle');
			mightyBop.animation.play('idle');
			vectorBop.animation.play('idle');
			charmyBop.animation.play('danceLeft');
		}

		if (curBeat % 1 == 0 && curStage == 'vista')
			{
				if (animController)
				{	
					amyBopFucked.animation.play('idle');
					espioBopFucked.animation.play('idle');
					knuxBopFucked.animation.play('idle');
					mightyBopFucked.animation.play('idle');
					vectorBopFucked.animation.play('idle');
					charmyBopFucked.animation.play('danceLeft');
				}

			}

		if (curBeat % 4 == 0 && curStage == 'vista')
		{
			charmyBop.animation.play('danceRight');
		}
                /*if (curBeat % 2 == 0 && curStage == 'vista' && fucklesMode)
		{
			gf.animation.play('scared');
		} */

		if (curBeat % 2 == 0 && wowZoomin && ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.04;
			camHUD.zoom += 0.06;

			if (camGlitchShader != null && glitchinTime)
				camGlitchShader.amount += 0.030;
		}

		if (curBeat % 1 == 0 && holyFuckStopZoomin && ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.04;
			camHUD.zoom += 0.06;

			if (camGlitchShader != null && glitchinTime)
				camGlitchShader.amount += 0.015;
		}

		if (curBeat % 8 == 0 && fuckedBar)
		{
			var fakeSongPercentTweener:Float = FlxG.random.int(0, 100);

			FlxTween.tween(this, {fakeSongPercent: fakeSongPercentTweener}, 1.5, {ease: FlxEase.cubeOut});
			//trace(fakeTimeBar.visible);
			//this shit is supposed to tween randomly everywhere to look like its glitching but it won't fucking work :sob:
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gray == null && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && gray == null && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			bfCamThing = [0, 0];
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dadCamThing = [0, 0];
			dad.dance();
		}

		switch (curStage)
		{
			case 'horizon-legacy':
				if (fucklesBeats)
					{
						fucklesEspioBgLegacy.animation.play('idle');
						fucklesMightyBgLegacy.animation.play('idle');
						fucklesCharmyBgLegacy.animation.play('idle');
						fucklesAmyBgLegacy.animation.play('idle');
						fucklesKnuxBgLegacy.animation.play('idle');
						fucklesVectorBgLegacy.animation.play('idle');
					}
				else
					{
						fucklesAmyBgLegacy.animation.play('fear');
						fucklesCharmyBgLegacy.animation.play('fear');
						fucklesMightyBgLegacy.animation.play('fear');
						fucklesEspioBgLegacy.animation.play('fear');
						fucklesKnuxBgLegacy.animation.play('fear');
						fucklesVectorBgLegacy.animation.play('fear');
					}
				if (SONG.song.toLowerCase() == 'our-horizon-legacy')
					{
						horizonAmyLegacy.animation.play('idle');
						horizonEspioLegacy.animation.play('idle');
						horizonKnucklesLegacy.animation.play('idle');
						horizonCharmyLegacy.animation.play('idle');
						horizonVectorLegacy.animation.play('idle');
						horizonMightyLegacy.animation.play('idle');
					}
		}

		if (curBeat % 64 == 0 && normalBool)
			{
				var prevInt:Int = normalCharShit;
	
				normalCharShit = FlxG.random.int(1, 5, [normalCharShit]);
	
				switch(normalCharShit){
					case 1:
						normalChars.animation.play('chaotix');
					case 2:
						normalChars.animation.play('curse');
					case 3:
						normalChars.animation.play('rex');
					case 4:
						normalChars.animation.play('rodent');
					case 5:
						normalChars.animation.play('spoiled');
				}
			}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

   override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (defaultZoomin && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
		        {
		   	    FlxG.camera.zoom += 0.0242;
			    camHUD.zoom += 0.03;

			    if (camGlitchShader != null && glitchinTime)
				    camGlitchShader.amount += 0.0075;
		        }

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	function chaotixGlass(ass:Int)
		{
			var trailDelay:Float = 0.05;
                        trailDelay *= ClientPrefs.framerate * FlxG.elapsed;
			switch (ass)
				{
					case 1:
						normalTrail = new FlxTrail(dad, null, 2, 12, 0.20, trailDelay);
						add(normalTrail);
						soulGlassTime = true;
					case 2:
						metalTrail = new FlxTrail(boyfriend, null, 2, 12, 0.20, trailDelay);
						add(metalTrail);
					case 3:
						amyTrail = new FlxTrail(gf, null, 2, 12, 0.20, trailDelay);
						add(amyTrail);
				}
		}

	function revivedIsPissed(ass:Int)
		{
			{
				switch (ass)
					{
						case 1:
							soulGlassTime = false;
							remove(normalTrail);
						case 2:
							remove(metalTrail);
						case 3:
							remove(amyTrail);
					}
			}
		}

		function majinSaysFuck(numb:Int):Void
			{
				switch(numb)
				{
					case 4:
						var three:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mazin/three', 'exe'));
						three.scrollFactor.set();
						three.updateHitbox();
						three.screenCenter();
						three.y -= 100;
						three.alpha = 1;
						three.cameras = [camOther];
						add(three);
						FlxTween.tween(three, {y: three.y + 100, alpha: 0, "scale.x": 1.05, "scale.y": 1.05}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								three.destroy();
							}
						});
					case 3:
						var two:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mazin/two', 'exe'));
						two.scrollFactor.set();
						two.screenCenter();
						two.y -= 100;
						two.alpha = 1;
						two.cameras = [camOther];
						add(two);
						FlxTween.tween(two, {y: two.y + 100, alpha: 0, "scale.x": 1.05, "scale.y": 1.05}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								two.destroy();
							}
						});
					case 2:
						var one:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mazin/one', 'exe'));
						one.scrollFactor.set();
						one.screenCenter();
						one.y -= 100;
						one.alpha = 1;
						one.cameras = [camOther];
						add(one);
						FlxTween.tween(one, {y: one.y + 100, alpha: 0, "scale.x": 1.05, "scale.y": 1.05}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								one.destroy();
							}
						});
					case 1:
						var gofun:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mazin/hitit', 'exe'));
						gofun.scrollFactor.set();
						gofun.updateHitbox();
						gofun.screenCenter();
						gofun.y -= 100;
						gofun.alpha = 1;
						add(gofun);
						FlxTween.tween(gofun, {y: gofun.y + 100, alpha: 0, "scale.x": 1.05, "scale.y": 1.05}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								gofun.destroy();
							}
						});
				}
			}

	function literallyMyHorizon()
		{
			boyfriend.visible = true;
			gf.visible = true;
			dadGroup.visible = true;
			fuckedBar = true;
			FlxG.camera.flash(FlxColor.BLACK, 1);
			defaultZoomin = true;
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1.5, {ease: FlxEase.cubeInOut});
			FlxTween.tween(camHUD, {alpha: 1}, 1.0);
			if (SONG.song.toLowerCase() == "vista") {
			    amyBop.visible = false;
			}
			fucklesDeluxe();
			if (SONG.song.toLowerCase() == "vista") {
			    FlxTween.tween(whiteFuck, {alpha: 0}, 2, {ease: FlxEase.cubeInOut});
			} else {
				FlxTween.tween(whiteFuck, {alpha: 0}, 2, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
					{
						remove(whiteFuck);
						whiteFuck.destroy();
					}
				});
			}

			camHUD.zoom += 2;

			//ee oo ee oo ay oo ay oo ee au ee ah
		}


	function iShouldKickUrFuckinAss(die:Int)
		{
			switch (die)
			{
				case 1:
					FlxG.camera.flash(FlxColor.GREEN, 1.5);
					FlxTween.tween(this, {barSongLength: songLength, health: 1}, 5, {ease: FlxEase.sineInOut});

					entranceSpookyBG.visible = true;
					entranceSpookyClock.visible = true;
					entranceSpookyIdk.visible = true;
					entranceSpookyFloor.visible = true;
					entranceSpookyOver.visible = true;

					FlxTween.tween(camHUD, {alpha: 1}, 0.5, {ease: FlxEase.cubeInOut});
						camHUD.zoom += 2;

					remove(entranceBG);
					entranceBG.destroy();
					remove(entranceClock);
					entranceClock.destroy();
					remove(entranceIdk);
					entranceIdk.destroy();
					remove(entranceFloor);
					entranceFloor.destroy();
					remove(entranceOver);
					entranceOver.destroy();
			        Paths.clearUnusedMemory();
					//the game is racist its over
					//this is a joke coming from a mixed dude shut the fuck up twitter.
				case 2:
					FlxTween.tween(this, {health: 1}, 5);
					FlxTween.tween(boyfriend, {alpha: 1}, 0.01);
					FlxTween.tween(gf, {alpha: 1}, 0.01);

					remove(vistaFlower);
					vistaFlower.destroy();
					remove(vistaTree);
					vistaTree.destroy();
					remove(vistaBush);
					vistaBush.destroy();
					remove(vistaGrass);
					vistaGrass.destroy();
					remove(vistaFloor);
					vistaFloor.destroy();
					remove(vistaBG);
					vistaBG.destroy();

					amyBop.visible = false;
					vectorBop.visible = false;
					charmyBop.visible = false;
					espioBop.visible = false;
					mightyBop.visible = false;
					knuxBop.visible = false;

					amyBopFucked.visible = true;
					charmyBopFucked.visible = true;
					vectorBopFucked.visible = true;
					espioBopFucked.visible = true;
					mightyBopFucked.visible = true;
					knuxBopFucked.visible = true;

					fuckedBG.visible = true;
					fuckedFloor.visible = true;
					fuckedGrass.visible = true;
					fuckedBush.visible = true;
					fuckedTree.visible = true;
					fuckedFlower.visible = true;
					fuckedTails.visible = true;
			}
		}

	function staticEvent()
	{
		FlxTween.tween(theStatic, {alpha: 0.9}, 1.5, {ease: FlxEase.quadInOut});

		new FlxTimer().start(0.9, function(tmr:FlxTimer) 
		{				
			FlxFlicker.flicker(theStatic, 0.5, 0.02, false, false);
		});
		new FlxTimer().start(1.5, function(tmr:FlxTimer) 
		{				
			FlxG.camera.flash(0xFF0edc7c, 1);
			theStatic.visible = false;
			theStatic.alpha = 0;
		});
	}

	function literallyOurHorizon()
		{
			defaultZoomin = true;
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.35, {ease: FlxEase.quadOut});
			FlxTween.tween(camHUD, {alpha: 1}, 0.5);
			FlxTween.tween(dad, {alpha: 1}, 0.1, {ease: FlxEase.cubeInOut});
			FlxTween.tween(boyfriend, {alpha: 1}, 0.1, {ease: FlxEase.cubeInOut});
			FlxTween.tween(whiteFuck, {alpha: 0}, 1, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
				{
					remove(whiteFuck);
					whiteFuck.destroy();
					GameOverSubstate.characterName = 'bf-holding-gf-dead';
				}
			});

			healthBar.x -= 150;
			iconP1.x -= 150;
			iconP2.x -= 150;
			healthBarBG.x -= 150;

			add(timeBarBG);
			add(timeTxt);
			add(songNameHUD);
			add(scoreTxt);

			timeBarBG.visible = !ClientPrefs.hideHud;
			fakeTimeBar.visible = !ClientPrefs.hideHud;
			timeBar.visible = !ClientPrefs.hideHud;
			timeTxt.visible = !ClientPrefs.hideHud;
			scoreTxt.visible = !ClientPrefs.hideHud;
			chaotixHUD.visible = false;

			fucklesBGPixelLegacy.visible = false;
			fucklesFGPixelLegacy.visible = false;

			horizonBgLegacy.visible = true;
			horizonFloorLegacy.visible = true;
			horizonTreesLegacy.visible = true;
			horizonTrees2Legacy.visible = true;

			horizonPurpurLegacy.visible = true;
			horizonYellowLegacy.visible = true;
			horizonRedLegacy.visible = true;

			horizonAmyLegacy.visible = true;
			horizonCharmyLegacy.visible = true;
			horizonEspioLegacy.visible = true;
			horizonMightyLegacy.visible = true;
			horizonKnucklesLegacy.visible = true;
			horizonVectorLegacy.visible = true;

            reloadTheNotesPls();
		}


	function reloadTheNotesPls()
	{
		playerStrums.forEach(function(spr:StrumNote)
		{
			spr.reloadNote();
		});
		opponentStrums.forEach(function(spr:StrumNote)
		{
			spr.reloadNote();
		});
		notes.forEach(function(spr:Note)
		{
			spr.reloadNote();
		});
	}

	function changeIcon(change:String, colorArray:Array<Int>)
        {
            var character:Character = null;
            var icon:FlxSprite = null;

            switch (change.toLowerCase())
            {
                case "dad", "1", "opponent":
                    character = dad;
                    icon = iconP2;
                case "bf", "0":
                    character = boyfriend;
                    icon = iconP1;
            }

            if (character != null && icon != null)
            {
                var source:Character = getSingingCharacter([character, gf]);
                if (source != null)
                {
                    icon.changeIcon(source.healthIcon);
                    character.healthColorArray = source.healthColorArray.copy();
                    triggerEventNote("Change Character", change.toLowerCase(), character.curCharacter);
                }
            }
        }

        function getSingingCharacter(characters:Array<Character>):Character
        {
            for (char in characters)
            {
                if (char.animation.curAnim != null)
                {
                    var animName = char.animation.curAnim.name;
                    if (animName.startsWith("sing") || animName.endsWith("-miss") || animName.endsWith("-alt"))
                        return char;
                }
            }
            return null;
        }

	//bf pixel feet
	function bfFeetAppear(hello:Int) {
        switch (hello) {
			case 1:
				add(bfSEFeet);
				bfSEFeet.visible = true;
			case 0:
				remove(bfSEFeet);
		}
	}
	
	function removeShit(fuck:Int)
	{
		switch(fuck)
			{
				case 1:
					fucklesEspioBgLegacy.animation.stop();
					fucklesMightyBgLegacy.animation.stop();
					fucklesCharmyBgLegacy.animation.stop();
					fucklesAmyBgLegacy.animation.stop();
					fucklesKnuxBgLegacy.animation.stop();
					fucklesVectorBgLegacy.animation.stop();
				
				case 2:
				    fucklesEspioBgLegacy.visible = false;
					fucklesMightyBgLegacy.visible = false;
					fucklesCharmyBgLegacy.visible = false;
					fucklesAmyBgLegacy.visible = false;
					fucklesKnuxBgLegacy.visible = false;
					fucklesVectorBgLegacy.visible = false;
					
				case 3:
				    horizonBgLegacy.visible = false;
					horizonFloorLegacy.visible = false;
					horizonTreesLegacy.visible = false;
					horizonTrees2Legacy.visible = false;

					horizonPurpurLegacy.visible = false;
					horizonYellowLegacy.visible = false;
					horizonRedLegacy.visible = false;

					horizonAmyLegacy.visible = false;
					horizonCharmyLegacy.visible = false;
					horizonEspioLegacy.visible = false;
					horizonMightyLegacy.visible = false;
					horizonKnucklesLegacy.visible = false;
					horizonVectorLegacy.visible = false;

					dadGroup.visible = false;
					boyfriendGroup.visible = false;
			}
	}


	function fucklesDeluxe()
	{
		health = 2;
		//songMisses = 0;
		fucklesMode = true;

		timeBar.visible = false;
		timeTxt.visible = false;
		scoreTxt.visible = false;
        if (SONG.song.toLowerCase() == "my-horizon-legacy") {
			timeBarBG.visible = false;
		} else if (SONG.song.toLowerCase() == "vista") {
			scoreTxt.visible = true;
		}

		opponentStrums.forEach(function(spr:FlxSprite)
		{
			spr.x += 10000;
		});
	}

			// ok might not do this lmao

	var fuckedMode:Bool = false;

	function fucklesFinale()
	{
		if (fucklesMode)
			fuckedMode = true;
		if (fuckedMode)
		{
			health -= 0.1;
			if (health <= 0.01)
			{
				health = 0.01;
				fuckedMode = false;
			}
			//nerfed 2nd mechanic for vista
			if (SONG.song.toLowerCase() == "vista") {
				if (health <= 0.0555)
				{
					health = 0.0555;
					fuckedMode = false;
				}
			}
		}
	}

    var lyricText:FlxText;
	var lyricTween:FlxTween;

	function writeLyrics(text:String, duration:Float, color:FlxColor)
		{
			if (lyricText != null) {
				var old:FlxText = cast lyricText;
				FlxTween.tween(old, {alpha: 0}, 0.2, {onComplete: function(twn:FlxTween)
				{
					remove(old);
					old.destroy();
				}});
				lyricText = null;
			}
			if (lyricTween != null){
				lyricTween.cancel();
				lyricTween=null;
			}
			if (text.trim() != '' && duration > 0 && color.alphaFloat > 0) {
				lyricText = new FlxText(0, 0, FlxG.width, text);
				lyricText.setFormat(Paths.font("chaotix.ttf"), 24, color, CENTER, OUTLINE, FlxColor.BLACK);
				if (SONG.song.toLowerCase() == 'found-you-legacy') {
					lyricText.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 24, color, CENTER, OUTLINE, FlxColor.BLACK);
				}
				lyricText.alpha = 0;
				lyricText.screenCenter(XY);
				lyricText.y += 250;
				lyricText.cameras = [camOther];
				add(lyricText);
				lyricTween = FlxTween.tween(lyricText, {alpha: color.alphaFloat}, 0.2, {onComplete: function(twn:FlxTween)
				{
					lyricTween = FlxTween.tween(lyricText, {alpha: 0}, 0.2, {startDelay: duration, onComplete: function(twn:FlxTween)
					{
						remove(lyricText);
						lyricText.destroy();
						lyricText = null;
						if(lyricTween==twn)lyricTween = null;
					}});
				}});
			}
		}

	function fucklesHealthRandomize()
	{
		if (fucklesMode)
			health = FlxG.random.float(0.5, 2);
		// randomly sets health between max and 0.5,
		// this im gonna use for stephits and basically
		// have it go fucking insane in some parts and disable the drain and reenable when needed
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(event, args);
			if(ret == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == FunkinLua.Function_Continue;
			if(!bool && ret != 0) {
				returnVal = cast ret;
			}
		}
		#end
		//trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(field:PlayField, id:Int, time:Float, ?note:Note) {
		var spr:StrumNote = field.members[id];

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "";

			if(fcLabel!=null){
				if(fcLabel.animation.curAnim!=null){
					if(fcLabel.animation.getByName(ratingFC)!=null && fcLabel.animation.curAnim.name!=ratingFC){
						var frame = fcLabel.animation.curAnim.curFrame;
						fcLabel.animation.play(ratingFC,true);
						fcLabel.animation.curAnim.curFrame = frame;
					}
				}else if(fcLabel.animation.getByName(ratingFC)!=null){
					fcLabel.animation.play(ratingFC,true);
				}
				fcLabel.visible=songMisses<10;
			}
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end


	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
