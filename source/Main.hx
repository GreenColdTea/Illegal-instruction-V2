import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxSprite;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;

class Main extends Sprite
{
    var gameWidth:Int = 1280;
    var gameHeight:Int = 720;
    var initialState:Class<FlxState> = TitleState;
    var zoom:Float = -1;
    var framerate:Int = 60;
    var skipSplash:Bool = true;
    var startFullscreen:Bool = false;
    public static var fpsVar:FPS;

    public static function main():Void
    {
        Lib.current.addChild(new Main());
    }

    public function new()
    {
        super();

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
        var stageWidth:Int = Lib.current.stage.stageWidth;
        var stageHeight:Int = Lib.current.stage.stageHeight;

        if (zoom == -1 && !ClientPrefs.noBordersScreen) {
            zoom = 1;
        }

        if (ClientPrefs.noBordersScreen) {
            resizeGame();
        }

        addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));

        fpsVar = new FPS(10, 3, 0xFFFFFF);
        addChild(fpsVar);
        Lib.current.stage.align = "tl";
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        if(fpsVar != null) {
            fpsVar.visible = ClientPrefs.showFPS;
        }
    }

    private function resizeGame():Void
    {
        var stageWidth:Int = Lib.current.stage.stageWidth;
        var stageHeight:Int = Lib.current.stage.stageHeight;

        var aspectRatio:Float = 16.0 / 9.0;

        if (stageWidth / stageHeight > aspectRatio)
        {
            gameHeight = stageHeight;
            gameWidth = Std.int(gameHeight * aspectRatio);
        }
        else
        {
            gameWidth = stageWidth;
            gameHeight = Std.int(gameWidth / aspectRatio);
        }

        var ratioX:Float = stageWidth / gameWidth;
        var ratioY:Float = stageHeight / gameHeight;
        zoom = Math.min(ratioX, ratioY);

        FlxG.resizeGame(gameWidth, gameHeight);

        var camera:FlxCamera = FlxG.camera;
        camera.setScrollBoundsRect(0, 0, gameWidth, gameHeight);
        camera.zoom = zoom;
    }
}
