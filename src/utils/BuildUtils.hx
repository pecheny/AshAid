package utils;
import ash.core.Entity;
using Lambda;

class BuildUtils {
    public static function getComponentClassNames(typedescr:Dynamic):Array<String> {
        var r:EReg = ~/^[A-Z]/;
        return Reflect.fields(typedescr).filter(
            function(fieldName:String):Bool {
                return r.match(fieldName);
            }
        );
    }

    public static function getProtosNames(typedescr:Dynamic):Array<String> {
        if (Reflect.fields(typedescr).has("protos")) {
            var protos = Reflect.field(typedescr, "protos");
            if (!Std.is(protos, Array)) {
                throw "protos is not array of string";
            }
            return protos;
        }
        return new Array<String>();
    }


    public static function getValue(descr:Dynamic):Dynamic {
        if (isPrimitive(descr)) {
            return descr;
        }
        if (Std.is(descr, String)) {
            return parseString(descr);
        }

        return getSafeDynamic(descr);
        throw "Given value is not primitive";
    }

    public static function getSafeDynamic(descr:Dynamic):Dynamic {
        if (Std.is(descr, Array)) {
            return descr;
        }
        var safe = {};
        for (field in Reflect.fields(descr)) {
            var val = Reflect.field(descr, field);
            Reflect.setField(safe, field, getValue(val));
        }
        return safe;
    }

    public static function parseString(s:String):Dynamic {

        if (s.indexOf("randomRange") == 0) {
            var args = s.split(",");
            return getRandom(Std.parseInt(args[1]), Std.parseInt(args[2]));
        } else if (s.indexOf("randomSet") == 0) {
            var args = s.split(",");
            args.shift();
            return args[getRandom(0, args.length)];
        } else if (s.indexOf("0x") == 0) {
            return Std.parseInt(s);
        } else if (s.indexOf("value2fun") == 0) {
            var args = s.split(",");
            var val = Std.parseInt(args[1]);
            return function(e:Entity, ?e2:Entity) {
                return val;
            }
        }
        return s;
    }

    public static function getRandom(min:Int, max:Int):Int {
        var range = max - min;
        return Std.random(range) + min;
    }

    public static function isPrimitive(val:Dynamic):Bool {
        return Std.is(val, Float) || Std.is(val, Bool);
    }

}