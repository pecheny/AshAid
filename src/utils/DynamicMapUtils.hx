package utils;
class DynamicMapUtils {
    public static function add(target:Map<String, Dynamic>, source:Map<String, Dynamic>):Void {
           for (key in source.keys()) {
             target[key] = source[key];
           }
       }
}