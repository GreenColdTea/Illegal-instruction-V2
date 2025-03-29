class HaxelibInstaller {
    static function main() {
        var sysName = Sys.systemName().toLowerCase();
        var path = switch sysName {
            case "windows": "setup/windows/haxelib";
            case "linux", "mac": "setup/android/haxelib";
            default: null;
        }

        if (path != null) {
            Sys.command("haxelib", ["install", path, "--quiet"]);
        } else {
            trace("Unsupported OS: " + sysName);
        }
    }
}
