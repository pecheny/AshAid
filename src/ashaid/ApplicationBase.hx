package ashaid;
import ashaid.componenthelper.ComponentHelper;
import flash.Lib;
import flash.events.Event;
import ashaid.entitybuilder.EntityBuilder;
import ash.core.Engine;
import minject.Injector;
import flash.display.Sprite;
class ApplicationBase extends Sprite {
	inline static var MAX_ELAPSED = 0.0333;

	public static var timeMultiplier:Float = 1;
	public var entityBuilder:EntityBuilder;

	var injector:Injector;
	var engine:Engine;
	var last:Int;

	public function new() {
		super();
		injector = new Injector();
		injector.mapValue(Injector, injector);
		engine = createSingleton(Engine);
		entityBuilder = createSingleton(EntityBuilder);
		ComponentHelper.importSystems();
		addEventListener(Event.ENTER_FRAME, enterFrameHandler);
	}

	private function enterFrameHandler(e:Event):Void {
		var time = Lib.getTimer();
		var elapsed = (time - last) / 1000;
		if (elapsed > MAX_ELAPSED) elapsed = MAX_ELAPSED;
		last = time;
		engine.update(elapsed * timeMultiplier);
	}

	private function createSingleton(c1ass:Class<Dynamic>, ?args:Array<Dynamic>):Dynamic {
		if (args == null) {
			args = [];
		}
		var instance = injector.instantiate(c1ass);
		injector.mapValue(c1ass, instance);
		return instance;
	}


}