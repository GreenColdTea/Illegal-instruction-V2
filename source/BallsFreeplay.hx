package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import openfl.text.TextField;
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
import haxe.io.Path;
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
        'Color \nCrash'
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
    var scoreText:FlxText;

    var screenInfo:FlxTypedGroup<FlxSprite>;
    var screenCharacters:FlxTypedGroup<FlxSprite>;
    var screenPlayers:FlxTypedGroup<FlxSprite>;

    //bf settings
    var player:FlxSprite; //player is FlxSprite
    public var isHoldingLeft:Bool = false; // left button pressed checker
    public var isHoldingRight:Bool = false; // right button pressed checker
    public var isJumping:Bool = false; // jumping checker
    var holdTimer:FlxTimer = new FlxTimer(); // Timer for how long we're holding movement keys. Because holding keys should be timed like fine wine.
    public var speed:Float = 125; // needs for bf's moves
    public var speedMultiplier:Float = 1.25; // bf's default walk speed
    var jumpSpeed:Float = -300; // Vertical speed when jumping. Think of it as the character’s "I believe I can fly" moment.
    var gravity:Float = 600; // How fast we fall. Gravity's way of reminding us that the ground is always waiting.
    var maxJumpHeight:Float = 200; // Maximum height of our jump. Like reaching for the last slice of pizza.
    var jumpStartY:Float = 0; // Y position where we started jumping. Because you gotta know where you began your epic leap.

    // Ima alone man, so i decided to add some funni comments

    public var songIndex:Int = 0;
    static var lastSongIndex:Int = 0; // To keep the last selected song index
    var lerpScore:Int = 0;
    var intendedScore:Int = 0;

    override function create()
    {
        Paths.clearStoredMemory();
	    Paths.clearUnusedMemory();

        transIn = FlxTransitionableState.defaultTransIn;
	    transOut = FlxTransitionableState.defaultTransOut;

        FlxG.mouse.visible = true;

        #if desktop
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

	    screenPlayers = new FlxTypedGroup<FlxSprite>();
	    add(screenPlayers);

	    screenSong = new FlxTypedGroup<FlxText>();
	    add(screenSong);

    var characterText:FlxText;
    var proceedText:FlxText;
    var yn:FlxText;

	createMenuElements();
    updateScreen();

    var screen:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/Frame'));
    screen.setGraphicSize(FlxG.width, FlxG.height);
    screen.updateHitbox();
    add(screen);

	var screenLogo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/logo'));
	screenLogo.scale.set(2, 1.75);
	screenLogo.screenCenter(X);
	screenLogo.updateHitbox();
	screenLogo.x -= 92.5;
	screenLogo.y += 61;
	add(screenLogo);

    scoreText = new FlxText(925, 75, 0, "SCORE: \n49324858", 36);
    scoreText.setFormat(Paths.font("pixel.otf"), 32, FlxColor.RED, CENTER);
    add(scoreText);

	player = new FlxSprite(455, 250);
    player.frames = Paths.getSparrowAtlas('freeplay/encore/BFMenu');
    player.animation.addByPrefix('idle', 'BF_Idle', 24, true);
    player.animation.addByPrefix('jump', 'BF_Jump', 24, true);
    player.animation.addByPrefix('walk', 'BF_Walk', 24, true);
    player.animation.addByPrefix('run', 'BF_Run', 24, true);
    player.antialiasing = true;
    add(player);

	#if !android
    yn = new FlxText(0, 0, 'PRESS 3 TO SWITCH FREEPLAY \nTHEMES');
    #else
    yn = new FlxText(0, 0, 'PRESS X TO SWITCH FREEPLAY \nTHEMES');
    #end
    yn.setFormat(Paths.font("chaotix.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    yn.visible = true;
	yn.y += 650;
    yn.color = FlxColor.WHITE;
    yn.borderSize = 0.9;
    add(yn);

	CoolUtil.precacheMusic('freeplayThemeDuccly');
	CoolUtil.precacheMusic('freeplayTheme');

	#if android
    addVirtualPad(LEFT_FULL, A_B_C_X_Y);
    #end

	if (ClientPrefs.ducclyMix)
        {
            FlxG.sound.playMusic(Paths.music('freeplayThemeDuccly'), 0);
		    FlxG.sound.music.fadeIn(4, 0, 0.85);
        }
        else
        {
            FlxG.sound.playMusic(Paths.music('freeplayTheme'), 0);
		    FlxG.sound.music.fadeIn(4, 0, 0.85);
	    }

	songIndex = lastSongIndex;

        super.create();
    }

    var infoScreen:Bool = false;
    var curSelected:Int = 0;

    // menu elements recreation
    public function createMenuElements():Void {
        for (i in 0...songs.length) {
            var songPortrait:FlxSprite = new FlxSprite();
            songPortrait.loadGraphic(Paths.image('freeplay/screen/' + songs[i]));
            songPortrait.screenCenter();
            songPortrait.antialiasing = false;
            songPortrait.scale.set(4.5, 4.5);
            songPortrait.y -= 40;
            songPortrait.alpha = 0;
            songPortrait.ID = i;
            screenInfo.add(songPortrait);

            var songCharacter:FlxSprite = new FlxSprite();
            songCharacter.frames = Paths.getSparrowAtlas('freeplay/characters/' + characters[i]);
            songCharacter.animation.addByPrefix('idle', characters[i], 22, true);
            songCharacter.animation.play('idle');
            songCharacter.screenCenter();
            songCharacter.scale.set(3, 3);
            songCharacter.x -= 360;
            songCharacter.y = 245;
            songCharacter.alpha = 0;
            songCharacter.ID = i;
            if (songCharacter.ID == 6) {
                songCharacter.y = 282.5;
                songCharacter.x -= 15;
            }
            else if (songCharacter.ID == 5) {
                songCharacter.y += 12.5;
            }
            else if (songCharacter.ID == 4) {
                songCharacter.y += 37.5;
                songCharacter.x += 5;
            }
            else if (songCharacter.ID == 3) {
                songCharacter.x += 25;
                songCharacter.y -= 20;
                songCharacter.flipX = true;
            }
            else if (songCharacter.ID == 2) {
                songCharacter.y -= 60;
                songCharacter.flipX = true;
            }
            screenCharacters.add(songCharacter);

            var songPlayable:FlxSprite = new FlxSprite();
            songPlayable.frames = Paths.getSparrowAtlas('freeplay/playables/' + playables[i]);
            songPlayable.animation.addByPrefix('idle', playables[i], 14, true);
            songPlayable.animation.play('idle');
            songPlayable.screenCenter();
            songPlayable.scale.set(5.5, 5.5);
            songPlayable.x += 360;
            songPlayable.y -= 50;
            songPlayable.alpha = 0;
            songPlayable.ID = i;
            if (songPlayable.ID == 6) {
                songPlayable.y -= 2.5;
            }
            screenPlayers.add(songPlayable);

	        var characterText = new FlxText(0, 0, songs[i].replace("-", " \n").toUpperCase());
	        characterText.updateHitbox();
            characterText.screenCenter();
            characterText.setFormat(Paths.font("pixel.otf"), 35, FlxColor.RED, CENTER);
            characterText.x -= 475;
            characterText.y -= 280;
            characterText.alpha = 0;
            characterText.ID = i;
            screenSong.add(characterText);
            
        }
    }

    // screen update command
    public function updateScreen():Void {
        intendedScore = Highscore.getScore(Std.string([songIndex]), 2);
	    lastSongIndex = songIndex;
        for (sprite in screenInfo.members) {
            var flxSprite:FlxSprite = cast(sprite, FlxSprite);
            flxSprite.alpha = flxSprite.ID == songIndex ? 1 : 0;
        }
        for (sprite in screenCharacters.members) {
            var flxSprite:FlxSprite = cast(sprite, FlxSprite);
            flxSprite.alpha = flxSprite.ID == songIndex ? 1 : 0;
            if (flxSprite.ID == 4 || flxSprite.ID == 6) {
                flxSprite.scale.set(5.5, 5.5);
            }
            /*flxSprite.x = Math.max(0, flxSprite.x);
            flxSprite.y = Math.max(0, flxSprite.y);*/
        }
        for (sprite in screenPlayers.members) {
            var flxSprite:FlxSprite = cast(sprite, FlxSprite);
            flxSprite.alpha = flxSprite.ID == songIndex ? 1 : 0;
	        if (flxSprite.ID == 3) {
                flxSprite.scale.set(0.375, 0.375);
                //flxSprite.animation.curAnim.curFrame = 22;
            }
        }
	    for (sprite in screenSong.members) {
            var flxText:FlxText = cast(sprite, FlxText);
            flxText.alpha = flxText.ID == songIndex ? 1 : 0;
	    }
    }
	
    // Main update function, where all the magic happens
    override function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.THREE #if android || _virtualpad.buttonX.justPressed #end)
        {
            ClientPrefs.ducclyMix = !ClientPrefs.ducclyMix;
            FlxG.sound.music.stop();

	        if (ClientPrefs.ducclyMix)
            {
                FlxG.sound.playMusic(Paths.music('freeplayThemeDuccly'), 0);
		        FlxG.sound.music.fadeIn(4, 0, 0.85);
            }
            else
            {
                FlxG.sound.playMusic(Paths.music('freeplayTheme'), 0);
		        FlxG.sound.music.fadeIn(4, 0, 0.85);
	        }
        }

        lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
        if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

        intendedScore = Highscore.getScore(Paths.formatToSongPath(songs[songIndex]), 2);

        scoreText.text = "SCORE:" + "\n" + lerpScore;

	    if(FlxG.keys.pressed.CONTROL #if android || _virtualpad.buttonC.pressed #end)
	    {
	        persistentUpdate = false;
	        openSubState(new GameplayChangersSubstate());
	    }
	    
        if (controls.UI_UP_P)
        {
            songIndex = (songIndex - 1 + songs.length) % songs.length;
            updateScreen();
        }

        if (controls.UI_DOWN_P)
        {
            songIndex = (songIndex + 1) % songs.length;
            updateScreen();
        }

        if (controls.ACCEPT)
        {
            doTheLoad();
	        lastSongIndex = songIndex;
	        updateScreen();
        }

        if (controls.BACK)
        {
            switchToBack();
        }

        //BF left and right movement
        if (controls.UI_LEFT_P && !controls.UI_RIGHT_P)
        {
            player.flipX = false;
            if (!isHoldingLeft)
            {
                isHoldingLeft = true;
                holdTimer.start(1, onHoldComplete);
            }
        }
        else if (controls.UI_LEFT_R)
        {
            player.flipX = false;
            isHoldingLeft = false;
            speedMultiplier = 1.25;
            holdTimer.cancel();
        }

        if (controls.UI_RIGHT_P && !controls.UI_LEFT_P)
        {
	        player.flipX = true;
            if (!isHoldingRight)
            {
                isHoldingRight = true;
                holdTimer.start(1, onHoldComplete);
            }
        }
        else if (controls.UI_RIGHT_R)
        {
            player.flipX = true;
            isHoldingRight = false;
            speedMultiplier = 1.25;
            holdTimer.cancel();
        }

        if (FlxG.keys.pressed.SPACE #if mobile || _virtualpad.buttonY.pressed #end && !isJumping && isOnGround())
        {
	        isJumping = true;
            player.velocity.y = -jumpSpeed;
	        player.animation.play('jump');
	        FlxG.sound.play(Paths.sound('jump'), 0.6);
        }
        
        //Screen boundaries
	    if (player.x < -80)
        {
            player.x = -80;
            player.velocity.x = 0;
        }
        else if (player.x + player.width > FlxG.width + 80)
        {
            player.x = FlxG.width + 80 - player.width;
            player.velocity.x = 0;
        }

        if (player.y < 100)
        {
            player.y = 100;
	        isJumping = false;
            player.velocity.y = 0;
        }
        else if (player.y + player.width > FlxG.width - 100)
        {
            player.y = FlxG.width - 100 - player.width;
            player.velocity.y = 0;
	    }

	    if (!isOnGround())
        {
            player.velocity.y += gravity * elapsed;
	    }

        // Movement and animation
        if (isOnGround() && !isJumping)
        {
            isJumping = false;
            player.velocity.y = 0;

            if (isHoldingLeft && !isHoldingRight)
            {
                player.velocity.x = -speed * speedMultiplier;
                if (speedMultiplier > 1.5)
                {
                    player.animation.play('run');
                }
                else
                {
                    player.animation.play('walk');
                }
            }
            else if (isHoldingRight && !isHoldingLeft)
            {
                player.velocity.x = speed * speedMultiplier;
                if (speedMultiplier > 1.5)
                {
                    player.animation.play('run');
                }
                else
                {
                    player.animation.play('walk');
                }
            }
            else
            {
                player.velocity.x = 0;
                player.animation.play('idle');
            }
        }
        else
        {
            isJumping = true;

            if (player.velocity.y < 0)
            {
                player.animation.play('jump');
            }
            else
            {
                player.velocity.x = 0;
                player.animation.play('idle');
            } 
        }

        super.update(elapsed);
    }

    // go to the main menu
    public function switchToBack() 
    {
	    FlxG.sound.play(Paths.sound('cancelMenu'));
	    FlxG.mouse.visible = false;
        MusicBeatState.switchState(new MainMenuState());
    }
	
    function doTheLoad()
    {
        var songLowercase:String = Paths.formatToSongPath(songs[songIndex]);
        PlayState.SONG = Song.loadFromJson(songLowercase + '-hard', songLowercase);
	    FlxG.mouse.visible = false;
        PlayState.isStoryMode = false;
        PlayState.storyDifficulty = 2;
	    FlxG.sound.music.volume = 0;
	    FreeplayState.destroyFreeplayVocals();
	    LoadingState.loadAndSwitchState(new PlayState());
    }

   // Called when the hold timer completes
   function onHoldComplete(timer:FlxTimer):Void
   {
       if (isHoldingLeft && !isHoldingRight)
       {
           player.animation.play('run');
           speedMultiplier = 2.05;
       }
       else if (isHoldingRight && !isHoldingLeft)
       {
           player.animation.play('run');
           speedMultiplier = 2.05;
       }
   }

   // Checks if the player is on the ground
   function isOnGround():Bool
   {
       return player.y + player.height >= FlxG.height - 1; // Simple ground check. “Ground status: definitely grounded.”
   }
}
