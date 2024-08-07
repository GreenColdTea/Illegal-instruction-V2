package;

#if android
import android.Tools;
import android.Permissions;
import android.callback.CallBack;
import android.os.Environment;
import android.widget.Toast;
#end
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import openfl.utils.Assets as OpenFlAssets;
import openfl.Lib;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import openfl.system.System;
import lime.system.System as LimeSystem;

/**
 * ...
 * @author: Saw (M.A. Jigsaw)
 */

using StringTools;

class SUtil
{
	#if android
	private static var aDir:String = null; // android dir
	#end

	public static function getPath():String
	{
		#if android
		if (aDir != null && aDir.length > 0)
			return aDir;
		else
			return aDir = Tools.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file') + '/';
		#else
		return '';
		#end
	}

	public static function doTheCheck()
	{
		#if android
		if (!Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE) || !Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE))
		{
                        Permissions.requestPermission([Permissions.READ_EXTERNAL_STORAGE, Permissions.WRITE_EXTERNAL_STORAGE]);
			SUtil.applicationAlert('Permissions', "if you accepted the permissions all good if not expect a crash" + '\n' + 'Press Ok to see what happens');
		}

		if (Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE) || Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE))
		{
			if (!FileSystem.exists(Tools.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file')))
				FileSystem.createDirectory(Tools.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file'));

			if (!FileSystem.exists(SUtil.getPath() + 'assets') && !FileSystem.exists(SUtil.getPath() + 'mods'))
			{
				SUtil.applicationAlert('Uncaught Error :(!', "Whoops, seems you didn't extract the files from the .APK!\nPlease watch the tutorial by pressing OK.");
				CoolUtil.browserLoad('https://youtu.be/zjvkTmdWvfU');
				System.exit(0);
			}
			else
			{
				if (!FileSystem.exists(SUtil.getPath() + 'assets'))
				{
					SUtil.applicationAlert('Uncaught Error :(!', "Whoops, seems you didn't extract the assets/assets folder from the .APK!\nPlease watch the tutorial by pressing OK.");
					CoolUtil.browserLoad('https://youtu.be/zjvkTmdWvfU');
					System.exit(0);
				}

				if (!FileSystem.exists(SUtil.getPath() + 'mods'))
				{
					SUtil.applicationAlert('Uncaught Error :(!', "Whoops, seems you didn't extract the assets/mods folder from the .APK!\nPlease watch the tutorial by pressing OK.");
					CoolUtil.browserLoad('https://youtu.be/zjvkTmdWvfU');
					System.exit(0);
				}
			}
		}
		#end
	}

	public static function getStorageForLogs()
	{
		if (!Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE) || !Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE))
		{
                        Permissions.requestPermission([Permissions.READ_EXTERNAL_STORAGE, Permissions.WRITE_EXTERNAL_STORAGE]);
			SUtil.applicationAlert('Permissions', 'Storage permissions is necessary for writing error logs.' + 'If you arent accepted, the error log wont be written on your device' + '\n' + 'Press Ok to continue');
		}

		if (Permissions.getGrantedPermissions().contains(Permissions.READ_EXTERNAL_STORAGE) || Permissions.getGrantedPermissions().contains(Permissions.WRITE_EXTERNAL_STORAGE))
		{
			if (!FileSystem.exists(Tools.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file'))) {
				FileSystem.createDirectory(Tools.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file'));
			}
		}
	}

	public static function gameCrashCheck()
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
	}

	public static function showPopUp(message:String, title:String):Void
	{
		#if android
		Tools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#elseif (!ios || !iphonesim)
		lime.app.Application.current.window.alert(message, title);
		#else
		trace('$title - $message');
		#end
	}

	public static function onCrash(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var m:String = e.error;
		if (Std.isOfType(e.error, Error)) {
			var err = cast(e.error, Error);
			m = '${err.message}';
		} else if (Std.isOfType(e.error, ErrorEvent)) {
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		var stack = haxe.CallStack.exceptionStack();
		var stackLabelArr:Array<String> = [];
		var stackLabel:String = "";
		for(e in stack) {
			switch(e) {
				case CFunction: stackLabelArr.push("Non-Haxe (C) Function");
				case Module(c): stackLabelArr.push('Module ${c}');
				case FilePos(parent, file, line, col):
					switch(parent) {
						case Method(cla, func):
							stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		stackLabel = stackLabelArr.join('\r\n');
		#if sys
		try
		{
			if (!FileSystem.exists('logs'))
				FileSystem.createDirectory('logs');

			File.saveContent('logs/' + 'Crash - ' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', '$m\n$stackLabel');
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save error message. (${e.message})');
		#end

		showPopUp('$m\n$stackLabel', "Uncaught Error!");

		#if html5
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		js.Browser.window.location.reload(true);
		#else
		System.exit(1);
		#end
	}

	private static function applicationAlert(title:String, description:String)
	{
		Application.current.window.alert(description, title);
	}

	#if android
	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json', fileData:String = 'you forgot something to add in your code')
	{
		if (!FileSystem.exists(SUtil.getPath() + 'saves'))
			FileSystem.createDirectory(SUtil.getPath() + 'saves');

		File.saveContent(SUtil.getPath() + 'saves/' + fileName + fileExtension, fileData);
		SUtil.applicationAlert('Done :)!', 'File Saved Successfully!');
	}

	public static function saveClipboard(fileData:String = 'you forgot something to add in your code')
	{
		openfl.system.System.setClipboard(fileData);
		SUtil.applicationAlert('Done :)!', 'Data Saved to Clipboard Successfully!');
	}

	public static function copyContent(copyPath:String, savePath:String)
	{
		if (!FileSystem.exists(savePath))
			File.saveBytes(savePath, OpenFlAssets.getBytes(copyPath));
	}
	#end
}
