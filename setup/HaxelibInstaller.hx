class HaxelibInstaller {
    static function main() {
        var platform = Sys.systemName().toLowerCase();
        var path = "setup/" + (platform == "windows" ? "windows" : "android") + "/haxelib.json";
        Sys.command("haxelib install " + path + " --quiet");
    }
}
