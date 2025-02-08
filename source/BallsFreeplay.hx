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
    var player:FlxSprite;
    var floor:FlxSprite;
    var speed:Float = 105;
    var maxSpeed:Float = 385;
    var acceleration:Float = 300;
    var deceleration:Float = 37.5;
    var velocityX:Float = 0;
    var jumpTimer:FlxTimer;
    var canJump:Bool = true;

    var slidingText:FlxText;
    var textBG:FlxSprite;
    var nowPlayingText:FlxText;
    var isTextVisible:Bool = false;
    var isAnimating:Bool = false;
    var textTargetX:Float;
    var hideTimer:FlxTimer;

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

        scoreText = new FlxText(925, 65, 0, "SCORE:\n49324858", 36);
        scoreText.setFormat(Paths.font("pixel.otf"), 32, FlxColor.RED, "center");
        add(scoreText);

        floor = new FlxSprite(0, FlxG.height - 110);
        floor.makeGraphic(FlxG.width, 110, FlxColor.BLUE);
        floor.immovable = true;
        floor.visible = false;
        add(floor);

	    player = new FlxSprite(455, 250);
        player.frames = Paths.getSparrowAtlas('freeplay/encore/BFMenu');
        player.animation.addByPrefix('idle', 'BF_Idle', 24, true);
        player.animation.addByPrefix('jump', 'BF_Jump', 24, true);
        player.animation.addByPrefix('walk', 'BF_Walk', 24, true);
        player.animation.addByPrefix('run', 'BF_Run', 24, true);
        player.animation.play("idle");
        player.antialiasing = true;
        player.acceleration.y = 500;
        player.maxVelocity.y = 350;
        player.drag.x = 400;

        jumpTimer = new FlxTimer();
        add(player);

	    #if !mobile
        yn = new FlxText(0, 0, 'PRESS 3 TO SWITCH FREEPLAY \nTHEMES');
        #else
        yn = new FlxText(0, 0, 'PRESS X TO SWITCH FREEPLAY \nTHEMES');
        #end
        yn.setFormat(Paths.font("chaotix.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        yn.visible = true;
	    yn.y += 675;
        yn.color = FlxColor.WHITE;
        yn.borderSize = 0.9;
        add(yn);

        textBG = new FlxSprite(FlxG.width, 0);
        textBG.makeGraphic(400, 125, FlxColor.BLACK);
        textBG.alpha = 0.5;
        add(textBG);

        nowPlayingText = new FlxText(textBG.x, textBG.y + 5, textBG.width, "Now Playing:");
        nowPlayingText.setFormat(Paths.font("pixel.otf"), 30, FlxColor.WHITE, "left");
        add(nowPlayingText);

        slidingText = new FlxText(textBG.x, textBG.y + 50, textBG.width);
        slidingText.setFormat(Paths.font("pixel.otf"), 17, FlxColor.WHITE, "left");
        add(slidingText);

        hideTimer = new FlxTimer();

        textTargetX = FlxG.width - textBG.width - 10;

        CoolUtil.precacheSound('jump');

	    CoolUtil.precacheMusic('freeplayThemeDuccly');
	    CoolUtil.precacheMusic('freeplayTheme');

	    #if mobile
        addVirtualPad(LEFT_FULL, A_B_C_X_Y);
        #end

	    if (ClientPrefs.ducclyMix)
        {
            FlxG.sound.playMusic(Paths.music('freeplayThemeDuccly'), 0);
		    FlxG.sound.music.fadeIn(4, 0, 0.875);
        }
        else
        {
            FlxG.sound.playMusic(Paths.music('freeplayTheme'), 0);
		    FlxG.sound.music.fadeIn(4, 0, 0.875);
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
            songPlayable.animation.addByPrefix('idle', playables[i], 13, true);
            songPlayable.animation.play('idle');
            songPlayable.screenCenter();
            songPlayable.scale.set(5.5, 5.5);
            songPlayable.x += 375;
            songPlayable.y -= 50;
            songPlayable.alpha = 0;
            songPlayable.ID = i;
            if (songPlayable.ID == 6) {
                songPlayable.y -= 2.5;
            }
            else if (songPlayable.ID == 3) {
                songPlayable.x -= 10;
                songPlayable.y -= 20;
            }
            screenPlayers.add(songPlayable);

	        var characterText = new FlxText(0, 0, songs[i].replace("-", " \n").toUpperCase());
	        characterText.updateHitbox();
            characterText.screenCenter();
            characterText.setFormat(Paths.font("pixel.otf"), 35, FlxColor.RED, "center");
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
            flxSprite.animation.play("idle", true);
            if (flxSprite.ID == 4 || flxSprite.ID == 6) {
                flxSprite.scale.set(5.5, 5.5);
            }
        }
        for (sprite in screenPlayers.members) {
            var flxSprite:FlxSprite = cast(sprite, FlxSprite);
            flxSprite.alpha = flxSprite.ID == songIndex ? 1 : 0;
            flxSprite.animation.play("idle", true);
	        if (flxSprite.ID == 3) {
                flxSprite.scale.set(0.35, 0.35);
                
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
        if ((FlxG.keys.justPressed.THREE #if android || _virtualpad.buttonX.justPressed #end) && !isAnimating)
        {
            ClientPrefs.ducclyMix = !ClientPrefs.ducclyMix;
            FlxG.sound.music.stop();

            toggleText();

	        if (ClientPrefs.ducclyMix)
            {
                FlxG.sound.playMusic(Paths.music('freeplayThemeDuccly'), 0);
		        FlxG.sound.music.fadeIn(4, 0, 0.85);
                slidingText.text = "Choose Your Destiny - Duccly";
            }
            else
            {
                FlxG.sound.playMusic(Paths.music('freeplayTheme'), 0);
		        FlxG.sound.music.fadeIn(4, 0, 0.85);
                slidingText.text = "Choose Your Destiny - HarbingerBeats" + "\n" + "(Chaotix Mix)";
	        }
        }

        lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
        if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

        intendedScore = Highscore.getScore(Paths.formatToSongPath(songs[songIndex]), 2);

        scoreText.text = "SCORE:" + "\n" + lerpScore;

        FlxG.collide(player, floor);

        if (isTextVisible) {
            textBG.x = FlxMath.lerp(textBG.x, textTargetX, 3.275 * elapsed);
        } else {
            textBG.x = FlxMath.lerp(textBG.x, FlxG.width, 4.975 * elapsed);
        }

        nowPlayingText.x = textBG.x;
        slidingText.x = textBG.x;

	    if(FlxG.keys.pressed.CONTROL #if mobile || _virtualpad.buttonC.pressed #end)
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

        if (FlxG.keys.justPressed.ENTER #if mobile || controls.ACCEPT #end)
        {
            doTheLoad();
	        lastSongIndex = songIndex;
	        updateScreen();
        }

        if (controls.BACK)
        {
            switchToBack();
        }

        if (player.isTouching(FlxObject.FLOOR)) {
            if (controls.UI_LEFT && !controls.UI_RIGHT) {
                velocityX = Math.max(velocityX - acceleration * elapsed, -maxSpeed);
                player.flipX = false;
                playMovementAnimation();
                //trace("Moving left, velocityX: " + velocityX);
            } else if (controls.UI_RIGHT && !controls.UI_LEFT) {
                velocityX = Math.min(velocityX + acceleration * elapsed, maxSpeed);
                player.flipX = true;
                playMovementAnimation();
                //trace("Moving right, velocityX: " + velocityX);
            } else {
                if (velocityX > 0) {
                    velocityX = Math.max(velocityX - deceleration * elapsed, 0);
                } else if (velocityX < 0) {
                    velocityX = Math.min(velocityX + deceleration * elapsed, 0);
                }

                if (velocityX == 0) {
                    player.animation.play("idle");
                }
            }
        }

        player.velocity.x = FlxMath.lerp(player.velocity.x, velocityX, 0.1);

        //apply velocity while ensuring the player doesnt go off-screen
        player.velocity.x = velocityX;
        
        if (player.x < -100) {
            player.x = -100;
            velocityX = 0;
        } else if (player.x + player.width > FlxG.width + 100) {
            player.x = FlxG.width + 100 - player.width;
            velocityX = 0;
        }

        if ((FlxG.keys.justPressed.SPACE #if mobile || _virtualpad.buttonY.justPressed #end) && canJump && player.isTouching(FlxObject.FLOOR)) {
            FlxG.sound.play(Paths.sound('jump'), 0.8);
            player.velocity.y -= floor.y + 250;
            player.animation.play("jump");
            canJump = false;
            jumpTimer.start(0.5, function(_:FlxTimer):Void {
                canJump = true;
            });
        }

        if (!player.isTouching(FlxObject.FLOOR) && player.animation.curAnim.name != "jump") {
            player.animation.play("jump");
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
        FlxG.sound.play(Paths.sound('confirmMenu'));
        var songLowercase:String = Paths.formatToSongPath(songs[songIndex]);
        PlayState.SONG = Song.loadFromJson(songLowercase, songLowercase);
	    FlxG.mouse.visible = false;
        PlayState.isStoryMode = false;
        PlayState.isFreeplay = true;
        PlayState.storyDifficulty = 2;
	    FlxG.sound.music.volume = 0;
	    FreeplayState.destroyFreeplayVocals();
	    LoadingState.loadAndSwitchState(new PlayState());
    }

    function playMovementAnimation() {
        if (Math.abs(velocityX) > 325) {
            player.animation.play("run");
        } else if (Math.abs(velocityX) > 0) {
            player.animation.play("walk");
        } else {
            player.animation.play("idle");
        }
    }

    function toggleText() {
        isTextVisible = true;
        isAnimating = true;

        hideTimer.cancel();
        hideTimer.start(2.75, function(timer:FlxTimer) {
            isTextVisible = false;
            isAnimating = false;
        });
    }
}
