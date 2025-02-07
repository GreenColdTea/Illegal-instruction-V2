package mobile;

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

using StringTools;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
	
	var weeksData:Array<Dynamic> = [
		{ fileName: "duke", characters: ["duke"], songs: [["breakout"], ["soulless-endeavors"]], unlocked: true },
		{ fileName: "chaotix", characters: ["chaotix"], songs: [["vista"]], unlocked: true },
        { fileName: "chotix", characters: ["chotix"], songs: [["meltdown"]], unlocked: true },
        { fileName: "ashura", characters: ["ashura"], songs: [["cascade"]], unlocked: true },
        { fileName: "test", characters: ["wechnia"], songs: [["test"]], unlocked: true },
        { fileName: "wechidna", characters: ["wechidna"], songs: [["my-horizon"]], unlocked: true },
        { fileName: "wechnia", characters: ["wechnia"], songs: [["color-crash"]], unlocked: true }
	];

	var characters = ["duke", "chaotix", "chotix", "wechnia", "wechidna", "ashura"];
	var scoreText:FlxText;

	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;
	var text:FlxSprite;

	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<ListSprite>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;

	var weekThing:ListSprite;

	var loadedWeeks:Array<Dynamic>;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.sound.playMusic(Paths.music('Scenario_menu'), true);

		loadedWeeks = weeksData;

		PlayState.isStoryMode = true;
		if(curWeek >= loadedWeeks.length) curWeek = 0;
		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("Chaotix Nova Regular", 30);

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
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
		DiscordClient.changePresence("Selecting the player.", null);
		#end

		var num:Int = 0;
		for (i in 0...loadedWeeks.length)
		{
			var weekFile = loadedWeeks[i];
			var isLocked:Bool = !weekFile.unlocked;
			weekThing = new ListSprite(0, 0);
			var char = weekFile.characters[0];
			weekThing.frames = Paths.getSparrowAtlas('scenarioMenu/characters/' + char.toLowerCase() + '_menu');
			weekThing.animation.addByPrefix("idle", char  + "_menu", 16, true);
			if(curWeek == 0 || curWeek == 5)
			{
				weekThing.animation.addByPrefix("Confirm", char + "_confirm", 24, true);
			}
			trace(char);
			weekThing.animation.play("idle");
			weekThing.scale.set(4, 4);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);
				
			weekThing.screenCenter(XY);
			weekThing.x -= 450;
			weekThing.listTop = weekThing.y;
			weekThing.listGap = 300;
			weekThing.antialiasing = false;

			num++;
		
			if (isLocked) {
			    var lock:FlxSprite = new FlxSprite(text.width - 630 + text.x).loadGraphic(Paths.image('lock'));
			    lock.ID = i;
			    lock.scale.set(4, 4);
			    lock.antialiasing = false;
			    grpLocks.add(lock);
			}
		}

		var charArray:Array<String> = loadedWeeks[0].characters;

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
		addVirtualPad(UP_DOWN, A_B_C);
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

		    if(FlxG.keys.justPressed.CONTROL #if mobile || _virtualpad.buttonC.justPressed #end)
		    {
			    persistentUpdate = false;
			    openSubState(new GameplayChangersSubstate());
		    }
		    else if(controls.RESET)
		    {
			    persistentUpdate = false;
			    openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
		    }
		    else if (controls.ACCEPT)
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
		    if (weekIsLocked(loadedWeeks[lock.ID].fileName))
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
	    if (!weekIsLocked(loadedWeeks[curWeek].fileName))
	    {
		    if (stopspamming == false)
		    {
			    FlxG.sound.play(Paths.sound('confirmMenu'));
			    grpWeekText.forEach(function(spr:FlxSprite)
			    {
				    if (spr.ID == curWeek && curWeek == 0)
				    {
					    spr.animation.play("Confirm");
				    }
			    });
			    stopspamming = true;
		    }

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
		    var songArray:Array<String> = [];
		    var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
		    for (i in 0...leWeek.length) {
			    songArray.push(leWeek[i][0]);
		    }

		    PlayState.storyPlaylist = songArray;
		    PlayState.isStoryMode = true;
		    selectedWeek = true;

		    var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
		    if(diffic == null) diffic = '';

		    PlayState.storyDifficulty = curDifficulty;

		    PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
		    PlayState.campaignScore = 0;
		    PlayState.campaignMisses = 0;
		    new FlxTimer().start(1, function(tmr:FlxTimer)
		    {
			    LoadingState.loadAndSwitchState(new PlayState(), true);
			    FreeplayState.destroyFreeplayVocals();
		    });
	    } 
	    else {
		    FlxG.sound.play(Paths.sound('nope'));
	    }
    }

    function changeDifficulty(change:Int = 0):Void
    {
	    curDifficulty = 1;

	    var diff:String = CoolUtil.difficulties[curDifficulty];
	    lastDifficultyName = diff;

	    #if !switch
	    intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
	    #end
    }

    var lerpScore:Int = 0;
	var intendedScore:Int = 0;

    function changeWeek(change:Int = 0):Void
    {
	    curWeek += change;

	    if (curWeek >= loadedWeeks.length)
		    curWeek = 0;
	    if (curWeek < 0)
		    curWeek = loadedWeeks.length - 1;

	    var leWeek = loadedWeeks[curWeek];
	    var bullShit:Int = 0;

	    var unlocked:Bool = !weekIsLocked(leWeek.fileName);
	    for (item in grpWeekText.members)
	    {
		    item.targetY = bullShit - curWeek;
		    if(item.targetY == 0)
			    text.animation.play(leWeek.characters[0]);

		    bullShit++;
	    }

	    PlayState.storyWeek = curWeek;

	    CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
	    var diffStr:String = leWeek.difficulties;
	    if(diffStr != null) diffStr = diffStr.trim();
	    difficultySelectors.visible = unlocked;

	    if(diffStr != null && diffStr.length > 0)
	    {
		    var diffs:Array<String> = diffStr.split(',');
		    var i:Int = diffs.length - 1;
		    while (i > 0)
		    {
			    if(diffs[i] != null)
			    {
				    diffs[i] = diffs[i].trim();
				    if(diffs[i].length < 1) diffs.remove(diffs[i]);
			    }
			    --i;
		    }

		    if(diffs.length > 0 && diffs[0].length > 0)
		    {
			    CoolUtil.difficulties = diffs;
		    }
	    }
	
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
		if (name == 'duke') return false;

		var leWeekArray:Array<Dynamic> = loadedWeeks.filter(function(week) return week.fileName == name);
		var leWeek:Dynamic = leWeekArray.length > 0 ? leWeekArray[0] : null;
	
		return leWeek == null || !leWeek.unlocked;
	}

    function updateText()
    {
	    var weekArray:Array<String> = loadedWeeks[curWeek].characters;

	    var leWeek = loadedWeeks[curWeek];
	    var stringThing:Array<String> = [];
	    for (i in 0...leWeek.songs.length) {
		    stringThing.push(leWeek.songs[i][0]);
	    }

	    #if !switch
	    intendedScore = Highscore.getWeekScore(leWeek.fileName, curDifficulty);
	    #end
    }
}