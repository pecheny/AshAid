package callback;
using Lambda;
class CallbackUtils {

    public static inline var TIME:String = "time";
    public static inline var THIS:String = "this";
    public static inline var SYSTEM_TARGET:String = "systemTarget";


    public static inline function fillThis(callbackComponent:ICallbackComponent, argValue:Dynamic):Void {
        fillArg(callbackComponent, THIS, argValue);
    }

    public static inline function fillTime(callbackComponent:ICallbackComponent, argValue:Dynamic):Void {
        fillArg(callbackComponent, TIME, argValue);
    }

    public static inline function fillTarget(callbackComponent:ICallbackComponent, argValue:Dynamic):Void {
        fillArg(callbackComponent, SYSTEM_TARGET, argValue);
    }

    public static inline function fillArg(callbackComponent:ICallbackComponent, argName:String, argValue:Dynamic):Void {
        if (callbackComponent.argKeys == null) {
            callbackComponent.argKeys = [];
        }
        var index = callbackComponent.argKeys.indexOf(argName);
        if (index > -1) {
            if (callbackComponent.args == null) callbackComponent.args = [];
            callbackComponent.args[index] = argValue;
        }
        if (callbackComponent.then != null) {
            fillArg(callbackComponent.then, argName, argValue);
        }
    }

    public static function addCallback(targetCallbackComponent:ICallbackComponent, callbackComponent:CallbackComponent):Void {
        while (targetCallbackComponent.then != null) {
            targetCallbackComponent = targetCallbackComponent.then;
        }
        targetCallbackComponent.then = callbackComponent;
    }

}