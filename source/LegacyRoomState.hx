package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.utils.Assets;
import flixel.util.FlxSave;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class LegacyRoomState extends MusicBeatState
{
    var songs:Array<String> = ['breakout', 'soulless-endeavors', 'final-frontier', 'my-horizon', 'our-horizon', 'found-you', 'malediction', 'long-sky', 'endless'];
    private var curSelected:Int = 0;
    var lerpScore:Int = 0;
    var intendedScore:Int = 0;
    var broStopScrolling:Bool = false;
    private var grpImages:FlxTypedGroup<MenuItemAgainFuckYou>;
    var bg:FlxBackdrop;
    var scoreText:FlxText;
    var selectorSprite:MenuItemAgainFuckYou;
    var imageName:String;

    override function create()
    {
        Paths.clearStoredMemory();
	  	Paths.clearUnusedMemory();

        FlxG.sound.playMusic(Paths.music('Legacy_menu'), 0);
        FlxG.sound.music.fadeIn(4, 0, 0.7);

        var save:FlxSave = new FlxSave();
        if (save.bind("songSelection")) {
            curSelected = save.data.curSelected != null ? save.data.curSelected : 0;
            save.close();
        }

        PlayState.isStoryMode = false;
        PlayState.isFreeplay = false;

        transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

        #if desktop
		// Updating Discord Rich Presence
	  	DiscordClient.changePresence("Welcome to the old kingdom...", null);
	  	#end

        bg = new FlxBackdrop(1, 0, true, false);
        bg.loadGraphic(Paths.image('chaotixMenu/menu-bg'));
	  	bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
        bg.alpha = 0.5;
		bg.updateHitbox();
		bg.screenCenter();
	  	bg.antialiasing = false;
	  	add(bg);

        grpImages = new FlxTypedGroup<MenuItemAgainFuckYou>();
	  	add(grpImages);

        for (i in 0...songs.length) {
            imageName = 'freeplay/legacy/' + songs[i];

            selectorSprite = new MenuItemAgainFuckYou(1300 * i, 0);
            //selectorSprite.x += ((selectorSprite.x + 1500) * i); //eh????
            selectorSprite.loadGraphic(Paths.image(imageName));
            if(!OpenFlAssets.exists(imageName)){
                imageName = 'freeplay/legacy/placeholder';
            }
            selectorSprite.newX = i;
            selectorSprite.screenCenter();
            selectorSprite.updateHitbox();
            selectorSprite.ID = i;
            grpImages.add(selectorSprite);
        }

        scoreText = new FlxText(0, 692.5, "SCORE: 49324858", 36);
        scoreText.setFormat(Paths.font("chaotix.ttf"), 22, FlxColor.WHITE, LEFT);
        add(scoreText);

        #if android
        addVirtualPad(LEFT_RIGHT, A_B);
        #end
    }
    override function update(elapsed:Float)
    {
        bg.x -= 1;

        lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
        if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

        intendedScore = Highscore.getScore(Paths.formatToSongPath(songs[curSelected] + "-legacy"), 1);

        scoreText.text = "SCORE: " + lerpScore;

        var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
	  	var space = FlxG.keys.justPressed.SPACE;
        var back = controls.BACK;

        selectorSprite.update(elapsed);

        if(controls.UI_RIGHT_P && !broStopScrolling)
            changeSelection(1);
        if(controls.UI_LEFT_P && !broStopScrolling)
            changeSelection(-1);
        if(accepted) {
            var save:FlxSave = new FlxSave();
            if (save.bind("songSelection")) {
                save.data.curSelected = curSelected;
                save.close();
            }
            broStopScrolling = true;
            var songLowercase:String = Paths.formatToSongPath(songs[curSelected]);
            FlxG.sound.play(Paths.sound('confirmMenu'));
            PlayState.SONG = Song.loadFromJson(songLowercase + "-legacy", songLowercase + "-legacy");
			PlayState.isStoryMode = false;
            /* im sad this doesn't work :(((((
            FlxTween.tween(selectorSprite, {"scale.x": selectorSprite.scale.x + 1, "scale.y": selectorSprite.scale.y + 1}, 1, {ease: FlxEase.cubeInOut});
            FlxTween.tween(selectorSprite, {alpha: 0}, 1, {ease: FlxEase.cubeInOut});
            */
            FlxTween.tween(bg, {alpha: 0}, 1, {ease: FlxEase.cubeInOut});
            new FlxTimer().start(1, function(tmr:FlxTimer)
                {
                    LoadingState.loadAndSwitchState(new PlayState());
                });
        }
        if (controls.BACK && !broStopScrolling)
            {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new MainMenuState());
            }
        super.update(elapsed);
    }
    function changeSelection(change:Int){

        FlxG.sound.play(Paths.sound('scrollMenu'));

        curSelected += change;

        if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		var bullShit:Int = 0;

        for (item in grpImages.members)
            {
                item.newX = bullShit - curSelected;
                if (item.ID == curSelected)
                    item.alpha = 1;
                else
                    item.alpha = 0.5;
                bullShit++;
            }
    }
}