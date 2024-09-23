package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;

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
    var bars:Array<FlxSprite>;
    var numBars:Int = 10; // bars amount

    override public function create():Void {
      
        musicII = new FlxSound();
        
        // Track list
        musicList = [
            {name: "Breakout", path: "assets/music/visualizer/Breakout.mp3"},
            {name: "Soulless Endeavors/Hellspawn", path: "assets/music/visualizer/SE-HS.mp3"},
            {name: "Apptheosis(Sssprite Mix)", path: "assets/music/visualizer/Apotheosis(Sssprie).mp3"}
        ];
        
        // First track loading
        loadCurrentTrack();

        // Logo
        logo = new FlxSprite(FlxG.width / 2, FlxG.height / 2);
        logo.loadGraphic(Paths.image("logo"));
        logo.scale.set(1, 1);
        logo.setGraphicSize(150, 150);
        logo.updateHitbox();
        add(logo);

        // BG
        entranceBG = new FlxSprite(-325, -50);
        entranceBG.loadGraphic(Paths.image('entrance/bg', 'exe'));
	entranceBG.scrollFactor.set();
	entranceBG.scale.set(1.1, 1.1);
	entranceBG.antialiasing = true;

	entranceClock = new FlxSprite(-450, -50);
	entranceClock.loadGraphic(Paths.image('entrance/clock', 'exe'));
	entranceClock.scrollFactor.set();
	entranceClock.scale.set(1.1, 1.1);
	entranceClock.antialiasing = true;

	entranceIdk = new FlxSprite(-355, -50);
	entranceIdk.loadGraphic(Paths.image('entrance/idk', 'exe'));
	entranceIdk.scrollFactor.set();
	entranceIdk.scale.set(1.1, 1.1);
	entranceIdk.antialiasing = true;

	entranceFloor = new FlxSprite(-375, -50);
	entranceFloor.loadGraphic(Paths.image('entrance/floor', 'exe'));
	entranceFloor.scrollFactor.set();
	entranceFloor.scale.set(1.1, 1.1);
	entranceFloor.antialiasing = true;

	entranceOver = new FlxSprite(-325, -125);
	entranceOver.loadGraphic(Paths.image('entrance/over', 'exe'));
	entranceOver.scrollFactor.set();
	entranceOver.scale.set(1.1, 1.1);
	entranceOver.antialiasing = true;

        // Track name
        trackNameText = new FlxText(0, 10, FlxG.width, musicList[currentTrack].name);
        trackNameText.size = 16;
        trackNameText.setFormat(null, 16, FlxColor.WHITE, "center");
        add(trackNameText);

        // creating amplitude bars
        bars = [];
        for (i in 0...numBars) {
            var bar = new FlxSprite(FlxG.width / 2 + i * 15 - numBars * 7, FlxG.height / 2 + 100);
            bar.makeGraphic(10, 50, FlxColor.WHITE);
            add(bar);
            bars.push(bar);
        }
	addVirtualPad(LEFT_RIGHT, A_B);
    }

    // Track loading
    function loadCurrentTrack():Void {
        musicII.stop();
        musicII.loadEmbedded(musicList[currentTrack].path, true);
        musicII.play();
        // track name update
        trackNameText.text = musicList[currentTrack].name;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Button touch checker
        handleInput();

        // Logo bobbing
        var scaleFactor:Float = musicII.amplitude * 5; //amplitude increase by volume 
        logo.scale.set(1 + scaleFactor, 1 + scaleFactor);

        // amplitude heights
        for (i in 0...bars.length) {
            var bar = bars[i];
            bar.scale.y = musicII.amplitude * 100;
        }
    }

    // button click checker
    function handleInput():Void {
        // Next song
        if (FlxG.keys.justPressed.RIGHT) {
            currentTrack = (currentTrack + 1) % musicList.length;
            loadCurrentTrack();
        }

        // Back song
        if (FlxG.keys.justPressed.LEFT) {
            currentTrack = (currentTrack - 1 + musicList.length) % musicList.length;
            loadCurrentTrack();
        }

        // Song pause/resume
        if (FlxG.keys.justPressed.ENTER) {
            if (isPlaying) {
                musicII.pause();
            } else {
                musicII.resume();
            }
            isPlaying = !isPlaying;
        }
    }
}
