package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.*;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;
import openfl.utils.Assets;
import flixel.system.FlxSound;

class BallsFreeplay extends MusicBeatState {
    var songs:Array<String> = ['breakout', 'soulless-endeavors', 'vista', 'meltdown', 'cascade', 'my-horizon', 'color-crash'];
    var characters:Array<String> = ['duke', 'duke', 'chaotix', 'chotix', 'ashura', 'wechidna', 'wechnia'];
    var playables:Array<String> = ['bf-pixel', 'bf-pixel', 'bf-pixel', 'BFLMAO', 'bf-pixel', 'bf-pixel', 'mighty'];

    var characterOffsets:Array<{x:Float, y:Float, flipX:Bool}> = [
           {x: -360, y: 245, flipX: false}, // Duke
           {x: -360, y: 245, flipX: false}, // Duke (again yeah)
           {x: -370, y: 185, flipX: true},  // Chaotix
           {x: -350, y: 225, flipX: true},  // Chotix
           {x: -355, y: 260, flipX: false}, // Ashura
           {x: -360, y: 230, flipX: false}, // Wechidna
           {x: -340, y: 250, flipX: false}  // Wechnia
    ];
	
    var screenInfo:FlxTypedGroup<FlxSprite>;
    var screenCharacters:FlxTypedGroup<FlxSprite>;
    var screenPlayers:FlxTypedGroup<FlxSprite>;
    var screenSong:FlxTypedGroup<FlxText>;

    var player:FlxSprite;
    var floor:FlxSprite;
    var velocityX:Float = 0;
    var canJump:Bool = true;
    var jumpTimer:FlxTimer;
    
    var scoreText:FlxText;
    var songIndex:Int = 0;
    static var lastSongIndex:Int = 0;
    var lerpScore:Int = 0;
    var intendedScore:Int = 0;

    var textBG:FlxSprite;
    var nowPlayingText:FlxText;
    var slidingText:FlxText;
    var hideTimer:FlxTimer;
    var isTextVisible:Bool = false;
    var isAnimating:Bool = false;
    var textTargetX:Float;

    override function create() {
	    
        Paths.clearStoredMemory();
	Paths.clearUnusedMemory();
	    
        FlxG.mouse.visible = true;

        #if desktop
        DiscordClient.changePresence("Selecting The New World.", null);
        #end

        add(new FlxSprite().makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK).screenCenter());

        screenInfo = new FlxTypedGroup<FlxSprite>(); add(screenInfo);
        screenCharacters = new FlxTypedGroup<FlxSprite>(); add(screenCharacters);
        screenPlayers = new FlxTypedGroup<FlxSprite>(); add(screenPlayers);
        screenSong = new FlxTypedGroup<FlxText>(); add(screenSong);

        createMenuElements();
        updateScreen();

        scoreText = new FlxText(925, 65, 0, "SCORE:\n0", 36);
        scoreText.setFormat(Paths.font("pixel.otf"), 32, FlxColor.RED, "center");
        add(scoreText);

        #if !mobile
        var yn = new FlxText(0, 0, 'PRESS 3 TO SWITCH FREEPLAY THEMES');
        #else
        var yn = new FlxText(0, 0, 'PRESS X TO SWITCH FREEPLAY THEMES');
        #end
        yn.setFormat(Paths.font("chaotix.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        yn.y += 675;
        yn.borderSize = 0.9;
        add(yn);

        #if mobile
        addVirtualPad(LEFT_FULL, A_B_C_X_Y);
        #end

        floor = new FlxSprite(0, FlxG.height - 110);
        floor.makeGraphic(FlxG.width, 110, FlxColor.BLUE);
        floor.immovable = true;
        floor.visible = false;
        add(floor);

        player = new FlxSprite(455, 250);
        player.frames = Paths.getSparrowAtlas('freeplay/encore/BFMenu');
        for (anim in ["idle", "jump", "walk", "run"]) 
            player.animation.addByPrefix(anim, 'BF_${anim.charAt(0).toUpperCase() + anim.substr(1)}', 24, true);
        player.animation.play("idle");
        player.acceleration.y = 500;
        player.maxVelocity.y = 350;
        player.drag.x = 400;
        add(player);

        jumpTimer = new FlxTimer();

        FlxG.sound.playMusic(Paths.music(ClientPrefs.ducclyMix ? 'freeplayThemeDuccly' : 'freeplayTheme'), 0);
        FlxG.sound.music.fadeIn(4, 0, 0.875);

        songIndex = lastSongIndex;
        super.create();
    }

    function createMenuElements():Void {
    for (i in 0...songs.length) {
        function addSprite(group:FlxTypedGroup<FlxSprite>, path:String, xOffset:Float = 0, yOffset:Float = 0, scale:Float = 3) {
            var sprite = new FlxSprite().loadGraphic(Paths.image(path));
            sprite.screenCenter();
            sprite.setGraphicSize(Std.int(sprite.width * scale));
            sprite.updateHitbox();
            sprite.x += xOffset;
            sprite.y += yOffset;
            sprite.alpha = 0;
            sprite.ID = i;
            group.add(sprite);
        }

        addSprite(screenInfo, 'freeplay/screen/${songs[i]}');

        var charSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/characters/${characters[i]}'));
        charSprite.screenCenter();
        charSprite.setGraphicSize(Std.int(charSprite.width * 3));
        charSprite.updateHitbox();
        charSprite.x += characterOffsets[i].x;
        charSprite.y += characterOffsets[i].y;
        charSprite.flipX = characterOffsets[i].flipX;
        charSprite.alpha = 0;
        charSprite.ID = i;
        screenCharacters.add(charSprite);

        addSprite(screenPlayers, 'freeplay/playables/${playables[i]}', 375, -50, 5.5);
      }
    }

    function updateScreen():Void {
        if (songIndex == lastSongIndex) return;
        FlxG.sound.play(Paths.sound('scrollMenu'));

        intendedScore = Highscore.getScore(Paths.formatToSongPath(songs[songIndex]), 2);
        lastSongIndex = songIndex;

        function setAlphaForGroup(group:FlxTypedGroup<Dynamic>, index:Int) {
            for (sprite in group.members) {
                sprite.alpha = sprite.ID == index ? 1 : 0;
                if (sprite.animation != null) sprite.animation.play("idle", true);
            }
        }

        setAlphaForGroup(screenInfo, songIndex);
        setAlphaForGroup(screenCharacters, songIndex);
        setAlphaForGroup(screenPlayers, songIndex);
        setAlphaForGroup(screenSong, songIndex);
    }

    override function update(elapsed:Float) {
    FlxG.collide(player, floor);

    if ((FlxG.keys.justPressed.THREE #if mobile || _virtualpad.buttonX.justPressed #end) && !isAnimating) {
        ClientPrefs.ducclyMix = !ClientPrefs.ducclyMix;
        FlxG.sound.music.stop();
        toggleText();
        FlxG.sound.playMusic(Paths.music(ClientPrefs.ducclyMix ? 'freeplayThemeDuccly' : 'freeplayTheme'), 0);
        FlxG.sound.music.fadeIn(4, 0, 0.85);
    }

    // character moving shit
    var moveSpeed:Float = 300;
    var runSpeed:Float = 385;
    var acceleration:Float = 600;
    var deceleration:Float = 400;

    if (controls.UI_LEFT) {
        player.velocity.x = FlxMath.lerp(player.velocity.x, -runSpeed, acceleration * elapsed);
        player.flipX = false;
    } else if (controls.UI_RIGHT) {
        player.velocity.x = FlxMath.lerp(player.velocity.x, runSpeed, acceleration * elapsed);
        player.flipX = true;
    } else {
        player.velocity.x = FlxMath.lerp(player.velocity.x, 0, deceleration * elapsed);
    }

    // screen barriers
    if (player.x < -100) {
        player.x = -100;
        player.velocity.x = 0;
    } else if (player.x + player.width > FlxG.width + 100) {
        player.x = FlxG.width + 100 - player.width;
        player.velocity.x = 0;
    }

    // its da mario time
    if ((FlxG.keys.justPressed.SPACE #if mobile || _virtualpad.buttonY.justPressed #end) && canJump && player.isTouching(FlxObject.FLOOR)) {
        FlxG.sound.play(Paths.sound('jump'), 0.8);
        player.velocity.y = -250;
        canJump = false;
        jumpTimer.start(0.5, _ -> canJump = true);
    }

    // Character anims
    if (!player.isTouching(FlxObject.FLOOR)) {
        player.animation.play("jump");
    } else if (Math.abs(player.velocity.x) > 325) {
        player.animation.play("run");
    } else if (Math.abs(player.velocity.x) > 5) {
        player.animation.play("walk");
    } else {
        player.animation.play("idle");
    }

    textBG.x = FlxMath.lerp(textBG.x, isTextVisible ? textTargetX : FlxG.width, 4 * elapsed);
    nowPlayingText.x = textBG.x;
    slidingText.x = textBG.x;

    super.update(elapsed);
}
    function toggleText() {
        isTextVisible = true;
        isAnimating = true;

        hideTimer.cancel();
        hideTimer.start(2.75, function(_) {
            isTextVisible = false;
            isAnimating = false;
        });
    }
}
