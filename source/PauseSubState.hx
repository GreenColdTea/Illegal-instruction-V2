package;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.util.FlxStringUtil;
import openfl.utils.Assets as OpenFlAssets;
import options.OptionsState;

using StringTools;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<FlxText>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song' #if mobile, 'Debug Mode' #end, 'Options', 'Exit'];
	var difficultyChoices = [];
	var curSelected:Int = 0;
	var menuItemsText:Array<FlxText> = [];
	var clones:Array<FlxText> = [];

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var levelDifficulty:FlxText;
	var pauseArt:FlxSprite;
	var skipTimeTracker:FlxText;

	var elapsedTime:Float = 0;

	var fontStyle:String;

	public static var levelInfo:FlxText;

	public static var curRender:String;

	var curTime:Float = Math.max(0, Conductor.songPosition);
	//var botplayText:FlxText;

	public static var songName:String = '';

	public function new(x:Float, y:Float)
	{
		super();
		//if(CoolUtil.difficulties.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!

		if(PlayState.chartingMode
			#if debug
			|| true
			#end)
		{
			#if !debug
			menuItemsOG.insert(2, 'Turn Off Debug Mode');
			#end
			
			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time:');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		menuItems = menuItemsOG;

	        curRender = PlayState.instance.dad.curCharacter;

		for (i in 0...CoolUtil.difficulties.length) {
			var diff:String = '' + CoolUtil.difficulties[i];
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');


		pauseMusic = new FlxSound();
		if (songName != null) {
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		} else if (songName != 'None') {
			pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)), true, true);
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

	        var renderDistance:Float = -75;
		pauseArt = new FlxSprite(renderDistance * -1, -450);
	        pauseArt.scale.set(0.4, 0.4);
		pauseArt.loadGraphic(Paths.image('Renders/' + curRender, 'shared'));
		pauseArt.scrollFactor.set();
		if (!OpenFlAssets.exists(Paths.getPath('Renders/' + curRender + '.png', IMAGE, 'shared'))) add(pauseArt);
		pauseArt.x = renderDistance * -1;
	        pauseArt.antialiasing = true;
		pauseArt.alpha = 0;

	        if (PlayState.instance.dad.curCharacter == 'dukep2midsong' || PlayState.instance.dad.curCharacter == 'dukepixel') {
                        curRender = 'dukep2';
		} else if (PlayState.instance.dad.curCharacter == 'wechidnaMH') {
			curRender = 'wechidna';
		} else if (PlayState.instance.dad.curCharacter == 'wechMH') {
                        curRender = 'wechbeast';
		}

		fixRenders();

		levelInfo = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += Std.string(PlayState.SONG.song).replace("-", " ");
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("chaotix.ttf"), 32);
		if (PlayState.SONG.song.toLowerCase() == 'found-you-legacy') { 
			levelInfo.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 32);
		}
		levelInfo.updateHitbox();
		add(levelInfo);

		levelDifficulty = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('chaotix.ttf'), 32);
		levelDifficulty.updateHitbox();

		var blueballedTxt:FlxText = new FlxText(20, 15 + 48, 0, "", 32);
		blueballedTxt.text = "Defeats: " + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('chaotix.ttf'), 32);
		if (PlayState.SONG.song.toLowerCase() == 'found-you-legacy') { 
			blueballedTxt.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 32);
		}
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 101, 0, "PRACTICE MODE", 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('chaotix.ttf'), 32);
                if (PlayState.SONG.song.toLowerCase() == 'found-you-legacy') { 
			practiceText.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 32);
		}
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.instance.practiceMode;
		add(practiceText);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, "DEBUG MODE", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('chaotix.ttf'), 32);
		if (PlayState.SONG.song.toLowerCase() == 'found-you-legacy') { 
			chartingText.setFormat(Paths.font("sonic-cd-menu-font.ttf"), 32);
		}
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		#if !debug
		chartingText.visible = PlayState.chartingMode;
		#else
		chartingText.visible = true;
		#end	
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
	        FlxTween.tween(pauseArt, {alpha: 1}, 0.55, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<FlxText>();
		add(grpMenuShit);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

                #if mobile
		if (PlayState.chartingMode)
		{
		        addVirtualPad(LEFT_FULL, A);
		}
		else
		{
		        addVirtualPad(UP_DOWN, A);
		}
		addVirtualPadCamera();
		#end
	}
			 
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		elapsedTime += elapsed;

		updateClones(elapsed);
		//Outdated
		/*if (PlayState.SONG.song.toLowerCase() == 'breakout' && PlayState.lastStepHit == 800) {
			curRender = "dukep2";
		        pauseArt.x = 75;
			pauseArt.y = -450;
		}*/

		super.update(elapsed);
		updateSkipTextStuff();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var back = controls.BACK;

		if(back)
		{
			close();
		}

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time:':
				if (controls.UI_LEFT_P)
				{
					if(FlxG.keys.pressed.SHIFT){
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						curTime -= 1000 * 60;
						holdTime = 0;
					}else{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						curTime -= 1000;
						holdTime = 0;
					}

				}
				if (controls.UI_RIGHT_P){
					if (FlxG.keys.pressed.SHIFT)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						curTime += 1000 * 60;
						holdTime = 0;
					}
					else
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						curTime += 1000;
						holdTime = 0;
					}
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (accepted)
		{
			if (menuItems == difficultyChoices)
			{
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
					var name:String = PlayState.SONG.song;
					var poop = Highscore.formatSong(name, curSelected);
					PlayState.SONG = Song.loadFromJson(poop, name);
					PlayState.storyDifficulty = curSelected;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
					PlayState.changedDifficulty = true;
					PlayState.chartingMode = false;
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = PlayState.instance.practiceMode;
				case "Restart Song":
					restartSong();
				case "Turn Off Debug Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Debug Mode':
		                        close();
					PlayState.chartingMode = true;
				case 'Skip Time:':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case "End Song":
					close();
					PlayState.instance.finishSong(true);
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case 'Options':
					PlayState.instance.paused = true;
					PlayState.instance.vocals.stop();
					PlayState.instance.canResync = false;
					MusicBeatState.switchState(new OptionsState());
					if (ClientPrefs.pauseMusic != "None")
					{
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;
					}
					OptionsState.onPlayState = true;
				case "Exit":
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					if(PlayState.isStoryMode) {
						#if !mobile
						MusicBeatState.switchState(new StoryMenuState());
						#else
						MusicBeatState.switchState(new mobile.StoryMenuState());
						#end
					} else if (PlayState.isFreeplay) {
						MusicBeatState.switchState(new BallsFreeplay());
					} else {
						MusicBeatState.switchState(new LegacyRoomState());
					}
					//FlxG.sound.playMusic(Paths.music('freakyMenu'));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
			}
		}
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function fixRenders():Void
	{
		switch (curRender)
		{
			case "duke":
				pauseArt.x += 215;
				pauseArt.y -= 125;
			case 'chaotix' |'chaotix-rimlit':
				pauseArt.x -= 175;
				pauseArt.y += 35;
			case "chotix":
				pauseArt.scale.set(0.5, 0.5);
				pauseArt.x += 350;
				pauseArt.y += 270;
			case "Wechnia":
				pauseArt.x += 250;
				pauseArt.y += 35;
		}
	}

        function changeSelection(change:Int = 0):Void {
            curSelected = (curSelected + change + menuItemsText.length) % menuItemsText.length;
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            updateMenuSelection();
	}

        function regenMenu():Void {
            for (i in 0...grpMenuShit.members.length) {
                var obj = grpMenuShit.members[0];
                obj.kill();
                grpMenuShit.remove(obj, true);
                obj.destroy();
            }
            menuItemsText = [];

            var spacing = 50;
            var startY = (FlxG.height - (menuItems.length * spacing)) * 0.5;
		
            if (PlayState.SONG.song.toLowerCase() == "found-you-legacy") {
                fontStyle = "sonic-cd-menu-font.ttf";
            } else {
                fontStyle = "chaotix.ttf";
            }

            for (i in 0...menuItems.length) {
                var item = new FlxText(0, startY + (i * spacing), 0, menuItems[i], 42);
                item.setFormat(Paths.font(fontStyle), 42, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                item.borderSize = 2;
                item.scrollFactor.set();
                item.screenCenter(X);
                item.x -= 350;
                item.updateHitbox();
                grpMenuShit.add(item);
                menuItemsText.push(item);

		if (menuItems[i] == 'Skip Time:') {
                      skipTimeText = new FlxText(0, item.y + 10, 0, '', 39);
                      skipTimeText.setFormat(Paths.font(fontStyle), 39, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                      skipTimeText.borderSize = 2;
		      skipTimeText.x -= 87.5;
                      skipTimeText.scrollFactor.set();
                      skipTimeTracker = item;
                      add(skipTimeText);

                      updateSkipTextStuff();
                      updateSkipTimeText();
		}
		    
		createSelectionEffect();
                updateMenuSelection();
	    }

            curSelected = 0;
            updateMenuSelection();
        }

        function updateMenuSelection():Void {
            for (i in 0...menuItemsText.length) {
                menuItemsText[i].alpha = (i == curSelected) ? 1 : 0.6;
	    }
            positionClones();
	}

        function createSelectionEffect() {
            for (i in 0...3) {
                var clone = new FlxText(0, 0, 0, "", 42);
                clone.setFormat(Paths.font(fontStyle), 42, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
                clone.borderSize = 2;
                clone.alpha = 0.5;
                add(clone);
                clones.push(clone);
            }
	}

        function positionClones() {
            var baseItem = grpMenuShit.members[curSelected];
            for (i in 0...clones.length) {
                clones[i].text = baseItem.text;
                clones[i].setPosition(baseItem.x, baseItem.y);
            }
        }

        function updateClones(elapsed:Float) {
            var radius = 10;
            var baseItem = grpMenuShit.members[curSelected];

            for (i in 0...clones.length) {
                var angle = (elapsedTime * 3) + (i * (Math.PI * 2 / clones.length));
                clones[i].x = baseItem.x + Math.cos(angle) * radius;
                clones[i].y = baseItem.y + Math.sin(angle) * radius;
	    }
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}
