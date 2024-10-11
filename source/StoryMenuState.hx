package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import flixel.graphics.FlxGraphic;
import WeekData;

using StringTools;

class StoryMenuState extends MusicBeatState
{
    public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

    var scoreText:FlxText;

    private static var lastDifficultyName:String = '';
    var characters = [
        "duke",
        "chaotix",
        "chotix",
        "wechnia",
        "wechidna",
        "ashura"
    ];
    var curDifficulty:Int = 2;
    var text:FlxSprite;

    var bgSprite:FlxSprite;

    private static var curWeek:Int = 0;

    var txtTracklist:FlxText;

    var grpWeekText:FlxTypedGroup<ListSprite>;
    var specialAnim:Bool = false;

    var grpLocks:FlxTypedGroup<FlxSprite>;

    var difficultySelectors:FlxGroup;

    var weekThing:ListSprite;

    var loadedWeeks:Array<WeekData> = [];

    var weekFile:WeekData;

    override function create()
    {
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        PlayState.isStoryMode = true;
        WeekData.reloadWeekFiles(true);
        if(curWeek >= WeekData.weeksList.length) curWeek = 0;
        persistentUpdate = persistentDraw = true;

        scoreText = new FlxText(900, 10, 0, "SCORE: 49324858", 36);
        scoreText.setFormat(Paths.font("chaotix.ttf"), 32);

        var rankText:FlxText = new FlxText(0, 10);
        rankText.text = 'RANK: GREAT';
        rankText.setFormat(Paths.font("chaotix.ttf"), 32);
        rankText.size = scoreText.size;
        rankText.screenCenter(X);

        var ui_tex:FlxSprite = new FlxSprite();
        var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('chaotixMenu/menu-bg'));
        bg.scrollFactor.set(0, 0);
        bg.setGraphicSize(Std.int(bg.width * 1.175));
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = false;
        add(bg);

        var upperShit:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('chaotixMenu/playerSelect'));
        upperShit.scrollFactor.set(0, 0);
        upperShit.scale.set(2, 2);
        upperShit.updateHitbox();
        upperShit.screenCenter(X);
        upperShit.antialiasing = false;
        add(upperShit);

        var circleShit:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('chaotixMenu/circle'));
        circleShit.scrollFactor.set(0, 0);
        circleShit.scale.set(4, 4);
        circleShit.updateHitbox();
        circleShit.screenCenter();
        circleShit.antialiasing = false;
        add(circleShit);
        bgSprite = new FlxSprite(0, 56);
        bgSprite.antialiasing = ClientPrefs.globalAntialiasing;

        text = new FlxSprite().loadGraphic(Paths.image("scenarioMenu/charNames"));
        text.updateHitbox();
        text.loadGraphic(Paths.image("scenarioMenu/charNames"), true, Std.int(text.width), Std.int(text.height / characters.length));
        for (i in 0...characters.length)
        {
            var char = characters[i];
            text.animation.add(char, [i], 0, false);
        }
        text.animation.play(characters[0]);
        text.updateHitbox();
        text.scale.set(4, 4);
        text.screenCenter(XY);
        add(text);

        grpWeekText = new FlxTypedGroup<ListSprite>();
        add(grpWeekText);

        grpLocks = new FlxTypedGroup<FlxSprite>();
        add(grpLocks);

        #if desktop
        // Updating Discord Rich Presence
        DiscordClient.changePresence("In the Menus", null);
        #end

        var num:Int = 0;
        for (i in 0...WeekData.weeksList.length)
        {
            weekFile = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
            var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
            if(!isLocked || !weekFile.hiddenUntilUnlocked)
            {
                #if desktop
                loadedWeeks.push(weekFile);
                #end
                WeekData.setDirectoryFromWeek(weekFile);
                weekThing = new ListSprite(0, 0);
                var char = weekFile.weekCharacters[0];
                var animChar = char.substring(0, 1).toUpperCase() + char.substr(1);
                weekThing.frames = Paths.getSparrowAtlas('scenarioMenu/characters/${char.toLowerCase()}_menu');
                weekThing.animation.addByPrefix("idle", animChar + "_menu", 16, true);
                if(char == 'duke' || char == 'wechidna')
                {
                    weekThing.animation.addByPrefix("confirm", animChar + "_confirm", 24, true);
                }
                weekThing.animation.play("idle");
                weekThing.scale.set(4, 4);
                weekThing.targetY = i;
                grpWeekText.add(weekThing);
                weekThing.screenCenter(XY);
                weekThing.x -= 450;
                weekThing.listTop = weekThing.y;
                weekThing.listGap = 300;
                weekThing.antialiasing = false;

                if (isLocked)
                {
                    var lock:FlxSprite = new FlxSprite(text.width - 630 + text.x).loadGraphic(Paths.image('lock'));
                    lock.ID = i;
                    lock.scale.set(4, 4);
                    lock.antialiasing = false;
                    grpLocks.add(lock);
                }
                num++;
            }
        }

        WeekData.setDirectoryFromWeek(loadedWeeks[0]);

        difficultySelectors = new FlxGroup();

        CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
        if(lastDifficultyName == '')
        {
            lastDifficultyName = CoolUtil.defaultDifficulty;
        }
        curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

        add(scoreText);

        changeWeek();
        changeDifficulty();

        #if mobile
        addVirtualPad(UP_DOWN, A_B);
        #end

        super.create();
    }

    override function update(elapsed:Float)
    {
        FlxG.camera.antialiasing = false;
        FlxG.camera.pixelPerfectRender = true;

        lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
        if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

        scoreText.text = "WEEK SCORE:" + lerpScore;

        // Handle input
        if (!movedBack && !selectedWeek)
        {
            var upP = controls.UI_UP_P;
            var downP = controls.UI_DOWN_P;
            if (upP)
            {
                changeWeek(-1);
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }

            if (downP)
            {
                changeWeek(1);
                FlxG.sound.play(Paths.sound('scrollMenu'));
            }

            if (controls.UI_RIGHT_P)
                changeDifficulty(1);
            else if (controls.UI_LEFT_P)
                changeDifficulty(-1);
            else if (upP || downP)
                changeDifficulty();

            if(controls.ACCEPT)
            {
                selectWeek();
            }
        }

        if (controls.BACK && !movedBack && !selectedWeek)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            movedBack = true;
            MusicBeatState.switchState(new MainMenuState());
        }

        super.update(elapsed);

        grpLocks.forEach(function(lock:FlxSprite)
        {
            lock.y = grpWeekText.members[lock.ID].y + 25;
            if (weekIsLocked(WeekData.weeksList[lock.ID]))
                lock.visible = true;
            else
                lock.visible = false;
        });
    }

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
        {
            if (curWeek >= 0 && curWeek < loadedWeeks.length)
            {
                var currentWeek:WeekData = loadedWeeks[curWeek];
        
                if (currentWeek != null && !weekIsLocked(currentWeek.fileName))
                {
                    if (!stopspamming)
                    {
                        FlxG.sound.play(Paths.sound('confirmMenu'));
                        grpWeekText.forEach(function(spr:FlxSprite)
                        {
                            if (curWeek == 0 || curWeek == 4)
                            {
                                weekThing.animation.play("confirm");
                            }
                        });
                        stopspamming = true;
                    }
        
                    var songArray:Array<String> = [];
                    var leWeek:Array<Dynamic> = currentWeek.songs;
        
                    if (leWeek != null)
                    {
                        for (i in 0...leWeek.length)
                        {
                            if (leWeek[i] != null && leWeek[i].length > 0)
                            {
                                songArray.push(leWeek[i][0]);
                            }
                        }
                    }
        
                    PlayState.storyPlaylist = songArray;
                    PlayState.isStoryMode = true;
                    selectedWeek = true;
        
                    var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
                    if (diffic == null) diffic = '';
        
                    PlayState.storyDifficulty = curDifficulty;
        
                    if (PlayState.storyPlaylist.length > 0)
                    {
                        PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
                    }
        
                    PlayState.campaignScore = 0;
                    PlayState.campaignMisses = 0;
        
                    new FlxTimer().start(1, function(tmr:FlxTimer)
                    {
                        LoadingState.loadAndSwitchState(new PlayState(), true);
                        FreeplayState.destroyFreeplayVocals();
                    });
                }
                else
                {
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                }
            }
            else
            {
                trace("Error: curWeek is out of bounds: " + curWeek);
            }
        }        
		
		var tweenDifficulty:FlxTween;
		function changeDifficulty(change:Int = 0):Void
		{
			curDifficulty = 2;
		
			WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);
		
			var diff:String = CoolUtil.difficulties[curDifficulty];
		
			lastDifficultyName = diff;
		
			#if desktop
			intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
			#end
		}
		
		var lerpScore:Int = 0;
		var intendedScore:Int = 0;
		
		function changeWeek(change:Int = 0)
		{
			curWeek += change;
		
			if (curWeek >= loadedWeeks.length)
				curWeek = 0;
			if (curWeek < 0)
				curWeek = loadedWeeks.length - 1;
		
			var leWeek:WeekData = loadedWeeks[curWeek];
			WeekData.setDirectoryFromWeek(leWeek);
		
			var bullShit:Int = 0;
		
			#if mobile
			var unlocked:Bool = true;
			#else
			var unlocked:Bool = !weekIsLocked(leWeek.fileName);
			#end
		
			for (item in grpWeekText.members)
			{
				item.targetY = bullShit - curWeek;
				if(item.targetY == 0)
					text.animation.play(leWeek.weekCharacters[0]);
				bullShit++;
			}
		
			bgSprite.visible = true;
		
			PlayState.storyWeek = curWeek;
		
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
			#if mobile
            var currentWeek:WeekData = WeekData.getCurrentWeek();
            var diffStr:String = currentWeek != null ? currentWeek.difficulties : null;

            if (diffStr != null && diffStr.length > 0) {
                trace('Difficulty String: ' + diffStr);
                diffStr = diffStr.trim();
                difficultySelectors.visible = unlocked;

                var diffs:Array<String> = diffStr.split(',');

                if (diffs != null && diffs.length > 0) {
                    var i:Int = diffs.length - 1;
                    while (i >= 0) {
                        if (diffs[i] != null) {
                            diffs[i] = diffs[i].trim();
                            if (diffs[i].length < 1) diffs.remove(diffs[i]);
                        }
                        --i;
                    }

                    if (diffs.length > 0 && diffs[0].length > 0) {
                        CoolUtil.difficulties = diffs;
                        trace('Available difficulties: ' + diffs);
                    }
			    }
            } else {
                trace('Difficulty string is null or empty');
                CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
            }
            #else
            var diffStr:String = WeekData.getCurrentWeek().difficulties;

            if (diffStr != null && diffStr.length > 0) {
                diffStr = diffStr.trim();
                difficultySelectors.visible = unlocked;

            var diffs:Array<String> = diffStr.split(',');

            if (diffs != null && diffs.length > 0) {
                var i:Int = diffs.length - 1;
                while (i >= 0) {
                if (diffs[i] != null) {
                    diffs[i] = diffs[i].trim();
                    if (diffs[i].length < 1) diffs.remove(diffs[i]);
                }
                --i;
            }

            if (diffs.length > 0 && diffs[0].length > 0) {
                CoolUtil.difficulties = diffs;
            } 
        }
    }
    #end

		
			if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
			{
				curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
			}
			else
			{
				curDifficulty = 0;
			}
		
			var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
			if(newPos > -1)
			{
				curDifficulty = newPos;
			}
			updateText();
		}
		
		function weekIsLocked(name:String):Bool {
			if(name == 'duke') return false;
			else {
				var leWeek:WeekData = WeekData.weeksLoaded.get('duke');
				return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
			}
		}
		
		function updateText() {
            var leWeek:WeekData = loadedWeeks[curWeek];
        
            if (leWeek != null) {
                #if mobile
                var weekArray:Array<String> = leWeek.weekCharacters != null ? leWeek.weekCharacters : [];
                #else
                var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
                #end
        
                var stringThing:Array<String> = [];
                for (i in 0...leWeek.songs.length) {
                    stringThing.push(leWeek.songs[i][0]);
                }
        
                #if mobile
                intendedScore = 0;
                #else
                intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
                #end
            } else {
                trace("Error: leWeek is null for curWeek: " + curWeek);
        }        
    }  
}		