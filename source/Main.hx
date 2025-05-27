package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.FlxCamera;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.system.System;
import lime.app.Application;
#if sys
import sys.FileSystem;
#end

#if CRASH_HANDLER
import CrashHandler;
#end

#if mobile
import mobile.MobileScaleMode;
#end

using CoolUtil;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

//@:nullSafety
class Main extends Sprite
{
    public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: Intro, // initial game state
        zoom: -1, // If -1, zoom is automatically calculated to fit the window dimensions.
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};
    
    public static var fpsVar:FPS;

    // You can pretty much ignore everything from here on - your code should go in your states.
    public static var path:String = System.applicationStorageDirectory;

    @:dox(hide)
	public static var audioDisconnected:Bool = false;

    public static var changeID:Int = 0;

    static final videva:Array<String> = [
        "II_Intro",
        "breakout_cut",
        "hellspawn_cut"
    ];
    
    public static function main():Void
    {
        Lib.current.addChild(new Main());
	    #if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
    }

    public function new()
    {
        super();

	    #if CRASH_HANDLER
	    CrashHandler.init();
	    #end

        if (stage != null)
        {
            init();
        }
        else
        {
            addEventListener(Event.ADDED_TO_STAGE, init);
        }
    }

    private function init(?E:Event):Void
    {
        if (hasEventListener(Event.ADDED_TO_STAGE))
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);
        }

        setupGame();
    }

    private function setupGame():Void
    {
	    #if (openfl < '9.2.0')
        var stageWidth:Int = Lib.current.stage.stageWidth;
	    var stageHeight:Int = Lib.current.stage.stageHeight;

	    if (game.zoom == -1)
	    {
		    var ratioX:Float = stageWidth / game.width;
		    var ratioY:Float = stageHeight / game.height;
		    game.zoom = Math.min(ratioX, ratioY);
		    game.width = Math.ceil(stageWidth / game.zoom);
		    game.height = Math.ceil(stageHeight / game.zoom);
	    }
        #elseif (openfl >= '9.2.0')
        if (game.zoom == -1) {
            game.zoom = 1;
        }
	    #end

        #if (cpp && windows)
		lime.Native.fixScaling();
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

        #if mobile
        Generic.mode = MEDIAFILE;
	    if (!FileSystem.exists(Generic.returnPath() + 'assets')) {
		    FileSystem.createDirectory(Generic.returnPath() + 'assets');
            }
	    if (!FileSystem.exists(Generic.returnPath() + 'assets/videos')) {
		    FileSystem.createDirectory(Generic.returnPath() + 'assets/videos');
	    }
            if (!FileSystem.exists(Generic.returnPath() + 'assets/weeks')) {
		    FileSystem.createDirectory(Generic.returnPath() + 'assets/weeks');
	    }
	    if (!FileSystem.exists(Generic.returnPath() + 'assets/scripts')) {
		    FileSystem.createDirectory(Generic.returnPath() + 'assets/scripts');
	    }

	    for (video in videva) {
		    Generic.copyContent(Paths._video(video), Paths._video(video));
	    }    
        #end

        ClientPrefs.loadDefaultKeys();
	    // fuck you, persistent caching stays ON during sex
	    FlxGraphic.defaultPersist = true;
	    // the reason for this is we're going to be handling our own cache smartly

        #if !VIDEOS_ALLOWED
        game.initialState = TitleState;
        #end

        addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

        fpsVar = new FPS(10, 3, 0xFFFFFF);
        addChild(fpsVar);
        Lib.current.stage.align = "tl";
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        if(fpsVar != null) {
            fpsVar.visible = ClientPrefs.showFPS;
        }

	    FlxG.signals.gameResized.add(function (w, h) {
            if (fpsVar != null)
                fpsVar.positionFPS(10, 3, Math.min(w / FlxG.width, h / FlxG.height));

            if (FlxG.cameras != null && FlxG.cameras.list != null) {
                for (cam in FlxG.cameras.list) {
                    if (cam != null)
                        resetSpriteCache(cam.flashSprite);
                }
            }

            if (FlxG.game != null)
                resetSpriteCache(FlxG.game);
        });

        FlxG.fixedTimestep = false;
	    FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;
        FlxG.keys.preventDefaultKeys = [TAB];

	    #if mobile
	    FlxG.signals.postGameStart.addOnce(() -> {
		    FlxG.scaleMode = new MobileScaleMode();
	    });
	    #end

	    #if android 
	    FlxG.android.preventDefaultKeys = [BACK]; 
	    #end
    }

    private static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		    sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
    }

    #if (cpp || hl)
    private static function onError(message:Dynamic):Void
    {
            throw Std.string(message);
    }
    #end
	
    public function getFPS():Float {
	    return fpsVar.currentFPS;	
    }
}
