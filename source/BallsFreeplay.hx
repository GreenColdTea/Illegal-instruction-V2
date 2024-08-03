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

    var songtext:Array<String> = [
        'Breakout',
        'Hellspawn',
        'Vista',
        'Meltdown',
        'Cascade',
        'My Horizon',
        'Color Crash'
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
        'bf-pixel',
        'bf-pixel',
        'bf-pixel',
        'BFLMAO',
        'bf-pixel',
        'bf-pixel',
        'mighty'
    ];
	
    var backgroundShits:FlxTypedGroup<FlxSprite>;

    var screenSong:FlxTypedGroup<FlxText>;

    var screenInfo:FlxTypedGroup<FlxSprite>;
    var screenCharacters:FlxTypedGroup<FlxSprite>;
    var screenPlayers:FlxTypedGroup<FlxSprite>;

    //bf settings
    var player:FlxSprite; //player is FlxSprite
    public var isHoldingLeft:Bool = false; // left button pressed checker
    public var isHoldingRight:Bool = false; // right button pressed checker
    public var isJumping:Bool = false; // jumping checker
    var holdTimer:FlxTimer; // after this bf start running
    public var speed:Float = 125; // needs for bf's moves
    public var speedMultiplier:Float = 1.25; // bf's default walk speed
    public var jumpSpeed:Float = 225; //how fast he can jump
    public var gravity:Float = 425; //how long he can be in the air

    public var numSelect:Int = 0;

    override function create()
    {
        Paths.clearStoredMemory();
	Paths.clearUnusedMemory();

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

	screenSong = new FlxTypedGroup<FlxText>();
	          add(screenSong);

        screenInfo = new FlxTypedGroup<FlxSprite>();
		  add(screenInfo);

        screenCharacters = new FlxTypedGroup<FlxSprite>();
		  add(screenCharacters);

	screenPlayers = new FlxTypedGroup<FlxSprite>();
	         add(screenPlayers);

        var characterText:FlxText;
        var scoreText:FlxText;
        var proceedText:FlxText;
        var yn:FlxText;

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

	    characterText = new FlxText(0, 0, '${songtext[i]}');
            characterText.setFormat(Paths.font("pixel.otf"), 17, FlxColor.RED, CENTER);
	    characterText.x -= 50;
	    characterText.y -= 50;
            characterText.color = FlxColor.RED;
	    characterText.alpha = 0;
	    screenSong.add(characterText);

            var songCharacter:FlxSprite = new FlxSprite();
            songCharacter.frames = Paths.getSparrowAtlas('freeplay/characters/${characters[i]}');
            songCharacter.animation.addByPrefix('idle', '${characters[i]}', 24, true);
            songCharacter.animation.play('idle');
            songCharacter.screenCenter();
            songCharacter.scale.set(3, 3);
            songCharacter.x -= 360;
            songCharacter.y -= 70;
            songCharacter.alpha = 0;

            var songPlayable:FlxSprite = new FlxSprite();
            songPlayable.frames = Paths.getSparrowAtlas('freeplay/playables/${playables[i]}');
            songPlayable.animation.addByPrefix('idle', '${playables[i]}', 24, true);
            songPlayable.animation.play('idle');
            songPlayable.screenCenter();
            songPlayable.scale.set(3, 3);
            songPlayable.x += 325;
            songPlayable.y -= 60;
            songPlayable.alpha = 0;

	    if (playables[3] == 'BFLMAO') {
               songCharacter.scale.set(0.5, 0.5);
	    } else {
		 songCharacter.scale.set(3, 3);
	    }
		
            if(i == 0)

	    screenCharacters.add(songCharacter);
            screenPlayers.add(songPlayable);

            songPortrait.ID = i;
            songCharacter.ID = i;
            songPlayable.ID = i;
	    characterText.ID = i;

	    if(characterText.ID == curSelected)
		characterText.alpha = 1;

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

	var screenLogo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/logo'));
	screenLogo.scale.set(1.25, 1.25);
	screenLogo.screenCenter(X);
	screenLogo.updateHitbox();
	screenLogo.x -= 30;
	screenLogo.y += 75;
	add(screenLogo);

	player = new FlxSprite(450, 250);
        player.frames = Paths.getSparrowAtlas('freeplay/encore/BFMenu');
        player.animation.addByPrefix('idle', 'BF_Idle', 24, true);
        player.animation.addByPrefix('jump', 'BF_Jump', 24, true);
        player.animation.addByPrefix('walk', 'BF_Walk', 24, true);
        player.animation.addByPrefix('run', 'BF_Run', 24, true);
        player.antialiasing = true;
        add(player);

	#if !android
        yn = new FlxText(0, 0, 'PRESS 3 TO SWITCH FREEPLAY\nTHEMES');
        #else
        yn = new FlxText(0, 0, 'PRESS X TO SWITCH FREEPLAY\nTHEMES');
        #end
        yn.setFormat(Paths.font("chaotix.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        yn.visible = true;
	yn.y += 650;
        yn.color = FlxColor.WHITE;
        yn.borderSize = 0.9;
        add(yn);

	#if android
        addVirtualPad(LEFT_FULL, A_B_X_Y);
        #end

	if (ClientPrefs.ducclyMix)
        {
	    FlxG.sound.music.stop();
            FlxG.sound.playMusic(Paths.music('freeplayThemeDuccly'), 0);
            FlxG.sound.music.fadeIn(4, 0, 0.85);
        }
        else if (!ClientPrefs.ducclyMix)
        {
	    FlxG.sound.music.stop();
            FlxG.sound.playMusic(Paths.music('freeplayTheme'), 0);
            FlxG.sound.music.fadeIn(4, 0, 0.85);
        }

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
        if (#if !android FlxG.keys.justPressed.THREE #else _virtualpad.buttonX.justPressed #end && ClientPrefs.ducclyMix)
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
            speedMultiplier = 1.25;
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
            speedMultiplier = 1.25;
            holdTimer.cancel();
        }

	if (FlxG.keys.pressed.SPACE #if mobile || _virtualpad.buttonY.pressed #end && !isJumping && isOnGround())
        {
	    player.animation.play('jump');
	    FlxG.sound.play(Paths.sound('jump'), 0.6);
            player.velocity.y = -jumpSpeed;
            isJumping = true;
	}

	//screen barriers
	if (player.x < -75)
        {
            player.x = -75;
            player.velocity.x = 0;
        }
        else if (player.x + player.width > FlxG.width + 75)
        {
            player.x = FlxG.width + 75 - player.width;
            player.velocity.x = 0;
        }

        if (player.y < 0)
        {
            player.y = 0;
            player.velocity.y = 0;
        }
        else if (player.y + player.height > FlxG.height - 50)
        {
            player.y = FlxG.height - player.height - 50;
            isJumping = false; // jumping system
            player.velocity.y = 0;
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
	else if (!isOnGround())
        {
            player.velocity.y += gravity * elapsed;
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
        screenCharacters.members[curSelected].alpha = 0;
        screenPlayers.members[curSelected].alpha = 0;
	
        curSelected = newIndex;

        screenInfo.members[curSelected].alpha = 1;
        screenCharacters.members[curSelected].alpha = 1;
        screenPlayers.members[curSelected].alpha = 1;
    }
	
    function doTheLoad()
    {
        var songLowercase:String = Paths.formatToSongPath(songs[curSelected]);
        PlayState.SONG = Song.loadFromJson(songLowercase + '-hard', songLowercase);
        PlayState.isStoryMode = false;
        PlayState.storyDifficulty = 2;
        LoadingState.loadAndSwitchState(new PlayState());
	FlxG.sound.music.volume = 0;
	FreeplayState.destroyFreeplayVocals();
    }

    //timer end function
    function onHoldComplete(timer:FlxTimer):Void
    {
        if (isHoldingLeft || isHoldingRight)
        {
            player.animation.play('run');
            speedMultiplier = 2.05;
        }
    }
    // character is on the ground???
    function isOnGround():Bool
    {
        return player.y + player.height >= FlxG.height - 1;
    }
}
