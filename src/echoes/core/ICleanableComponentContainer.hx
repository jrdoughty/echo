package echoes.core;

interface ICleanableComponentContainer {
    function exists(id:Int):Bool;
    function remove(id:Int):Void;
    function reset():Void;
    function print(id:Int):String;
    function type(id:Int):String;
    function getAsAny(id:Int):Any;
    function addAsAny(id:Int,c:Any):Void;
}
