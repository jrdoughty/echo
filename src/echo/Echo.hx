package echo;
#if macro
import echo.macro.MacroBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
using haxe.macro.Context;
using echo.macro.Macro;
#end

using Lambda;

/**
 * ...
 * @author octocake1
 */
class Echo {
	
	
	@:noCompletion static public var __SEQUENCE = 0;
	
	
	public var entities:List<Int>;
	
	public var views:Array<View>;
	public var systems:Array<System>;
	
	
	public function new() {
		entities = new List();
		views = [];
		systems = [];
	}
	
	
	public function update(dt:Float) {
		for (s in systems) s.update(dt);
	}
	
	
	// System
	
	public function addSystem(s:System) {
		s.activate(this);
		systems.push(s);
	}
	
	public function removeSystem(s:System) {
		s.deactivate();
		systems.remove(s);
	}
	
	
	// View
	
	public function addView(v:View) {
		v.activate(this);
		views.push(v);
	}
	
	public function removeView(v:View) {
		v.deactivate();
		views.remove(v);
	}
	
	
	// Entity
	
	public function id() {
		var e = ++__SEQUENCE;
		entities.push(e);
		return e;
	}
	
	macro public function remove(self:Expr, id:ExprOf<Int>) {
		var esafe = macro var i = $id;
		var exprs = [ 
			for (n in echo.macro.MacroBuilder.componentHoldersMap) {
				var n = Context.parse(n, Context.currentPos());
				macro $n.__MAP.remove(i);
			}
		];
		
		trace(new Printer().printExprs(exprs, '\n'));
		
		return macro {
			$esafe;
			for (v in $self.views) v.removeIfMatch(i);
			$b{exprs};
			$self.entities.remove(i);
		}
	}
	
	
	// Component
	
	macro inline public function setComponent(self:Expr, id:ExprOf<Int>, components:Array<Expr>) {
		var esafe = macro var i = $id; // TODO opt ( if EConst - safe is unnesessary )
		var exprs = [
			for (c in components) {
				var h = echo.macro.MacroBuilder.getComponentHolder(c.typeof().follow().toComplexType().fullname());
				//if (h == null) continue; // TODO define ?
				var n = Context.parse(h, Context.currentPos());
				macro $n.__MAP.set(i, $c);
			}
		];
		
		trace(new Printer().printExprs(exprs, '\n'));
		
		return macro {
			$esafe;
			$b{exprs};
			for (v in $self.views) v.addIfMatch(i);
		}
	}
	
	macro inline public function removeComponent<T:Class<Dynamic>>(self:Expr, id:ExprOf<Int>, type:ExprOf<T>) {
		var esafe = macro var i = $id;
		var h = echo.macro.MacroBuilder.getComponentHolder(type.identName().getType().follow().toComplexType().fullname());
		//if (h == null) return macro null;
		var n = Context.parse(h, Context.currentPos());
		return macro {
			$esafe;
			if ($n.__MAP.exists(i)) {
				for (v in $self.views) if (v.testcomponent($n.__ID)) v.removeIfMatch(i);
				$n.__MAP.remove(i);
			}
		}
	}
	
	macro inline public function getComponent<T:Class<Dynamic>>(self:Expr, id:ExprOf<Int>, type:ExprOf<T>):ExprOf<T> {
		var h = echo.macro.MacroBuilder.getComponentHolder(type.identName().getType().follow().toComplexType().fullname());
		//if (h == null) return macro null;
		var n = Context.parse(h, Context.currentPos());
		return macro $n.__MAP.get($id);
	}
	
}