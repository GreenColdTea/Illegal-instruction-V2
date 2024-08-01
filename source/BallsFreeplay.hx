package;

#if windows
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxInput.FlxInputState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDirectionFlags;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
#if MODS_ALLOWED
import sys.FileSystem;
#end
using StringTools;

class BallsFreeplay extends MusicBeatState
{  
    var songs:Array<String> = [
        'breakout',
        'soulless-endeavors',
        'vista',
        'meltdown',
        'cascade',
        'my-horizon',
        'color-crash'
    ];

    var characters:Array<String> = [
        'duke',
        'duke',
        'chaotix',
        'chotix',
        'ashura',
        'wechidna',
        'wechnia'
    ];
 
    var playables:Array<String> = [
        'bf',
        'bf',
        'bf',
        'bf',
        'bf',
        'bf',
        'mighty'
    ];
	
    var backgroundShits:FlxTypedGroup<FlxSprite>;

    var screenInfo:FlxTypedGroup<FlxSprite>;
    var screenCharacters:FlxTypedGroup<FlxSprite>;

    public var numSelect:Int = 0;

    override function create()
    {
        Paths.clearStoredMemory();
	Paths.clearUnusedMemory();

	//bf settings
	var isHoldingLeft:Bool = false; // left button pressed checker
        var isHoldingRight:Bool = false; // right button pressed checker
        var holdTimer:FlxTimer; // after this bf start running
        var speed:Float = 100; // needs for bf's moves
        var speedMultiplier:Float = 1.0; // bf's default walk speed

        if (ClientPrefs.ducclyMix)
        {
            FlxG.sound.playMusic(Paths.music('freeplayThemeDuccly'), 0);
            FlxG.sound.music.fadeIn(4, 0, 0.7);
        }
        else
        {
            FlxG.sound.playMusic(Paths.music('freeplayTheme'), 0);
            FlxG.sound.music.fadeIn(4, 0, 0.7);
        }

        transIn = FlxTransitionableState.defaultTransIn;
	transOut = FlxTransitionableState.defaultTransOut;

        FlxG.mouse.visible = true;

        #if windows
		  // Updating Discord Rich Presence
		  DiscordClient.changePresence("Selecting The New World.", null);
		  #end

        var blackFuck:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
        blackFuck.screenCenter();
        add(blackFuck);

        holdTimer = new FlxTimer();

        backgroundShits = new FlxTypedGroup<FlxSprite>();
		  add(backgroundShits);

        screenInfo = new FlxTypedGroup<FlxSprite>();
		  add(screenInfo);

        screenCharacters = new FlxTypedGroup<FlxSprite>();
		  add(screenCharacters);

        var characterText:FlxText;
        var scoreText:FlxText;
        var proceedText:FlxText;
        var yn:FlxText;

        #if !android
        yn = new FlxText(0, 0, 'PRESS 3 TO SWITCH FREEPLAY \nTHEMES');
        #else
        yn = new FlxText(0, 0, 'PRESS X TO SWITCH FREEPLAY\nTHEMES');
        #end
        yn.setFormat(Paths.font("chaotix.ttf"), 14, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        yn.visible = true;
	yn.x -= 100;
	yn.y -= 600;
        yn.color = FlxColor.WHITE;
        yn.borderSize = 0.9;
        add(yn);

        for(i in 0...songs.length)
        {
            var songPortrait:FlxSprite = new FlxSprite();

            songPortrait.loadGraphic(Paths.image('freeplay/screen/${songs[i]}'));

            songPortrait.screenCenter();
            songPortrait.antialiasing = false;
            songPortrait.scale.set(4.5, 4.5);
            songPortrait.y -= 60;
            songPortrait.alpha = 0;
            screenInfo.add(songPortrait);

            var songCharacter:FlxSprite = new FlxSprite();
            songCharacter.frames = Paths.getSparrowAtlas('freeplay/screen/${characters[i]}');
            songCharacter.animation.addByPrefix('idle', '${characters[i]}', 24, true);
            songCharacter.animation.play('idle');
            songCharacter.screenCenter();
            songCharacter.scale.set(3, 3);
            songCharacter.x -= 360;
            songCharacter.y -= 70;
            songCharacter.alpha = 0;
            if(i == 0)
            songCharacter.flipX = true;

            screenCharacters.add(songCharacter);

            var songPlayable:FlxSprite = new FlxSprite();
            songPlayable.frames = Paths.getSparrowAtlas('freeplay/playables/${playables[i]}');
            songPlayable.animation.addByPrefix('idle', '${playables[i]}', 24, true);
            songPlayable.animation.play('idle');
            songPlayable.screenCenter();
            songPlayable.scale.set(0.5, 0.5);
            songPlayable.x += 200;
            songPlayable.y -= 100;
            songPlayable.alpha = 0;
            if(i == 0)

            screenCharacters.add(songPlayable);

            songPortrait.ID = i;
            songCharacter.ID = i;
            songPlayable.ID = i;

            if(songPortrait.ID == curSelected)
                songPortrait.alpha = 1;

            if(songCharacter.ID == curSelected)
                songCharacter.alpha = 1;
      
            if(songPlayable.ID == curSelected)
                songPlayable.alpha = 1;

            /* 
            After those make a screen shit for each pixel background all in 1 location and then add
            them to pixelShits
            */

            //Each song has a background
        }

        var screen:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/Frame'));
        screen.setGraphicSize(FlxG.width, FlxG.height);
        screen.updateHitbox();
        add(screen);

        var player:FlxSprite; //player is FlxSprite

	player = new FlxSprite(500, -405);
        player.frames = Paths.getSparrowAtlas('freeplay/encore/BFMenu');
        player.animation.addByPrefix('idle', 'BF_Idle', 24, true);
        player.animation.addByPrefix('jump', 'BF_Jump', 24, true);
        player.animation.addByPrefix('walk', 'BF_Walk', 24, true);
        player.animation.addByPrefix('run', 'BF_Run', 24, true);
        player.antialiasing = true;
        add(player);

	#if android
        addVirtualPad(LEFT_FULL, A_B_X_Y);
        #end

        super.create();
    }

    var infoScreen:Bool = false;
    var curSelected:Int = 0;

    override function update(elapsed:Float)
    {
        if (#if !android FlxG.keys.justPressed.THREE #else _virtualpad.buttonX.justPressed #end && !ClientPrefs.ducclyMix)
        {
           ClientPrefs.ducclyMix = true;
        }
        else if (#if !android FlxG.keys.justPressed.THREE #else _virtualpad.buttonX.justPressed #end && ClientPrefs.ducclyMix)
        {
           ClientPrefs.ducclyMix = false;
        }
	    
        if (controls.UI_UP_P)
        {
            changeSelection(-1);
        }
        if (controls.UI_DOWN_P)
        {
            changeSelection(1);
        }
        if (controls.ACCEPT)
        {
            doTheLoad();
        }
        if (controls.BACK)
        {
            switchToBack();
        }

        // bf's control buttons settinngs
        if (controls.UI_LEFT_P)
        {
            player.flipX = false;
            if (!isHoldingLeft)
            {
                player.animation.play('walk');
                isHoldingLeft = true;
                holdTimer.start(1, onHoldComplete);
            }
        }
        else if (controls.UI_LEFT_R)
        {
            player.animation.play('walk');
            player.flipX = false;
            isHoldingLeft = false;
            speedMultiplier = 1.0;
            holdTimer.cancel();
        }

        if (controls.UI_RIGHT_P)
        {
            player.flipX = true;
            if (!isHoldingRight)
            {
                player.animation.play('walk');
                isHoldingRight = true;
                holdTimer.start(1, onHoldComplete);
            }
        }
        else if (controls.UI_RIGHT_R)
        {
            player.animation.play('walk');
            player.flipX = true;
            isHoldingRight = false;
            speedMultiplier = 1.0;
            holdTimer.cancel();
        }

        // bf moves
        if (isHoldingLeft)
        {
            player.velocity.x = -speed * speedMultiplier;
        }
        else if (isHoldingRight)
        {
            player.velocity.x = speed * speedMultiplier;
        }
        else
        {
            player.velocity.x = 0;
            player.animation.play('idle');

        }

        super.update(elapsed);
    }

    // go to main menu
    public function switchToBack() 
    {
	FlxG.sound.play(Paths.sound('cancelMenu'));
	FlxG.mouse.visible = false;
        FlxG.sound.playMusic(Paths.music('freakyMenu'));
        MusicBeatState.switchState(new MainMenuState());
    }

    //song selection changing function
    function changeSelection(direction:Int)
    {
        var newIndex:Int = curSelected + direction;
        if (newIndex < 0) newIndex = songs.length - 1;
        else if (newIndex >= songs.length) newIndex = 0;

        updateSelection(newIndex);
    }

    //selection update
    function updateSelection(newIndex:Int)
    {
        screenInfo.members[curSelected].alpha = 0;
        screenCharacters.members[curSelected * 2].alpha = 0;
        screenCharacters.members[curSelected * 2 + 1].alpha = 0;

        curSelected = newIndex;

        screenInfo.members[curSelected].alpha = 1;
        screenCharacters.members[curSelected * 2].alpha = 1;
        screenCharacters.members[curSelected * 2 + 1].alpha = 1;
    }
	
    function doTheLoad()
    {
        var songLowercase:String = Paths.formatToSongPath(songs[curSelected]);
        PlayState.SONG = Song.loadFromJson(songLowercase + '-hard', songLowercase);
        PlayState.isStoryMode = false;
        PlayState.storyDifficulty = 2;
        LoadingState.loadAndSwitchState(new PlayState());
    }

    //timer end function
    function onHoldComplete(timer:FlxTimer):Void
    {
        if (isHoldingLeft || isHoldingRight)
        {
            player.animation.play('run');
            speedMultiplier = 1.75;
        }
    }
}
