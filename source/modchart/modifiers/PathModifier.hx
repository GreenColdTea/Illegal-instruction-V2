package modchart.modifiers;

import modchart.*;
import flixel.math.FlxMath;
import flixel.FlxG;
import math.Vector3;

typedef PathInfo = {
    var position:Vector3;
    var dist:Float;
    var start:Float;
    var end:Float;
}

class PathModifier extends Modifier {
    var moveSpeed:Float;
    var pathData:Array<Array<PathInfo>> = [];
    var totalDists:Array<Float> = [];

    public function new(modMgr:ModManager, path:Array<Array<Vector3>>, moveSpeed:Float = 5000) {
        super(modMgr);
        this.moveSpeed = moveSpeed;

        for (dir in 0...path.length) {
            totalDists[dir] = 0;
            pathData[dir] = [];

            for (idx in 0...path[dir].length) {
                var pos = path[dir][idx];

                if (idx != 0) {
                    var last = pathData[dir][idx - 1];
                    totalDists[dir] += Vector3.distance(last.position, pos); 
                    last.end = totalDists[dir];
                    last.dist = last.start - totalDists[dir];
                }

                pathData[dir].push({
                    position: pos.add(new Vector3(-Note.swagWidth / 2, -Note.swagWidth / 2)),
                    start: totalDists[dir],
                    end: 0,
                    dist: 0
                });
            }
        }
    }

    override function getPath(visualDiff:Float, pos:Vector3, data:Int, player:Int, timeDiff:Float) {
        if (getPercent(player) == 0 || data >= pathData.length) return pos;

        var totalDist = totalDists[data];
        if (totalDist == 0) return pos;

        var progress = (timeDiff / -moveSpeed) * totalDist;
        var outPos = pos.clone();
        var daPath = pathData[data];

        if (progress <= 0) return pos.lerp(daPath[0].position, getPercent(player));

        for (idx in 0...daPath.length - 1) {
            var cData = daPath[idx];
            var nData = daPath[idx + 1];

            if (progress > cData.start && progress < cData.end) {
                var alpha = (cData.start - progress) / cData.dist;
                var interpPos:Vector3 = cData.position.lerp(nData.position, alpha);
                return pos.lerp(interpPos, getPercent(player));
            }
        }
        return outPos;
    }

    override function getSubmods() {
        return [];
    }
}
