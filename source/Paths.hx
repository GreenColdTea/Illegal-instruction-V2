package;

import openfl.display3D.textures.Texture;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import haxe.xml.Access;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;

import openfl.media.Sound;

using StringTools;

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'exe',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'fonts',
		'scripts',
	];

	public static final HSCRIPT_EXTENSIONS:Array<String> = ["hscript", "hxs", "hx"];

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static var localTrackedAssets:Array<String> = [];
	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)			 
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
					  
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
	 
			if (!localTrackedAssets.contains(key) 
				&& !dumpExclusions.contains(key)) {
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
	 
				  var isTexture:Bool = currentTrackedTextures.exists(key);
				  if (isTexture)					
				  {						
				    var texture = currentTrackedTextures.get(key);			
				    texture.dispose();						
				    texture = null;			
				    currentTrackedTextures.remove(key);					
				    
				  }
					OpenFlAssets.cache.removeBitmapData(key);
					OpenFlAssets.cache.clearBitmapData(key);
	  
					OpenFlAssets.cache.clear(key);
					FlxG.bitmap._cache.remove(key);																 
					obj.destroy();
					currentTrackedAssets.remove(key);
			   
				}
			}
		}							   
		// run the garbage collector for good measure lmfao
		openfl.system.System.gc();
		#if cpp
		cpp.NativeGc.run(true);
		#end
	}

	// define the locally tracked assets

	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key)) {
  
				OpenFlAssets.cache.removeBitmapData(key);
				OpenFlAssets.cache.clearBitmapData(key);
				OpenFlAssets.cache.clear(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
	        }
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key) 
			&& !dumpExclusions.contains(key) && key != null) {
				//trace('test: ' + dumpExclusions, key);
				//Assets.cache.clear(key);
				OpenFlAssets.cache.removeSound(key);				
				OpenFlAssets.cache.clearSounds(key);
				currentTrackedSounds.remove(key);
	 
			}		   
		}

        for (key in OpenFlAssets.cache.getKeys())	
        {			
            if (!localTrackedAssets.contains(key) && key != null)		
            {				
                OpenFlAssets.cache.clear(key);			
            }	
        }
		
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{

		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = ''):String
        {
        /*#if (android || ios)
                return lime.system.System.applicationStorageDirectory + '/assets/' + file;
        #else*/
                return 'assets/' + file;
        //#end
        }

	
	/*inline public static function getPreloadPathlua(file:String = '')
	{
		return Main.path + 'assets/$file';
	}*/

	public static function getFileWithExts(scriptPath:String, extensions:Array<String>) {
		for (fileExt in extensions) {
			var baseFile:String = '$scriptPath.$fileExt';
			for (file in [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)]) {
				if (OpenFlAssets.exists(file))
					return file;
				      
			}
		}

		return null;
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function shaderFrag(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVert(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return Main.path + getPath('$key.lua', TEXT, library);
	}
	
	inline static public function luaAsset(key:String, ?library:String)
        {
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		return Generic.returnPath() + 'assets/videos/$key.$VIDEO_EXT';
	}
	
	static public function _video(key:String)
	{
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function weeks(key:String)
	{
		return Generic.returnPath() + 'assets/weeks/$key.json';
	}

	static public function _weeks(key:String)
	{
		return 'assets/weeks/$key.json';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String, postfix:String = null):Any {
		var songKey:String = '${formatToSongPath(song)}/voices';
		if (postfix != null) songKey += '-' + postfix;
	
		var snd = returnSound(null, songKey, 'songs');
		if (snd == null) {
			songKey = '${formatToSongPath(song)}/Voices';
			if (postfix != null) songKey += '-' + postfix;
			snd = returnSound(null, songKey, 'songs');
		}
	
		return snd;
	}
	
	inline static public function inst(song:String):Any {
		var songKey:String = '${formatToSongPath(song)}/inst';
		var snd = returnSound(null, songKey, 'songs');
	
		if (snd == null) {
			songKey = '${formatToSongPath(song)}/Inst';
			snd = returnSound(null, songKey, 'songs');
		}
	
		return snd;
	}
	

	inline static public function image(key:String, ?library:String, ?allowGPU:Bool = false):Dynamic
	{
		// streamlined the assets process more 
		if (ClientPrefs.cacheOnGPU || ClientPrefs.adaptiveCache) {
			allowGPU = true;
		}
		var returnAsset:FlxGraphic = returnGraphic(key, library, allowGPU);
		return returnAsset;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(mods(key)))
			return File.getContent(mods(key));

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key))) {
			return true;
		}
		#end

		if(OpenFlAssets.exists(getPath(key, type))) {
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String, ?allowGPU:Bool = false):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var graphic:FlxGraphic = returnGraphic(key, library, allowGPU);
		var xmlExists:Bool = false;
		if (ClientPrefs.cacheOnGPU) {
			allowGPU = true;
		}
		if(FileSystem.exists(modsXml(key))) {
			xmlExists = true;
		}
		return FlxAtlasFrames.fromSparrow(graphic, (xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		var graphic:FlxGraphic = returnGraphic(key, library, allowGPU);
		return FlxAtlasFrames.fromSparrow(graphic, file('images/$key.xml', library));
		#end
	}


	inline static public function getPackerAtlas(key:String, ?library:String,  ?allowGPU:Bool = false)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key, allowGPU);
		var txtExists:Bool = false;
		if (ClientPrefs.cacheOnGPU) {
			allowGPU = true;
		}
		if(FileSystem.exists(modsTxt(key))) {
			txtExists = true;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public inline static function getHScriptPath(scriptPath:String)
	{
		#if hscript
		return getFileWithExts(scriptPath, Paths.HSCRIPT_EXTENSIONS);
		#else
		return null;
		#end
	}

	// completely rewritten asset loading? fuck!
	

	public static function returnGraphic(key:String, ?library:String, ?allowGPU:Bool = false) {
		#if MODS_ALLOWED
		if(FileSystem.exists(modsImages(key))) {
			if(!currentTrackedAssets.exists(key)) {
				var newBitmap:BitmapData = BitmapData.fromFile(modsImages(key));
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, key);
				currentTrackedAssets.set(key, newGraphic);
			}
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		#end

		if (ClientPrefs.cacheOnGPU) {
			allowGPU = true;
		}
	
		var path = getPath('images/$key.png', IMAGE, library);
		if (OpenFlAssets.exists(path, IMAGE)) {
			if(!currentTrackedAssets.exists(key)) {
				var bitmap = BitmapData.fromFile(path.substr(path.indexOf(':') + 1));
				var newGraphic:FlxGraphic;
	
				if (allowGPU && (ClientPrefs.cacheOnGPU || ClientPrefs.adaptiveCache)) {
					var texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
					texture.uploadFromBitmapData(bitmap);
					currentTrackedTextures.set(key, texture);
					bitmap.dispose();
					bitmap.disposeImage();
					bitmap = null;
					newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				} else {
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
				}
	
				newGraphic.persist = true;
				currentTrackedAssets.set(key, newGraphic);
			}
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
	
		trace('bitmap $key is returning null NOOOO');
		return null;
	}
	
	public static function returnSound(path:Null<String>, key:String, ?library:String) {
		// I hate this so god damn much
		var gottenPath:String = '$key.$SOUND_EXT';
		if(path != null) gottenPath = '$path/$gottenPath';
		gottenPath = getPath(gottenPath, SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath))
		{
			var retKey:String = (path != null) ? '$path/$key' : key;
			retKey = ((path == 'songs') ? 'songs:' : '') + getPath('$retKey.$SOUND_EXT', SOUND, library);
			if(OpenFlAssets.exists(retKey, SOUND))
			{
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(retKey));
				//trace('precached vanilla sound: $retKey');
			}
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}

	inline static public function modsFont(key:String) {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

  #if MODS_ALLOWED
	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}
   #end

	inline static public function modsSounds(path:String, key:String) {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String) {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

	inline static public function modsAchievements(key:String) {
		return modFolders('achievements/' + key + '.json');
	}

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;

		}
		return SUtil.getPath() + 'mods/' + key;
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		var path:String = SUtil.getPath() + 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if(FileSystem.exists(path)) {
						try{
							var rawJson:String = File.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global)globalMods.push(dat[0]);
							}
						} catch(e:Dynamic){
							trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if(FileSystem.exists(modsFolder)) {
			for (folder in FileSystem.readDirectory(modsFolder)) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end
}
