package ashaid.entitybuilder;
import utils.DynamicUtils;
import utils.DynamicMapUtils;
import utils.AshUtils;
import utils.BuildUtils;
import ashaid.componentsbase.CallbackComponent;
import ashaid.componentsbase.EntityStateMachineComponent;
import ashaid.componenthelper.ComponentHelper;

import Reflect;
import haxe.Unserializer;
import minject.Injector;
import openfl.Assets;

import haxe.Json;
import ash.core.System;
import ash.fsm.EntityStateMachine;
import ash.fsm.EngineState;
import ash.fsm.EntityState;
import ash.core.Entity;
import ash.core.Engine;

using utils.AshUtils;
using utils.DynamicMapUtils;
using utils.DynamicUtils;
using Lambda;

class EntityBuilder {


	@inject public var engine:Engine;
	@inject public var injector:Injector;
	var prototypesHash:Map<String, Dynamic>;
	static var hex:EReg = {
	~/0x[\da-zA-Z]+/;
	};

	public function new() {
		prototypesHash = new Map<String, Dynamic>();
	}

// ===================== PROTOTYPES ================

/**
*   Loads prototypes from all json files in assets dir
**/

	public function loadAllProtos():Void {
		var jsons:Array<String> = Unserializer.run(ComponentHelper.getJsonFileNames());
		for (jsonFileName in jsons) {
			addPrototypes(Assets.getText(jsonFileName));
		}
	}

/**
*   Registers prototypes from json description. Each top level element treates as proto. Element's name will give proto name.
**/

	public function addPrototypes(description:String):Void {
		var descrObject = Json.parse(description);
		var protoNames = Reflect.fields(descrObject);
		for (protoName in protoNames) {
			prototypesHash[protoName] = Reflect.field(descrObject, protoName);
		}
	}

/**
*   Returns prototype description given as dynamic structure.
**/

	public function getProtoDescr(name:String):Dynamic {
		if (!prototypesHash.exists(name)) trace("There is no proto with name " + name); // todo -> throw
		return DynamicUtils.clone(prototypesHash[name]);
	}

// ===================== SCENES ================
/**
*   Loads json description from path 'Assets/scenes/' and builds the scene.
**/

	public function buildSceneFromFile(assetFileName:String):Void {
		buildScene(Assets.getText(Paths.SCENES_PATH + assetFileName));
	}


/**
*   Creates entity from each top-level element of the description and adds it to the engine.
*   Description should be consistent with following rules:
*   1. Root element of the scene shoulb be called as 'root'
*   2. Each sub-element's name of the top level should be one of two options: a) the name of component to add, b) keyword
*   3. Substrucure of component's description should use fields which are presented in component's class.
*   Awailable keywords are:
*   name – name of the entity
*   protos – array of names registered protos which wil be added to the entity
**/

	public function buildScene(description:String):Void {
		var descrObject = Json.parse(description);
		var entityDescrs:Array<Dynamic> = Reflect.field(descrObject, "root");
		for (descr in entityDescrs) {
			var entity = buildEntity(descr);
			engine.addEntity(entity);
		}
	}

// ===================== SYSTEMS ================

	public function configureSystemsFromFile(fileName:String):Void {
		var descrObject = Json.parse(Assets.getText(Paths.SYSTEMS_PATH + fileName));
		var fields = Reflect.fields(descrObject);
		for (systemName in fields) {
			var system = ComponentHelper.createInstance(systemName);
			var priority:Int = Std.parseInt(Reflect.field(descrObject, systemName));
			if (!Std.is(priority, Int)) {
				throw "Prioryty for system " + systemName + " should be Int but given " + priority;
			}
			injector.injectInto(system);
			engine.addSystem(system, priority);
		}
	}

	public function makeEngineStateFromFile(fileName:String):EngineState {
		var descrObject = Json.parse(Assets.getText(Paths.SYSTEMS_PATH + fileName));
		return makeEngineStateFromDescription(descrObject);
	}

	public function makeEngineStateFromFiles(fileNames:Array<String>):EngineState {
		var merged = {};
		for (fileName in fileNames) {
			var descrObject = Json.parse(Assets.getText(Paths.SYSTEMS_PATH + fileName));
			merged.merge(descrObject);
		}
		return makeEngineStateFromDescription(merged);
	}

	public function makeEngineStateFromDescription(descrObject:Dynamic):EngineState {
		var state = new EngineState();
		var fields = Reflect.fields(descrObject);
		for (systemName in fields) {
			var system:System;
			var priority:Int = Std.parseInt(Reflect.field(descrObject, systemName));
			if (!Std.is(priority, Int)) {
				throw "Prioryty for system " + systemName + " should be Int but given " + priority;
			}
			if (injector.hasMapping(ComponentHelper.getClass(systemName))) {
				system = injector.getInstance(ComponentHelper.getClass(systemName));
			} else {
				system = ComponentHelper.createInstance(systemName);
				injector.injectInto(system);
				injector.mapValue(ComponentHelper.getClass(systemName), system);
			}
			state.addInstance(system).withPriority(priority);
		}
		return state;
	}

// ===================== ENTITIES ================

	public function buildEntity(typedescr:Dynamic, ?name:String):Entity {
		if (name == null) {
			name = getEntityName(typedescr);
		}
		name = StringTools.replace(name, '.', '');
		var entity:Entity = new Entity(name);
		addComponentsToEntity(entity, typedescr);
		return entity;
	}

	public function addComponentsToEntity(entity:Entity, typedescr:Dynamic):Void {
		var fiealds = Reflect.fields(typedescr);
		var componentClassNames = BuildUtils.getComponentClassNames(typedescr);
		for (componentClassName in componentClassNames) {
			var component:Dynamic = makeComponentForEntity(entity, componentClassName, Reflect.field(typedescr, componentClassName));
			if (Std.is(component, CallbackComponent) && entity.hasComponentWithName(componentClassName)) {
				var targetComponent:CallbackComponent = cast component;
				while (targetComponent.then != null) targetComponent = targetComponent.then;
				targetComponent.then = component;
			} else {
				entity.add(component);
			}
		}
		for (protoName in BuildUtils.getProtosNames(typedescr)) {
			var protoDescr = getProtoDescr(protoName);
			addComponentsToEntity(entity, protoDescr);
		}
	}

	public function addComponentsToState(state:EntityState, typedescr:Dynamic, entity:Entity):Void {
		var fiealds = Reflect.fields(typedescr);
		var componentClassNames = BuildUtils.getComponentClassNames(typedescr);
		for (componentClassName in componentClassNames) {
			var component = makeComponentForEntity(entity, componentClassName, Reflect.field(typedescr, componentClassName));
			state.add(ComponentHelper.getClass(componentClassName)).withInstance(component);
		}
		for (protoName in BuildUtils.getProtosNames(typedescr)) {
			var protoDescr = getProtoDescr(protoName);
			addComponentsToState(state, protoDescr, entity);
		}
	}

	private function createEsmComponent(entity:Entity, name:String, descr:Dynamic):EntityStateMachineComponent {
		var esm = new EntityStateMachine(entity);
		var statesDescr = Reflect.field(descr, "states");
		if (statesDescr == null) throw "Component " + name + " has esm annotation but has no 'states' field";
		for (stateName in Reflect.fields(statesDescr)) {
			var stateDescr = Reflect.field(statesDescr, stateName);
			var state = esm.createState(stateName);
			addComponentsToState(state, stateDescr, entity);
		}
		esm.createState("empty");
		var esmComponent:EntityStateMachineComponent = makeComponent(name, descr);
		esmComponent.entityStateMachine = esm;
		return esmComponent;
	}


	public function makeComponentForEntity(entity:Entity, componentAlias:String, descr:Dynamic):Dynamic {
		if (componentAlias.indexOf(",esm") > 0) {
			var params = componentAlias.split(',');
			var name = params[0];
			var esmComponent = createEsmComponent(entity, name, descr);
			if (params.length > 2) {
				esmComponent.entityStateMachine.changeState(params[2]);
			}
			return esmComponent;
		} else {
			return makeComponent(componentAlias, descr);
		}
	}


	public function makeComponent(componentAlias:String, descr:Dynamic):Dynamic {
		var component = ComponentHelper.createInstance(componentAlias);
		fillComponent(component, descr);
		return component;
	}

	public function fillComponent(instance:Dynamic, params:Dynamic):Void {
		var paramNames = Reflect.fields(params);
		for (field in paramNames) {
			var value:Dynamic = BuildUtils.getValue(Reflect.field(params, field));
			if (field == "then") {
				if (value != null) fillThen(instance, value.copy());
			} else if (field == "states") {
				continue;
			} else if (Std.is(value, String) && cast(value, String).indexOf("entity:") == 0) {
				var name = cast(value, String).substring("entity:".length, value.length);
				var entity = engine.getEntityByName(name);
				if (entity == null) throw "There is no entity with name " + name + " in the engine yet";
				Reflect.setProperty(instance, field, entity);
			} else {
				Reflect.setProperty(instance, field, value);
			}
		}
	}

/*  deffered fill target
if (entity == null) {
	var callback = null;
	 callback = function(entity:Entity) {
		if (entity.name == name) {
			Reflect.setProperty(instance, field, entity);
			engine.entityAdded.remove(callback);
		}
	}
	engine.entityAdded.add(callback);
} else {
	Reflect.setProperty(instance, field, entity);
}
*/


	private function fillThen(component:CallbackComponent, descriptors:Array<Dynamic>):Void {
		var descr = descriptors.shift();
		var descrVal:Dynamic;
		if (Std.is(descr, String) && descr.indexOf("proto:") == 0) {
			var strDescr:String = "" + descr;
			descrVal = getProtoDescr(strDescr.substring(6, strDescr.length));

		} else {
			descrVal = descr;
		}
		var newComponent:CallbackComponent = makeComponent("CallbackComponent", descrVal);
		if (descriptors.length > 0) {
			fillThen(newComponent, descriptors);
		}
		component.then = newComponent;
	}


	public function getEntityName(typedescr:Dynamic):String {
		var dname = Reflect.field(typedescr, "name");
		if (dname != null) {
			return dname;}
		var prefix = Reflect.field(typedescr, "namePrefix");
		if (prefix == null) {
			prefix = "E";
		}
		return prefix + Math.random();
	}

}