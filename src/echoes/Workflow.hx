package echoes;

import echoes.Entity.Status;
import echoes.core.AbstractView;
import echoes.core.ICleanableComponentContainer;
import echoes.core.ISystem;
import echoes.core.RestrictedLinkedList;
import haxe.Serializer;
import haxe.Unserializer;
//import serialization.WorkflowData;

/**
 *  Workflow  
 * 
 * @author https://github.com/deepcake
 */
class Workflow {


    @:allow(echoes.Entity) static inline var INVALID_ID = -1;


    static var nextId = INVALID_ID + 1;

    static var idPool = new Array<Int>();

    static var statuses = new Array<Status>();

    // all of every defined component container
    static var definedContainers = new Array<ICleanableComponentContainer>();
    // all of every defined view
    static var definedViews = new Array<AbstractView>();

    /**
     * All active entities
     */
    public static var entities(default, null) = new RestrictedLinkedList<Entity>();
    /**
     * All active views
     */
    public static var views(default, null) = new RestrictedLinkedList<AbstractView>();

    /**
     * All systems that will be called when `update()` is called
     */
    public static var systems(default, null) = new RestrictedLinkedList<ISystem>();


    #if echoes_profiling
    static var updateTime = .0;
    #end


    /**
     * Returns the workflow statistics:  
     * _( systems count ) { views count } [ entities count | entity cache size ]_  
     * With `echoes_profiling` flag additionaly returns:  
     * _( system name ) : time for update ms_  
     * _{ view name } [ collected entities count ]_  
     * @return String
     */
    public static function info():String {
        var ret = '# ( ${systems.length} ) { ${views.length} } [ ${entities.length} | ${idPool.length} ]'; // TODO version or something

        #if echoes_profiling
        ret += ' : $updateTime ms'; // total
        for (s in systems) {
            ret += '\n${ s.info('    ', 1) }';
        }
        for (v in views) {
            ret += '\n    {$v} [${ v.entities.length }]';
        }
        #end

        return ret;
    }


    /**
     * Update 
     * @param dt deltatime
     */
    public static function update(dt:Float) {
        #if echoes_profiling
        var timestamp = Date.now().getTime();
        #end

        for (s in systems) {

            s.__update__(dt);

        }

        #if echoes_profiling
        updateTime = Std.int(Date.now().getTime() - timestamp);
        #end
    }


    /**
     * Draw 
     */
    public static function draw() {
        for (s in systems) {
            s.__draw__();
        }
    }


    /**
     * Removes all views, systems and entities from the workflow, and resets the id sequence 
     */
    public static function reset() {
        for (e in entities) {
            e.destroy();
        }
        for (s in systems) {
            removeSystem(s);
        }
        for (v in definedViews) {
            v.reset();
        }
        for (c in definedContainers) {
            c.reset();
        }

        idPool.splice(0, idPool.length);
        statuses.splice(0, statuses.length);

        nextId = INVALID_ID + 1;
    }


    // System

    /**
     * Adds the system to the workflow
     * @param s `System` instance
     */
    public static function addSystem(s:ISystem) {
        if (!hasSystem(s)) {
            systems.add(s);
            s.__activate__();
        }
    }

    /**
     * Removes the system from the workflow
     * @param s `System` instance
     */
    public static function removeSystem(s:ISystem) {
        if (hasSystem(s)) {
            s.__deactivate__();
            systems.remove(s);
        }
    }

    /**
     * Returns `true` if the system is added to the workflow, otherwise returns `false`  
     * @param s `System` instance
     * @return `Bool`
     */
    public static function hasSystem(s:ISystem):Bool {
        return systems.exists(s);
    }


    // Entity

    @:allow(echoes.Entity) static function id(immediate:Bool):Int {
        var id = idPool.pop();

        if (id == null) {
            id = nextId++;
        }

        if (immediate) {
            statuses[id] = Active;
            entities.add(id);
        } else {
            statuses[id] = Inactive;
        }
        return id;
    }

    /**
     * Returns `Entity` if the id is added to the workflow, otherwise returns `false` if its in the cache or active entities 
     * @param id `Int` entityID
     * @param immediate `Bool` should it be made active immediately
     * @return `Bool`
     */
    public static function inject(id:Int):Entity {
        if (nextId <= id) { //ensures you don't get a conflict as you count up
            nextId = id + 1;
        }
        statuses[id] = Active;
        entities.add(id);
        return cast(id, Entity);
    }

    @:allow(echoes.Entity) static function cache(id:Int) {
        // Active or Inactive
        if (status(id) < Cached) {
            removeAllComponentsOf(id);
            entities.remove(id);
            idPool.push(id);
            statuses[id] = Cached;
        }
    }

    @:allow(echoes.Entity) static function add(id:Int) {
        if (status(id) == Inactive) {
            statuses[id] = Active;
            entities.add(id);
            for (v in views) v.addIfMatched(id);
        }
    }

    @:allow(echoes.Entity) static function remove(id:Int) {
        if (status(id) == Active) {
            for (v in views) v.removeIfExists(id);
            entities.remove(id);
            statuses[id] = Inactive;
        }
    }

    @:allow(echoes.Entity) static inline function status(id:Int):Status {
        return statuses[id];
    }

    @:allow(echoes.Entity) static inline function removeAllComponentsOf(id:Int) {
        if (status(id) == Active) {
            for (v in views) {
                v.removeIfExists(id);
            }
        }
        for (c in definedContainers) {
            c.remove(id);
        }
    }

    @:allow(echoes.Entity) static inline function printAllComponentsOf(id:Int):String {
        var ret = '#$id:';
        for (c in definedContainers) {
            if (c.exists(id)) {
                ret += '${ c.print(id) },';
            }
        }
        return ret.substr(0, ret.length - 1);
    }

    @:allow(echoes.Entity) static inline function printAllComponentTypesOf(id:Int):String {
        var ret = '#$id:';
        for (c in definedContainers) {
            if (c.exists(id)) {
                ret += '${ c.getAsAny(id) },';
            }
        }
        return ret.substr(0, ret.length - 1);
    }

    @:allow(echoes.Entity) static inline function allComponentOf(id:Int):Array<Any> {
        var ret = [];
        for (c in definedContainers) {
            if (c.exists(id)) {
                ret.push(c.getAsAny(id));
            }
        }
        return ret;
    }
    public static function save():String
    {
        var map = new Map<Int, Map<String,Any>>();
        for(i in Workflow.entities)
        {
            map.set(i,new Map<String,Any>());
            var types = i.compTypes();
            for(j in i.getComps())
            { 
                map.get(i).set(Type.getClassName(Type.getClass(j)),j);
            }

        }
        
        //trace(map);
        var seri = new haxe.Serializer();
        seri.serialize(map);
        return(seri.toString());   
    }
    public static function load(startString:String)
    {   
        var u = new haxe.Unserializer(startString);
        var eMap:Map<Int, Map<String,Any>> = cast u.unserialize();
        //trace(eMap);

        for(i in eMap.keys())
        {
            var e = Workflow.inject(i);
            trace(e);
            for(j in eMap[i].keys())
            {
                for(cont in definedContainers)
                {
                    if(j == cont.type(i))
                    {
                        cont.addAsAny(i,eMap[i][j]);
                        break;
                    }
                }
            }
        }
        
        //var d = new WorkflowData();
        
    }
}
