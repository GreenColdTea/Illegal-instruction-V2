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
    var bgColor:Int;
    var musicList:Array<{name:String, path:String}>;
    var currentTrack:Int = 0;
    var isPlaying:Bool = true;
    var trackNameText:FlxText;

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
        logo.loadGraphic(Paths.image("visualizer/logo"));
        logo.scale.set(1, 1);
        logo.setGraphicSize(150, 150);
        logo.updateHitbox();
        add(logo);

        // BG
        bgColor = FlxColor.WHITE;
        FlxG.bgColor = bgColor;

        // Добавляем текст для отображения названия трека
        trackNameText = new FlxText(0, 10, FlxG.width, musicList[currentTrack].name);
        trackNameText.size = 16;
        trackNameText.setFormat(null, 16, FlxColor.WHITE, "center");
        add(trackNameText);
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
        var scaleFactor:Float = sound.amplitude * 5; // Увеличение в зависимости от громкости
        logo.scale.set(1 + scaleFactor, 1 + scaleFactor);

        // BG change
        if (sound.amplitude > 0.5) {
            FlxG.bgColor = FlxColor.RED;
        } else {
            FlxG.bgColor = bgColor;
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
