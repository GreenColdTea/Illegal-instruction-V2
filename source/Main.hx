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
import sys.FileSystem;
import lime.system.System;

#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

#if mobile
import android.MobileScaleMode;
#end

using CoolUtil;

class Main extends Sprite
{
    var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
    var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
    var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
    var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
    var framerate:Int = 60; // How many frames per second the game should run at.
    var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
    var startFullscreen:Bool = true; // Whether to start the game in fullscreen on desktop targets
    public static var fpsVar:FPS;

    // You can pretty much ignore everything from here on - your code should go in your states.
    public static var path:String = System.applicationStorageDirectory;

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

	Generic.initCrashHandler();

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

	#if cpp
	untyped __global__.__hxcpp_set_critical_error_handler(onError);
	#elseif hl
	hl.Api.setErrorHandler(onError);
	#end

        setupGame();
    }

    private function setupGame():Void
    {
	#if (openfl < '9.2.0')
        var stageWidth:Int = Lib.current.stage.stageWidth;
	var stageHeight:Int = Lib.current.stage.stageHeight;

	if (zoom == -1)
	{
		var ratioX:Float = stageWidth / gameWidth;
		var ratioY:Float = stageHeight / gameHeight;
		zoom = Math.min(ratioX, ratioY);
		gameWidth = Math.ceil(stageWidth / zoom);
		gameHeight = Math.ceil(stageHeight / zoom);
	}
        #elseif (openfl >= '9.2.0')
        if (zoom == -1) {
            zoom = 1;
        }
	#end

        Generic.mode = ROOTDATA;
	if (!FileSystem.exists(Generic.returnPath() + 'assets')) {
		FileSystem.createDirectory(Generic.returnPath() + 'assets');
        }

        ClientPrefs.loadDefaultKeys();
	// fuck you, persistent caching stays ON during sex
	FlxGraphic.defaultPersist = true;
	// the reason for this is we're going to be handling our own cache smartly

        addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));

        fpsVar = new FPS(10, 3, 0xFFFFFF);
        addChild(fpsVar);
        Lib.current.stage.align = "tl";
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        if(fpsVar != null) {
            fpsVar.visible = ClientPrefs.showFPS;
        }

	FlxG.signals.gameResized.add(function (w, h) {
	    if(fpsVar != null)
		fpsVar.positionFPS(10, 3, Math.min(w / FlxG.width, h / FlxG.height));
	    if (FlxG.cameras != null) {
		for (cam in FlxG.cameras.list) {
		     if (cam != null && cam.filters != null)
			 resetSpriteCache(cam.flashSprite);
		}
	    }

	    if (FlxG.game != null)
		resetSpriteCache(FlxG.game);
	});

	#if mobile
	FlxG.scaleMode = new MobileScaleMode();
	#end

	#if android 
	FlxG.android.preventDefaultKeys = [BACK]; 
	#end
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
