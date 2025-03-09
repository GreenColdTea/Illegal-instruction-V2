package modchart;
// @author Riconats, ported by GreenColdTea

import funkin.objects.playfields.NoteField;
import math.Vector3;

class HScriptModifier extends Modifier {
	public var script:HScript;
	public var name:String = "unknown";

	public function new(modMgr:ModManager, ?parent:Modifier, script:HScript) {
		this.script = script;
		this.modMgr = modMgr;
		this.parent = parent;

		script.interp.variables.set("this", this);
		script.interp.variables.set("modMgr", this.modMgr);
		script.interp.variables.set("parent", this.parent);
		script.interp.variables.set("getValue", getValue);
		script.interp.variables.set("getPercent", getPercent);
		script.interp.variables.set("getSubmodValue", getSubmodValue);
		script.interp.variables.set("getSubmodPercent", getSubmodPercent);
		script.interp.variables.set("setValue", setValue);
		script.interp.variables.set("setPercent", setPercent);
		script.interp.variables.set("setSubmodValue", setSubmodValue);
		script.interp.variables.set("setSubmodPercent", setSubmodPercent);

		script.interp.execute(HScript.parser.parseString("onCreate()"));

		super(this.modMgr, this.parent);

		script.interp.execute(HScript.parser.parseString("onCreatePost()"));
	}

	@:noCompletion
	private static final _scriptEnums:Map<String, Dynamic> = [
		"NOTE_MOD" => NOTE_MOD,
		"MISC_MOD" => MISC_MOD,
		"FIRST" => FIRST,
		"PRE_REVERSE" => PRE_REVERSE,
		"REVERSE" => REVERSE,
		"POST_REVERSE" => POST_REVERSE,
		"DEFAULT" => DEFAULT,
		"LAST" => LAST
	];

	public static function fromString(modMgr:ModManager, ?parent:Modifier, scriptSource:String):HScriptModifier {
		return new HScriptModifier(
			modMgr,
			parent,
			new HScript()
		);
	}

	public static function fromName(modMgr:ModManager, ?parent:Modifier, scriptName:String):Null<HScriptModifier> {
		var filePath:String = Paths.getHScriptPath('modifiers/$scriptName');
		if (filePath == null) {
			trace('Modifier script: $scriptName not found!');
			return null;
		}

		var script = new HScript();
		script.interp.execute(HScript.parser.parseFile(filePath));

		var mod = new HScriptModifier(modMgr, parent, script);
		mod.name = scriptName;
		return mod;
	}

	override public function getModType() return script.interp.variables.exists("getModType") ? script.interp.execute(HScript.parser.parseString("getModType()")) : super.getModType();

	override public function ignorePos() return script.interp.variables.exists("ignorePos") ? script.interp.execute(HScript.parser.parseString("ignorePos()")) : super.ignorePos();

	override public function ignoreUpdateReceptor() return script.interp.variables.exists("ignoreUpdateReceptor") ? script.interp.execute(HScript.parser.parseString("ignoreUpdateReceptor()")) : super.ignoreUpdateReceptor();

	override public function ignoreUpdateNote() return script.interp.variables.exists("ignoreUpdateNote") ? script.interp.execute(HScript.parser.parseString("ignoreUpdateNote()")) : super.ignoreUpdateNote();

	override public function doesUpdate() return script.interp.variables.exists("doesUpdate") ? script.interp.execute(HScript.parser.parseString("doesUpdate()")) : super.doesUpdate();

	override public function shouldExecute(player:Int, value:Float):Bool
		return script.interp.variables.exists("shouldExecute") ? script.interp.execute(HScript.parser.parseString("shouldExecute($player, $value)")) : super.shouldExecute(player, value);

	override public function getOrder():Int
		return script.interp.variables.exists("getOrder") ? script.interp.execute(HScript.parser.parseString("getOrder()")) : super.getOrder();

	override public function getName():String
		return script.interp.variables.exists("getName") ? script.interp.execute(HScript.parser.parseString("getName()")) : name;

	override public function getSubmods():Array<String>
		return script.interp.variables.exists("getSubmods") ? script.interp.execute(HScript.parser.parseString("getSubmods()")) : super.getSubmods();

	override public function updateReceptor(beat:Float, receptor:StrumNote, player:Int)
		return script.interp.variables.exists("updateReceptor") ? script.interp.execute(HScript.parser.parseString("updateReceptor($beat, $receptor, $player)")) : super.updateReceptor(beat, receptor, player);

	override public function updateNote(beat:Float, note:Note, player:Int)
		return script.interp.variables.exists("updateNote") ? script.interp.execute(HScript.parser.parseString("updateNote($beat, $note, $player)")) : super.updateNote(beat, note, player);

	override public function getPos(diff:Float, tDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:NoteObject, field:NoteField):Vector3
		return script.interp.variables.exists("getPos") ? script.interp.execute(HScript.parser.parseString("getPos($diff, $tDiff, $beat, $pos, $data, $player, $obj, $field)")) : super.getPos(diff, tDiff, beat, pos, data, player, obj, field);

	override public function modifyVert(beat:Float, vert:Vector3, idx:Int, obj:NoteObject, pos:Vector3, player:Int, data:Int, field:NoteField):Vector3
		return script.interp.variables.exists("modifyVert") ? script.interp.execute(HScript.parser.parseString("modifyVert($beat, $vert, $idx, $obj, $pos, $player, $data, $field)")) : super.modifyVert(beat, vert, idx, obj, pos, player, data, field);

	override public function getExtraInfo(diff:Float, tDiff:Float, beat:Float, info:RenderInfo, obj:NoteObject, player:Int, data:Int):RenderInfo
		return script.interp.variables.exists("getExtraInfo") ? script.interp.execute(HScript.parser.parseString("getExtraInfo($diff, $tDiff, $beat, $info, $obj, $player, $data)")) : super.getExtraInfo(diff, tDiff, beat, info, obj, player, data);

	override public function update(elapsed:Float, beat:Float)
		return script.interp.variables.exists("update") ? script.interp.execute(HScript.parser.parseString("update($elapsed, $beat)")) : super.update(elapsed, beat);

	override public function isRenderMod():Bool
		return script.interp.variables.exists("isRenderMod") ? script.interp.execute(HScript.parser.parseString("isRenderMod()")) : super.isRenderMod();
}
