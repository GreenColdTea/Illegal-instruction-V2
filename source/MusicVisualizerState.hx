package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;

class MusicVisualizerState extends MusicBeatState {
    var musicII:FlxSound;
    var logo:FlxSprite;
    var entranceBG:FlxSprite;
    var entranceClock:FlxSprite;
    var entranceIdk:FlxSprite;
    var entranceFloor:FlxSprite;
    var entranceOver:FlxSprite;
    var musicList:Array<{name:String, path:String}>;
    var currentTrack:Int = 0;
    var isPlaying:Bool = false;
    var trackNameText:FlxText;
    var bars:Array<FlxSprite>; // array of bars for the visualizer
    var numBars:Int = 10; // number of bars
    var slider:FlxBar; // slider for track seeking
    var currentTimeText:FlxText; // current time of the track
    var totalTimeText:FlxText; // total length of the track

    override public function create():Void {
        musicII = new FlxSound();
        
        // track list
        musicList = [
            {name: "Breakout", path: "assets/music/visualizer/Breakout.mp3"},
            {name: "Soulless Endeavors/Hellspawn", path: "assets/music/visualizer/SE-HS.mp3"},
            {name: "Apotheosis(Sssprite Mix)", path: "assets/music/visualizer/Apotheosis(Sssprite).mp3"}
        ];
        
        // first track loading
        loadCurrentTrack();

        logo = new FlxSprite(FlxG.width / 2, FlxG.height / 2);
        logo.loadGraphic(Paths.image("logo"));
        logo.scale.set(1, 1);
        logo.setGraphicSize(150, 150);
	logo.screenCenter(X);
        logo.updateHitbox();
        add(logo);

        // BG
        entranceBG = new FlxSprite(-325, -50);
        entranceBG.loadGraphic(Paths.image('entrance/bg', 'exe'));
	entranceBG.scrollFactor.set();
	entranceBG.scale.set(1.1, 1.1);
	entranceBG.screenCenter();
	entranceBG.antialiasing = true;
	add(entranceBG);

	entranceClock = new FlxSprite(-450, -50);
	entranceClock.loadGraphic(Paths.image('entrance/clock', 'exe'));
	entranceClock.scrollFactor.set();
	entranceClock.screenCenter();
	entranceClock.scale.set(1.1, 1.1);
	entranceClock.antialiasing = true;
	add(entranceClock);

	entranceIdk = new FlxSprite(-355, -50);
	entranceIdk.loadGraphic(Paths.image('entrance/idk', 'exe'));
	entranceIdk.scrollFactor.set();
	entranceIdk.screenCenter();
	entranceIdk.scale.set(1.1, 1.1);
	entranceIdk.antialiasing = true;
	add(entranceIdk);

	entranceFloor = new FlxSprite(-375, -50);
	entranceFloor.loadGraphic(Paths.image('entrance/floor', 'exe'));
	entranceFloor.scrollFactor.set();
	entranceFloor.scale.set(1.1, 1.1);
	entranceFloor.screenCenter();
	entranceFloor.antialiasing = true;
	add(entranceFloor);

	entranceOver = new FlxSprite(-325, -125);
	entranceOver.loadGraphic(Paths.image('entrance/over', 'exe'));
	entranceOver.scrollFactor.set();
	entranceOver.screenCenter();
	entranceOver.scale.set(1.1, 1.1);
	entranceOver.antialiasing = true;
	add(entranceOver);

        // add text to display track name
        trackNameText = new FlxText(0, 500, FlxG.width, 'Now playing:' + musicList[currentTrack].name);
        trackNameText.size = 16;
        trackNameText.setFormat(Paths.font("chaotix.ttf"), 16, FlxColor.WHITE, "left");
        add(trackNameText);

        // create an array of bars for the visualizer
        bars = [];
        for (i in 0...numBars) {
            var bar = new FlxSprite(FlxG.width / 2 + i * 15 - numBars * 7, FlxG.height / 2 + 100);
            bar.makeGraphic(10, 50, FlxColor.WHITE);
            add(bar);
            bars.push(bar);
        }

        // slider for track seeking positioned below center and colored green
        slider = new FlxBar(50, FlxG.height - 100, 1, 200, 10);
        slider.createFilledBar(FlxColor.PURPLE, FlxColor.GREEN);
        add(slider);

        // current track time (position)
        currentTimeText = new FlxText(30, FlxG.height - 120, 100, "0:00");
        currentTimeText.size = 12;
        currentTimeText.setFormat(Paths.font("chaotix.ttf"), 12, FlxColor.WHITE);
        add(currentTimeText);

        // total track time (duration)
        totalTimeText = new FlxText(260, FlxG.height - 120, 100, "0:00");
        totalTimeText.size = 12;
        totalTimeText.setFormat(Paths.font("chaotix.ttf"), 12, FlxColor.WHITE);
        add(totalTimeText);

	#if !mobile
	FlxG.mouse.visible = true;
	#end
    }

    // track loading
    function loadCurrentTrack():Void {
        musicII.stop();
        musicII.loadEmbedded(musicList[currentTrack].path, true);
        musicII.play();
        // update track name text
        trackNameText.text = musicList[currentTrack].name;

        // set slider's max range to the track length
        slider.setRange(0, musicII.length);
        
        // update total time display
        updateTotalTime();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // check input for control
        handleInput();

        // update the slider based on the track's current time
        slider.value = musicII.time;
        
        // update the current time display
        updateCurrentTime();

        // logo bobbing based on the track's amplitude
        var scaleFactor:Float = musicII.amplitude * 5;
        logo.scale.set(1 + scaleFactor, 1 + scaleFactor);

        // update bar heights based on track's amplitude
        for (i in 0...bars.length) {
            var bar = bars[i];
            bar.scale.y = musicII.amplitude * 100;
        }

        // handle slider seeking with the mouse
        if (FlxG.mouse.pressed() && FlxG.mouse.overlaps(slider)) {
            musicII.time = slider.value;
        }
    }

    // check input for track control
    function handleInput():Void {
        // next track
        if (controls.UI_RIGHT_P) {
            currentTrack = (currentTrack + 1) % musicList.length;
            loadCurrentTrack();
        }

        // previous track
        if (controls.UI_LEFT_P) {
            currentTrack = (currentTrack - 1 + musicList.length) % musicList.length;
            loadCurrentTrack();
        }

        // play/pause track
        if (controls.ACCEPT) {
            if (isPlaying) {
                musicII.pause();
            } else {
                musicII.resume();
            }
            isPlaying = !isPlaying;
        }

	if (controls.BACK)
        {
            ByeBye();
	}
    }

    public function ByeBye() 
    {
	FlxG.sound.play(Paths.sound('cancelMenu'));
	#if !mobile
	FlxG.mouse.visible = false;
	#end
        MusicBeatState.switchState(new MainMenuState());
    }

    // update the current time display
    function updateCurrentTime():Void {
        var minutes:Int = Std.int(musicII.time / 60);
        var seconds:Int = Std.int(musicII.time % 60);
        currentTimeText.text = Std.string(minutes) + ":" + (seconds < 10 ? "0" : "") + Std.string(seconds);
    }

    // update the total track time display
    function updateTotalTime():Void {
        var totalMinutes:Int = Std.int(musicII.length / 60);
        var totalSeconds:Int = Std.int(musicII.length % 60);
        totalTimeText.text = Std.string(totalMinutes) + ":" + (totalSeconds < 10 ? "0" : "") + Std.string(totalSeconds);
    }
}
