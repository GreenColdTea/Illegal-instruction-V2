package;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;
import haxe.format.JsonParser;
import openfl.utils.AssetType;

using StringTools;

typedef WeekFile = {
    var songs:Array<Dynamic>;
    var weekCharacters:Array<String>;
    var weekBackground:String;
    var weekBefore:String;
    var storyName:String;
    var weekName:String;
    var freeplayColor:Array<Int>;
    var startUnlocked:Bool;
    var hiddenUntilUnlocked:Bool;
    var hideStoryMode:Bool;
    var hideFreeplay:Bool;
    var difficulties:String;
}

class WeekData {
    public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
    #if desktop
    public static var weeksList:Array<String> = [];
    #else
    public static var weeksList:Array<String> = [
		"duke",
		"chaotix",
		"chotix",
        "ashura",
        "test",
		"wechidna",
		"wechnia"
    ];
    #end
    public var folder:String = '';
    
    public var songs:Array<Dynamic>;
    public var weekCharacters:Array<String>;
    public var weekBackground:String;
    public var weekBefore:String;
    public var storyName:String;
    public var weekName:String;
    public var freeplayColor:Array<Int>;
    public var startUnlocked:Bool;
    public var hiddenUntilUnlocked:Bool;
    public var hideStoryMode:Bool;
    public var hideFreeplay:Bool;
    public var difficulties:String;

    public var fileName:String;

	public static function setDirectoryFromWeek(?data:WeekData = null):Void {
        Paths.currentModDirectory = '';
        if (data != null && data.folder != null && data.folder.length > 0) {
            Paths.currentModDirectory = data.folder;
        }
    }

    public static function loadTheFirstEnabledMod():Void {
        Paths.currentModDirectory = '';

        #if MODS_ALLOWED
        if (FileSystem.exists(SUtil.getPath() + "modsList.txt")) {
            var list:Array<String> = CoolUtil.listFromString(File.getContent(SUtil.getPath() + "modsList.txt"));
            var foundTheTop = false;
            for (i in list) {
                var dat = i.split("|");
                if (dat[1] == "1" && !foundTheTop) {
                    foundTheTop = true;
                    Paths.currentModDirectory = dat[0];
                }
            }
        }
        #end
    }

    public static function getCurrentWeek():WeekData {
        return weeksLoaded.get(weeksList[PlayState.storyWeek]);
    }

    public static function getWeekFileName():String {
        return weeksList[PlayState.storyWeek];
    }

    public static function createWeekFile():WeekFile {
        return {
            songs: [["breakout", "duke", [146, 113, 253]], ["soulless-endeavours", "duke2", [146, 113, 253]]],
            weekCharacters: ['dad', 'bf', 'gf'],
            weekBackground: 'stage',
            weekBefore: 'tutorial',
            storyName: 'Your New Week',
            weekName: 'Custom Week',
            freeplayColor: [146, 113, 253],
            startUnlocked: true,
            hiddenUntilUnlocked: false,
            hideStoryMode: false,
            hideFreeplay: false,
            difficulties: ''
        };
    }

    public function new(weekFile:WeekFile, fileName:String) {
        songs = weekFile.songs;
        weekCharacters = weekFile.weekCharacters;
        weekBackground = weekFile.weekBackground;
        weekBefore = weekFile.weekBefore;
        storyName = weekFile.storyName;
        weekName = weekFile.weekName;
        freeplayColor = weekFile.freeplayColor;
        startUnlocked = weekFile.startUnlocked;
        hiddenUntilUnlocked = weekFile.hiddenUntilUnlocked;
        hideStoryMode = weekFile.hideStoryMode;
        hideFreeplay = weekFile.hideFreeplay;
        difficulties = weekFile.difficulties;

        this.fileName = fileName;
    }

    private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int) {
        if (!weeksLoaded.exists(weekToCheck)) {
            var week:WeekFile = getWeekFile(path);
            if (week != null) {
                var weekFile:WeekData = new WeekData(week, weekToCheck);
                if (i >= originalLength) {
                    #if MODS_ALLOWED
                    weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
                    #end
                }
                if ((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay)) {
                    weeksLoaded.set(weekToCheck, weekFile);
                    weeksList.push(weekToCheck);
                }
            }
        }
    }

    private static function getWeekFile(path:String):WeekFile {
        var rawJson:String = null;
        #if MODS_ALLOWED
        if (FileSystem.exists(path)) {
            rawJson = File.getContent(path);
        }
        #else
        if (OpenFlAssets.exists(path)) {
            rawJson = Assets.getText(path);
        }
        #end

        if (rawJson != null && rawJson.length > 0) {
            return cast Json.parse(rawJson);
        }
        return null;
    }

    public static function reloadWeekFiles(isStoryMode:Null<Bool> = false) {
        weeksList = [];
        weeksLoaded.clear();

        #if MODS_ALLOWED
        var disabledMods:Array<String> = [];
        var modsListPath:String = SUtil.getPath() + 'modsList.txt';
        var directories:Array<String> = [Paths.mods(), SUtil.getPath() + Paths.getPreloadPath()];
        var originalLength:Int = directories.length;
        #else
        var directories:Array<String> = [Paths.getPreloadPath()];
        var originalLength:Int = directories.length;
        #end

        #if !desktop
        var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getPath('weeks/weekList.txt', AssetType.TEXT, "shared"));
        #else
        var sexList:Array<String> = CoolUtil.coolTextFile(SUtil.getPath() + Paths.getPreloadPath('weeks/weekList.txt'));
        #end

        for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
				if(!weeksLoaded.exists(sexList[i])) {
					var week:WeekFile = null;
					#if desktop
					var week:WeekFile = getWeekFile(fileToCheck);
					#else
					var weekFilePath:String = Paths.getPath(fileToCheck, AssetType.TEXT, "shared");
					if (Assets.exists(weekFilePath)) {
						var week:WeekFile = getWeekFile(weekFilePath);
					}
					#end
		
					if(week != null) {
						var weekFile:WeekData = new WeekData(week, sexList[i]);
						// Обработка weekFile
					}
				}
			}
		}
		

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i] + 'weeks/';
			if(FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if(sys.FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}
}