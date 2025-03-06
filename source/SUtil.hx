package;

import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Exception;
import lime.app.Application;
import flixel.FlxG;
#if android
import android.content.Context as AndroidContext;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.Tools as AndroidTools;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
#end
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

/**
 * A storage class for mobile.
 * @author Karim Akra and Lily Ross (mcagabe19)
 */
class SUtil
{
	#if sys
	// root directory, used for handling the saved storage type and path
	public static final rootDir:String = LimeSystem.applicationStorageDirectory;

	#if android
	private static var aDir:String = null; // android dir
	#end

	public static function getPath():String
	{
		#if android
		if (aDir != null && aDir.length > 0)
			return aDir;
		else
			return aDir = AndroidEnvironment.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file') + '/';
		#else
		return '';
		#end
	}

	public static function getStorageDirectory(?force:Bool = false):String
	{
		var daPath:String = '';
		#if android
		if (!FileSystem.exists(rootDir + 'storagetype.txt'))
			File.saveContent(rootDir + 'storagetype.txt', Generic.returnPath());
		var curStorageType:String = File.getContent(rootDir + 'storagetype.txt');
		daPath = force ? Generic.returnPath() : Generic.returnPath();
		daPath = Path.addTrailingSlash(daPath);
		#else
		daPath = Sys.getCwd();
		#end

		return daPath;
	}

	public static function showPopUp(message:String, title:String):Void
	{
		FlxG.sound.music.stop();
		#if android
		AndroidTools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#elseif (!ios || !iphonesim)
		lime.app.Application.current.window.alert(message, title);
		#else
		trace('$title - $message');
		#end
	}

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/$fileName', fileData);
			if (alert)
				showPopUp('$fileName has been saved.', "Success!");
		}
		catch (e:Exception)
			if (alert)
				showPopUp('$fileName couldn\'t be saved.\n(${e.message})', "Error!")
			else
				trace('$fileName couldn\'t be saved. (${e.message})');
	}

	#if android
	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			for (perms in ['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO', 'READ_MEDIA_VISUAL_USER_SELECTED'])
	                        AndroidPermissions.requestPermission(perms);
		else
			for (perms in ['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE'])
			        AndroidPermissions.requestPermission(perms);

		if (!AndroidEnvironment.isExternalStorageManager())
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');

		if ((AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES'))
			|| (AndroidVersion.SDK_INT < AndroidVersionCode.TIRAMISU
				&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')))
			showPopUp('If you accepted the permissions you are all good!\nIf you didn\'t then expect a crash\nPress OK to see what happens', "Warning!");

		try
		{
			if (!FileSystem.exists(getStorageDirectory()))
				FileSystem.createDirectory(getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			showPopUp('Please create directory to\n' + getStorageDirectory(true) + '\nPress OK to close the game', "Error!");
			LimeSystem.exit(1);
		}
	}
	#end

	public static function checkExternalPaths(?splitStorage = false):Array<String>
	{
		var process = new sys.io.Process('grep -o "/storage/....-...." /proc/mounts | paste -sd \',\'');
		var paths:String = process.stdout.readAll().toString();
		if (splitStorage)
			paths = paths.replace('/storage/', '');
		return paths.split(',');
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		var daPath:String = '';
		for (path in checkExternalPaths())
			if (path.contains(externalDir))
				daPath = path;

		daPath = Path.addTrailingSlash(daPath.endsWith("\n") ? daPath.substr(0, daPath.length - 1) : daPath);
		return daPath;
	}
	#end
}
