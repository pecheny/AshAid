package ashaid.componenthelper;
import haxe.Unserializer;
import haxe.Serializer;
import haxe.macro.Context;
import haxe.Json;
using StringTools;
using utils.StringMapUtils;
using utils.DynamicMapUtils;
using haxe.macro.Tools;

class ComponentHelper {
    public static var hash:Map<String, String> = {
         Unserializer.run(getClassesHash());
    };


    public static function createInstance(className:String):Dynamic {
        return Type.createInstance(getClass(className), []);
    }

    public static function getClass(className:String):Class<Dynamic> {
        var fullClassName:String = hash[className];
        return Type.resolveClass(fullClassName);
    }

#if macro
    public static function getFullClassPath(name:String, path:String = ".") {
        var files = sys.FileSystem.readDirectory(path);
        for (file in files) {
            var filePath = path + "/" + file;
            if (sys.FileSystem.isDirectory(filePath)) {
                var newPath = getFullClassPath(name, filePath);
                if (newPath != "")
                    return newPath;
            } else {
                if (file == name + ".hx") {
                    return filePath;
                }
            }
        }
        return "";
    }

    public static function getJsons():Array<String> {
        var out = new Array<String>();
        getJsonsInDir("Assets", out);
        return out;
    }

    private static function getJsonsInDir(dir:String, out:Array<String>):Void {
        var files = sys.FileSystem.readDirectory(dir);
        for (file in files) {
            if (file.indexOf(".json") > -1) {
                out.push(dir + "/" + file);
            } else if (sys.FileSystem.isDirectory(dir + "/" + file)) {
                getJsonsInDir(dir + "/" + file, out);
            }
        }
    }


    public static function getClassesHashForDirectory(path:String, ?implementing:String):Map<String, String> {
        var classHash = new Map<String, String>();
        var files = sys.FileSystem.readDirectory(path);
        for (file in files) {
            var filePath = path + "/" + file;
            if (sys.FileSystem.isDirectory(filePath)) {
                var newMap = getClassesHashForDirectory(filePath, implementing);
                classHash.add(newMap);
            } else {
                if (file.indexOf(".hx") > -1) {
                    if (implementing == null || isImplementing(filePath, implementing)) {
                        classHash[getShortClassName(file)] = getFullClassName(filePath);
                    }
                }
            }
        }
        return classHash;
    }

    private static function isImplementing(pathToClass:String, interfaceName:String):Bool {
        var cont = sys.io.File.getContent(pathToClass);
        return cont.indexOf("implements " + interfaceName) > -1; // todo make this condition more strict
    }

    private static function getShortClassName(fileName:String):String {
        fileName = fileName.replace(".hx", "");
        return fileName;
    }

    static function getFullClassName(name:String) {
        var path:String = name;
        path = path.replace("./src/", "");
        path = path.replace("/", ".");
        path = path.replace(".hx", "");
        return path;
    }

    static private function storeImports(s:String):Void {
        sys.io.File.saveContent("./src/Imports.hx", s);
    }

#end

    macro public static function getClassesHash(?implementing:String):ExprOf<Map<String, String>> {
        return Context.makeExpr(Serializer.run(getClassesHashForDirectory("./src", implementing)), Context.currentPos());
    }

    macro public static function getJsonFileNames() {
        return Context.makeExpr(Serializer.run(getJsons()), Context.currentPos());
    }


	macro public static function importAll() {
        for (className in hash) {
            Context.getModule(className);
        }
        return Context.makeExpr("", Context.currentPos());
    }

    macro public static function importSystems() {
        var hash = getClassesHashForDirectory("./" + Paths.SOURCES_PATH);
		var files = sys.FileSystem.readDirectory("./" +Paths.SYSTEMS_PATH);
		for (file in files) {
			if(file.indexOf(".json") < 0) continue;
            var filePath = "./" +Paths.SYSTEMS_PATH + "/" + file;
            var json = Json.parse(sys.io.File.getContent(filePath));
	        for (field in Reflect.fields(json)) {
	            var path:String = hash[field];
	            Context.getModule(hash[field]);
	        }
		}
        return Context.makeExpr("", Context.currentPos());
    }

    macro public static function getDirList() {
        var date = sys.FileSystem.readDirectory(".");
        return Context.makeExpr(date, Context.currentPos());
    }



}
