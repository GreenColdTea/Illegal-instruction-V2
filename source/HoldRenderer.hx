package;

import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import PlayState;
import Note;
import StrumNote;
import Conductor;
import ClientPrefs;

class HoldRenderer extends FlxSprite {
    public var strumGroup:FlxTypedGroup<StrumNote>;
    public var notes:FlxTypedGroup<Note>;
    public var playfields:Array<Playfield> = [];
    public var speed:Float = 1.0;
    public var inEditor:Bool = false;

    public function new(strumGroup:FlxTypedGroup<StrumNote>, notes:FlxTypedGroup<Note>) {
        super(0, 0);
        this.strumGroup = strumGroup;
        this.notes = notes;

        strumGroup.visible = false;
        notes.visible = false;

        addNewPlayfield();
    }

    public function addNewPlayfield(?x:Float = 0, ?y:Float = 0, ?z:Float = 0, ?alpha:Float = 1) {
        playfields.push(new Playfield(x, y, z, alpha));
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
    }

    override public function draw() {
        if (alpha == 0 || !visible) return;
        drawStuff(getNotePositions());
    }

    private function getNotePositions() {
        var notePositions:Array<NotePositionData> = [];
        for (pf in 0...playfields.length) {
            for (i in 0...strumGroup.members.length) {
                var strumData = getDataForStrum(i, pf);
                notePositions.push(strumData);
            }
            for (i in 0...notes.members.length) {
                var curPos = getNoteCurPos(i);
                var noteData = createDataFromNote(i, pf, curPos);
                notePositions.push(noteData);
            }
        }
        notePositions.sort((a, b) -> Std.int(a.z - b.z));
        return notePositions;
    }

    private function getDataForStrum(i:Int, pf:Int) {
        var strumData = NotePositionData.get();
        strumData.setupStrum(FlxG.width / 2, FlxG.height - 100, 0, i, 1, 1, pf);
        return strumData;
    }

    private function createDataFromNote(noteIndex:Int, playfieldIndex:Int, curPos:Float) {
        var noteData = NotePositionData.get();
        noteData.setupNote(0, 0, 0, noteIndex % 4, 1, 1, playfieldIndex, 1, curPos, 0, 0, 0, notes.members[noteIndex].strumTime, noteIndex);
        return noteData;
    }

    private function getNoteCurPos(noteIndex:Int) {
        var distance = Conductor.songPosition - notes.members[noteIndex].strumTime;
        return distance * getCorrectScrollSpeed();
    }

    private function getCorrectScrollSpeed() {
        return PlayState.instance.SONG.speed;
    }

    private function drawStuff(notePositions:Array<NotePositionData>) {
        for (noteData in notePositions) {
            if (noteData.isStrum)
                drawStrum(noteData);
            else if (!notes.members[noteData.index].isSustainNote)
                drawNote(noteData);
        }
    }

    private function drawStrum(noteData:NotePositionData) {
        if (noteData.alpha <= 0) return;
        var strum = strumGroup.members[noteData.index];
        strum.setPosition(noteData.x, noteData.y);
        strum.draw();
    }

    private function drawNote(noteData:NotePositionData) {
        if (noteData.alpha <= 0) return;
        var note = notes.members[noteData.index];
        note.setPosition(noteData.x, noteData.y);
        note.draw();
    }
}
