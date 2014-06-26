package utils;
class DynamicUtils {
	public static function merge(target:Dynamic, source:Dynamic):Void {
		for (field in Reflect.fields(source)) {
			Reflect.setField(target, field, Reflect.field(source, field));
		}
	}

	public static function recursiveGetField(descr:Dynamic, path:String):Dynamic {
		var elementNames = path.split('.');
		var firstName:String = elementNames[0];
		var element = Reflect.field(descr, firstName);
		if (elementNames.length > 1) {
			var newPath = path.substring(firstName.length + 1, path.length);
			return recursiveGetField(element, newPath);
		} else {
			return element;
		}
	}

	public static function mergeCallbacks(descr1:Dynamic, descr2:Dynamic):Dynamic {
		var fields = Reflect.fields(descr1);
		var then:Array<Dynamic> = [];
		if (fields.indexOf('then') > -1) {
			then = cast Reflect.field(descr1, 'then');
		}
		var fields = Reflect.fields(descr2);
		if (fields.indexOf('then') > -1) {
			then = then.concat(cast Reflect.field(descr2, 'then'));
			Reflect.setField(descr2, 'then', []);
		}
		then.push(descr2);
		Reflect.setField(descr1, 'then', then);
		return descr1;
	}

	public static function recurciveTrace(descr:Dynamic):Void {
		if (Std.is(descr, String) || Std.is(descr, Bool) || Std.is(descr, Float)) {
			trace(descr);
		} else if (Std.is(descr, Array)) {
			var array:Array<Dynamic> = cast descr;
			for (val in array) {
				trace(val);
			}
		} else {
			var keys = Reflect.fields(descr);
			for (key in keys) {
				trace(key + " : {");
				recurciveTrace(Reflect.field(descr, key));
				trace("}");
			}
		}
	}

	public static function clone(descr:Dynamic):Dynamic {

		if (Std.is(descr, String) || Std.is(descr, Bool) || Std.is(descr, Float)) {
			return descr;
		} else if (Std.is(descr, Array)) {
			var source:Array<Dynamic> = cast descr;
			var array:Array<Dynamic> = [];
			for (val in source) {
				array.push(clone(val));
			}
			return array;
		} else {
			var out = {};
			for (field in Reflect.fields(descr)) {
				var val = Reflect.field(descr, field);
				Reflect.setField(out, field, clone(val));
			}
			return out;
		}
	}
}