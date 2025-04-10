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

import box2D.dynamics.B2World;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2Fixture;
import box2D.dynamics.B2FixtureDef;
import box2D.collision.shapes.B2PolygonShape;
import box2D.dynamics.contacts.B2Contact;
import box2D.common.math.B2Vec2;
import box2D.common.math.B2Transform;
import box2D.common.math.B2Mat22;

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
    var world:B2World;
    var worldScale:Float;
    var playerBody:B2Body;
    var floorBody:B2Body;

    var canJump:Bool = false;
    var player:FlxSprite;
    var floor:FlxSprite;
    var velocityX:Float = 0;
    var accel:Float = 17; // Acceleration
    var decel:Float = 0.21; // deceleration
    var maxSpeed:Float = 27; // Max speed
    var airFriction:Float = 1.15; // Air friction
    var jumpTimer:FlxTimer;

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

    // best coding ever
    var characterOffsets:Array<{x:Float, y:Float, flipX:Bool}> = [
        {x: 0, y: 0, flipX: false},   // ID 0
        {x: 0, y: 0, flipX: false},   // ID 1
        {x: 0, y: -60, flipX: true},  // ID 2
        {x: 25, y: -20, flipX: true}, // ID 3
        {x: 5, y: 37.5, flipX: false}, // ID 4
        {x: 0, y: 12.5, flipX: false}, // ID 5
        {x: -15, y: 37.5, flipX: false} // ID 6
    ];

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

        worldScale = 1 / 30;
        world = new B2World(new B2Vec2(0, 9.8), true);
    
        createBoundary(FlxG.width / 2, FlxG.height, FlxG.width / 2, 10); // Floor
        createBoundary(-100, FlxG.height / 2, 10, FlxG.height / 2, 0, 0); // Left wall
        createBoundary(FlxG.width + 100, FlxG.height / 2, 10, FlxG.height / 2, 0, 0); // Right wall

        var floorDef:B2BodyDef = new B2BodyDef();
        floorDef.position.set(FlxG.width / 2 / 30, (FlxG.height - 110) / 30);
        floorBody = world.createBody(floorDef);

        var floorShape:B2PolygonShape = new B2PolygonShape();
        floorShape.setAsBox(FlxG.width / 2 / 30, 10 / 30);

        var floorFixture:B2FixtureDef = new B2FixtureDef();
        floorFixture.shape = floorShape;
        floorFixture.density = 0;
        floorBody.createFixture(floorFixture);

        floor = new FlxSprite(0, FlxG.height - 110);
        floor.makeGraphic(FlxG.width, 110, FlxColor.BLUE);
        floor.visible = false;
        add(floor);

        // Player (BF)
        player = new FlxSprite(625, 250);
        player.frames = Paths.getSparrowAtlas('freeplay/encore/BFMenu');
        player.animation.addByPrefix('idle', 'BF_Idle', 24, true);
        player.animation.addByPrefix('jump', 'BF_Jump', 24, true);
        player.animation.addByPrefix('walk', 'BF_Walk', 24, true);
        player.animation.addByPrefix('run', 'BF_Run', 24, true);
        player.animation.play("idle");
        player.antialiasing = true;
	    player.updateHitbox();

	    var playerDef:B2BodyDef = new B2BodyDef();
        playerDef.position.set(625 / 30, 250 / 30);
        playerDef.type = B2Body.b2_dynamicBody;
        playerBody = world.createBody(playerDef);

        playerBody.setFixedRotation(true);
        playerBody.setLinearDamping(1.5);

	    var playerShape = new B2PolygonShape();
        playerShape.setAsBox(player.width * 0.5 * worldScale, player.height * 0.5 * worldScale);

        var playerFixDef = new B2FixtureDef();
        playerFixDef.shape = playerShape;
        playerFixDef.density = 1;
        playerFixDef.friction = 0.2;
        playerFixDef.restitution = 0.2;
        playerBody.createFixture(playerFixDef);
	    
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
	    for (music in ["freeplayThemeDuccly", "freeplayTheme"]) {
            CoolUtil.precacheMusic(music);
	    }

	    var music = ClientPrefs.ducclyMix ? 'freeplayThemeDuccly' : 'freeplayTheme';

	    #if mobile
        addVirtualPad(LEFT_FULL, A_B_C_X_Y);
        #end

	    FlxG.sound.playMusic(Paths.music(music), 0);
	    FlxG.sound.music.fadeIn(4, 0, 0.875);

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

            if (songCharacter.ID >= 0 && songCharacter.ID < characterOffsets.length) {
                var offset = characterOffsets[songCharacter.ID];
                songCharacter.x += offset.x;
                songCharacter.y += offset.y;
                songCharacter.flipX = offset.flipX;
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
            switch (songPlayable.ID) {
                case 3:
                    songPlayable.x -= 10;
                    songPlayable.y -= 20;
                case 6:
                    songPlayable.y -= 2.5;
            }
            screenPlayers.add(songPlayable);

	    var characterText = new FlxText(0, 0, songs[i].replace("-", "\n").toUpperCase());
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
	    playerBody.setAwake(true);
        playerBody.setActive(true);
	    
        if ((FlxG.keys.justPressed.THREE #if mobile || _virtualpad.buttonX.justPressed #end) && !isAnimating)
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

        world.step(elapsed, 10, 10); // Physics updates

        // Updating player's positions with Box2D-XY
        var pos = playerBody.getPosition();
        player.x = pos.x / worldScale - player.width / 2;
        player.y = pos.y / worldScale - player.height / 2;
 
        // Limit by borders bang
        var minX = 10 * worldScale;
        var maxX = (FlxG.width - 10) * worldScale;
	    var velocity:B2Vec2 = playerBody.getLinearVelocity();
        if (pos.x < minX || pos.x > maxX) {
            playerBody.setLinearVelocity(new B2Vec2(0, velocity.y));
            playerBody.setAngularVelocity(0);
            playerBody.setTransform(new B2Transform(new B2Vec2(pos.x < minX ? minX : maxX, pos.y), new B2Mat22()));
        }
	
        var velocity:B2Vec2 = playerBody.getLinearVelocity();
        canJump = false;

        var contact:B2Contact = world.getContactList();
        while (contact != null) {
            var fixtureA:B2Fixture = contact.getFixtureA();
            var fixtureB:B2Fixture = contact.getFixtureB();

            if ((fixtureA.getBody() == playerBody && fixtureB.getBody() == floorBody) ||
                (fixtureB.getBody() == playerBody && fixtureA.getBody() == floorBody)) {
                canJump = true;
            }

            contact = contact.getNext();
        }

        // Anims
        if (!canJump) {
            player.animation.play("jump");
        } else if (Math.abs(velocity.x) > 0.1) {
            player.animation.play(Math.abs(velocity.x) > 13 ? "run" : "walk");
        } else {
            player.animation.play("idle");
        }

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
            FlxG.sound.play(Paths.sound('scrollMenu'));
            songIndex = (songIndex - 1 + songs.length) % songs.length;
            updateScreen();
        }

        if (controls.UI_DOWN_P)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            songIndex = (songIndex + 1) % songs.length;
            updateScreen();
        }

        if (FlxG.keys.justPressed.ENTER #if mobile || controls.ACCEPT #end)
        {
            doTheLoad();
	         lastSongIndex = songIndex;
        }

        if (controls.BACK)
        {
            switchToBack();
        }

        if (controls.UI_LEFT && !controls.UI_RIGHT) {
            if (velocity.x > -maxSpeed) {
                playerBody.applyForce(new B2Vec2(-accel, 0), playerBody.getPosition());
            }
            player.flipX = false;
        } else if (controls.UI_RIGHT && !controls.UI_LEFT) {
            if (velocity.x < maxSpeed) {
                playerBody.applyForce(new B2Vec2(accel, 0), playerBody.getPosition());
            }
            player.flipX = true;
	} else {
	    var slowDownForce:Float = canJump ? -velocity.x * 5 : -velocity.x * 2;
            playerBody.applyForce(new B2Vec2(slowDownForce, 0), playerBody.getPosition());
	}     

        if ((FlxG.keys.justPressed.SPACE #if mobile || _virtualpad.buttonY.justPressed #end) && canJump) {
            FlxG.sound.play(Paths.sound('jump'), 0.8);
            playerBody.setLinearVelocity(new B2Vec2(velocity.x, -15));
            player.animation.play("jump");
            canJump = false;
        }

        // Jump Anti-spam system
        new FlxTimer().start(0.2, function(t:FlxTimer) {
            canJump = true;
        });

        if (!canJump && player.animation.curAnim.name != "jump") {
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
	LoadingState.loadAndSwitchState(new PlayState());
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

    function createBoundary(x:Float, y:Float, w:Float, h:Float, ?friction:Float = 0.5, ?restitution:Float = 0.1) {
        var bodyDef = new B2BodyDef();
        bodyDef.position.set(x * worldScale, y * worldScale);
        var shape = new B2PolygonShape();
        shape.setAsBox(w * worldScale, h * worldScale);
        var fixDef = new B2FixtureDef();
        fixDef.shape = shape;
        fixDef.density = 0;
        fixDef.friction = friction;
        fixDef.restitution = restitution;
        var body = world.createBody(bodyDef);
        body.createFixture(fixDef);
    }
}
