package echo;

/**
 * ...
 * @author octocake1
 */
#if !macro
@:autoBuild(echo.macro.MacroBuilder.buildSystem())
#end
class System {
	
	
	var echo:Echo;
	

	public function new() {
		
	}
	
	
	@:allow(echo.Echo) function activate(echo:Echo) {
		this.echo = echo;
		onactivate();
	}
	
	@:allow(echo.Echo) function deactivate() {
		ondeactivate();
		this.echo = null;
	}
	
	
	public function onactivate() {
		
	}
	
	public function ondeactivate() {
		
	}
	
	public function update(dt:Float) {
		
	}
	
}