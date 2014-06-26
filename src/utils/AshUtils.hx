package utils;
import ash.core.System;
import ash.core.Engine;
//import countdown.CountdownComponent;
import ash.core.Entity;
class AshUtils {
    public static inline function getOrCreate(entity:Entity, type:Class<Dynamic>):Dynamic {
        if (entity.has(type)) {
            return entity.get(type);
        } else {
            var instance = Type.createInstance(type, []);
            entity.add(instance);
            return instance;
        }
    }

    public static function getComponentByName(entity:Entity, name:String):Dynamic {
        for (component in entity.components) {
            var fullName = Type.getClassName(Type.getClass(component));
            var parts = fullName.split('.');
            if (parts[parts.length - 1] == name) {
                return component;
            }
        }
        throw "There is no " + name + " on entity " + entity.name;
    }

    public static function hasComponentWithName(entity:Entity, name:String):Bool {
        for (component in entity.components) {
            var fullName = Type.getClassName(Type.getClass(component));
            var parts = fullName.split('.');
            if (parts[parts.length - 1] == name) {
                return true;
            }
        }
        return false;
    }

    public static function removeComponentByName(entity:Entity, name:String):Dynamic {
        for (component in entity.components) {
            var type = Type.getClass(component);
            var fullName = Type.getClassName(type);
            var parts = fullName.split('.');
            if (parts[parts.length - 1] == name) {
                return entity.remove(type);
            }
        }
        throw "There is no " + name + " on entity " + entity.name;
    }

    public static function getSystemByName(engine:Engine, systemName:String):System {
        for (system in engine.systems) {
            var fullName = Type.getClassName(Type.getClass(system));
            var parts = fullName.split('.');
            if (parts[parts.length - 1] == systemName) {
                return system;
            }
        }
        throw "There is no " + systemName + " in the engine";
    }

   /* public static function addDeffered(entity:Entity, component:Dynamic, delay:Float):Void {
        var targetComponent:CountdownComponent = CountdownComponent.fromLifetime(delay / 1000);
        targetComponent.callbackName = "addComponent";
        targetComponent.args = [entity, component];
        if (entity.has(CountdownComponent)) {
            var countdownComponent:CountdownComponent = entity.get(CountdownComponent);
            while (countdownComponent.next != null) countdownComponent = countdownComponent.next;
            countdownComponent.next = targetComponent;
        } else {
            entity.add(targetComponent);
        }

    }*/

}