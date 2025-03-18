package modchart;

import flixel.tweens.FlxEase.EaseFunction;

class BaseEvent {
    public var manager:ModManager;
    public var executionStep:Float = 0;
    public var ignoreExecution:Bool = false;
    public var finished:Bool = false;
    public function new(step:Float, manager:ModManager)
    {
	   this.manager = manager;
	   this.executionStep = step;
    }

    public function run(curStep:Float){}
}

class CallbackEvent extends BaseEvent {
	public var callback:(CallbackEvent, Float)->Void;
	public function new(step:Float, callback:(CallbackEvent, Float)->Void, modMgr:ModManager)
	{
		super(step, modMgr);
		this.callback = callback;
	}

    override function run(curStep:Float){
        callback(this, curStep);
		finished = true;
    }
}

class FuncEvent extends BaseEvent {
  public var callback:Void->Void;

  public function new(step:Float,callback:Void->Void,modMgr:ModManager){
    super(step, modMgr);
    this.callback = callback;
    this.executionStep = step;
  }

  override function run(curStep:Float){
    if(curStep >= executionStep){
      callback();
      finished = true;
    }
  }
}

class ModEvent extends BaseEvent {
  public var modName:String = '';
  public var endPercent:Float = 0;
  public var player:Int = -1;

  private var mod:Modifier;

  public function getPreviousPercent() {
    return manager.getPreviousWithEvent(this).endPercent;
  }

  public function getCurrentPercent() {
    return manager.getLatestWithEvent(this).endPercent;
  }

  public function new(step:Float, modName:String, target:Float, player:Int=-1, modMgr:ModManager) {
    super(step, modMgr);
    this.modName = modName;
    this.player = player;
    endPercent = target;
    this.mod = manager.get(modName);
  }
}

class EaseEvent extends ModEvent {
  public var easeFunction:EaseFunction;
  public var endStep:Float = 0;
  public var length:Float = 0;
  public var startPercent:Null<Float> = 0;

  public function new(step:Float, endStep:Float, modName:String, target:Float, ease:EaseFunction, player:Int=-1, modMgr:ModManager, ?startVal:Float){
    super(step, modName, target, player, modMgr);
    this.executionStep = step;
    this.endStep = endStep;
    this.easeFunction = ease;
    this.length = endStep - executionStep;
    this.startPercent = startVal; // getCurrentPercent();
  }

  function ease(t:Float, b:Float, c:Float, d:Float) { // elapsed, begin, change (ending-beginning), duration
    var time = t / d;
    return c * easeFunction(time) + b;
  }

  override function run(curStep:Float) {
    if (curStep >= executionStep && curStep <= endStep) {
      if (this.startPercent == null) {
        this.startPercent = mod.getPercent(player) * 100;
      }
      var passed = curStep - executionStep;
      var change = endPercent - startPercent;
      mod.setPercent(
        ease(passed, startPercent, change, length),
        player
      );
    } else if (curStep > endStep) {
      finished = true;
      mod.setPercent(endPercent, player);
    }
  }
}

class SetEvent extends ModEvent {
  override function run(curStep:Float) {
    if (curStep >= executionStep) {
      mod.setPercent(endPercent, player);
      finished = true;
    }
  }
}

class StepCallbackEvent extends CallbackEvent {
  public var endStep:Float = 0;

  public function new(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void, modMgr:ModManager) {
    super(step, callback, modMgr);
    this.executionStep = step;
    this.endStep = endStep;
  }

  override function run(curStep:Float) {
    if (curStep <= endStep)
      callback(this, curStep);
    else
      finished = true;
  }
}
