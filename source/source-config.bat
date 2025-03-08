@echo off
cls
title Illegal Instruction Necessary Libraries Installer
echo.
echo Installing necessary libraries. Please wait...
echo.
haxelib setup C:\haxelib
haxelib git openfl https://github.com/MobilePorting/openfl 9.3.4 > /dev/null --quiet
haxelib git flixel https://github.com/MobilePorting/flixel 5.6.1 --never --quiet
haxelib git lime https://github.com/MobilePorting/lime.git > /dev/null --quiet
haxelib git hxcpp https://github.com/MobilePorting/hxcpp > /dev/null
haxelib run lime setup flixel --quiet
haxelib install flixel-tools 1.5.1 --quiet
haxelib install flixel-ui 2.6.3 --quiet
haxelib install flixel-addons 3.2.3 --quiet
haxelib install tjson --quiet
haxelib install hxjsonast --quiet
haxelib install hscript 2.4.0 --quiet
haxelib git hxvlc https://github.com/GreenColdTea/hxvlc --quiet --skip-dependencies
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc --quiet
haxelib git linc_luajit https://github.com/MobilePorting/linc_luajit.git --quiet
haxelib list
echo.
echo Setting current library versions...
echo.
haxelib set flixel-tools 1.5.1
haxelib set flixel-ui 2.6.3
haxelib set flixel-addons 3.2.3
haxelib set hscript 2.4.0
echo.
echo Done! Press any key to close the app!
pause
