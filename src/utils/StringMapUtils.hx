package utils;
class StringMapUtils {
    public static function add(target:Map<String, String>, source:Map<String, String>):Void {
           for (key in source.keys()) {
             target[key] = source[key];
           }
       }
}