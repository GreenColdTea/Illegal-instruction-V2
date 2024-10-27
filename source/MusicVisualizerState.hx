package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;

class MusicVisualizerState extends MusicBeatState {
    
    var musicII:FlxSound;
    var logo:FlxSprite;
    var entranceBG:FlxSprite;
    var musicList:Array<{name:String, path:String}>;
    var currentTrack:Int = 0;
    var isPlaying:Bool = false;
    var trackNameText:FlxText;
    var bars:Array<FlxSprite>;
    var numBars:Int = 10;
    var slider:FlxBar;
    var currentTimeText:FlxText;
    var totalTimeText:FlxText;

    override public function create() {
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();
        FlxG.sound.music.stop();

        musicII = new FlxSound();
        musicII.volume = 1;

        musicList = [
            {name: "Breakout", path: "assets/music/visualizer/Breakout.ogg"},
            {name: "Soulless Endeavors\nHellspawn", path: "assets/music/visualizer/Hellspawn(SE).ogg"},
            {name: "Apotheosis \nSssprite Mix", path: "assets/music/visualizer/Apotheosis(Sssprite).ogg"}
        ];

        loadCurrentTrack();

        entranceBG = new FlxSprite();
        entranceBG.loadGraphic(Paths.image('entranceFull'));
        entranceBG.scrollFactor.set();
        entranceBG.scale.set(1.5, 1.5);
        entranceBG.screenCenter();
        entranceBG.antialiasing = true;
        add(entranceBG);

        trackNameText = new FlxText(0, 500, FlxG.width, 'Now playing: ' + musicList[currentTrack].name);
        trackNameText.size = 16;
        trackNameText.setFormat(Paths.font("chaotix.ttf"), 16, FlxColor.WHITE, "right");
        add(trackNameText);

        logo = new FlxSprite();
        logo.loadGraphic(Paths.image("logo"));
        logo.scale.set(1.1, 1.1);
        logo.screenCenter();
        logo.updateHitbox();
        add(logo);

        bars = [];
        for (i in 0...numBars) {
            var bar = new FlxSprite(FlxG.width / 2 + i * 15 - numBars * 7, FlxG.height / 2 + 100);
            bar.makeGraphic(10, 50, FlxColor.WHITE);
            bar.screenCenter();
            add(bar);
            bars.push(bar);
        }

        slider = new FlxBar(50, FlxG.height - 50, LEFT_TO_RIGHT, FlxG.width - 100, 5);
        slider.createFilledBar(FlxColor.PURPLE, FlxColor.GREEN);
        slider.scrollFactor.set();
        add(slider);

        currentTimeText = new FlxText(30, FlxG.height - 120, 100, "0:00");
        currentTimeText.size = 12;
        currentTimeText.setFormat(Paths.font("chaotix.ttf"), 12, FlxColor.WHITE);
        add(currentTimeText);

        totalTimeText = new FlxText(260, FlxG.height - 120, 100, "0:00");
        totalTimeText.size = 12;
        totalTimeText.setFormat(Paths.font("chaotix.ttf"), 12, FlxColor.WHITE);
        add(totalTimeText);

        #if !mobile
        FlxG.mouse.visible = true;
        #end
    }

    function loadCurrentTrack():Void {
        musicII.stop();
        musicII.loadEmbedded(musicList[currentTrack].path, true);
        musicII.play();
        updateTotalTime();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        handleInput();

        if (musicII != null && musicII.playing) {
            slider.value = musicII.time;
            updateCurrentTime();

            var curTime:Float = musicII.time;
            if(curTime < 0) curTime = 0;

            var barSongLength:Float = musicII.length;
            var songPercent:Float = (curTime / barSongLength);

            for (i in 0...bars.length) {
                var bar = bars[i];
                bar.scale.y = songPercent * 200; 
            }
        }        

        if (musicII.playing) {
            var targetScale:Float = 0.25 + musicII.volume * 0.5;
            logo.scale.set(lerp(logo.scale.x, targetScale, 0.1), lerp(logo.scale.y, targetScale, 0.1));
            for (i in 0...bars.length) {
                var bar = bars[i];
                bar.scale.y = musicII.volume * 200;
            }
        } else {
            logo.scale.set(0.25, 0.25);
        }
        
        if (FlxG.mouse.pressed && FlxG.mouse.overlaps(slider)) {
            musicII.time = slider.value;
        }
    }

    function handleInput() {

        if (controls.ACCEPT) {
            if (musicII != null) {
                if (isPlaying) {
                    musicII.pause();
                    isPlaying = false;
                } else {
                    musicII.resume();
                    isPlaying = true;
                }
                isPlaying = !isPlaying;
            }
        }

        if (controls.UI_RIGHT_P) {
            currentTrack = (currentTrack + 1) % musicList.length;
            trackNameText.text = 'Now playing: ' + musicList[currentTrack].name;
            loadCurrentTrack();
        }

        if (controls.UI_LEFT_P) {
            currentTrack = (currentTrack - 1 + musicList.length) % musicList.length;
            trackNameText.text = 'Now playing: ' + musicList[currentTrack].name;
            loadCurrentTrack();
        }
    }

    function updateCurrentTime() {
        currentTimeText.text = formatTime(musicII.time);
    }

    function updateTotalTime() {
        totalTimeText.text = formatTime(musicII.length);
    }

    function formatTime(seconds:Float):String {
        var minutes:Int = Std.int(seconds / 60);
        var remainingSeconds:Int = Std.int(seconds % 60);
        return Std.string(minutes) + ":" + (remainingSeconds < 10 ? "0" : "") + Std.string(remainingSeconds);
    }

    function lerp(start:Float, end:Float, alpha:Float):Float {
        return start + (end - start) * alpha;
    }
}
