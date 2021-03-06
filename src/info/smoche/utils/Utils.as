package info.smoche.utils
{
	import flash.external.ExternalInterface;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / Twitter:@suzumura_ss
	 */
	public class Utils 
	{
		public function Utils() { }
		
		// radian - degree conversion
		static public function to_deg(rad:Number):Number
		{
			return 360.0 * rad / (2.0 * Math.PI);
		}
		
		static public function to_rad(deg:Number):Number
		{
			return 2.0 * Math.PI * deg / 360.0;
		}
		
		// JavaScript callback wrapper
		static public function jsCallback(jsFunction:String, data:Object):void
		{
			if (ExternalInterface.available) {
				try {
					if (jsFunction) ExternalInterface.call(jsFunction, data);
				} catch (x:Error) {
					Trace(x);
				}
			}
		}
		
		static public function Trace(msg:Object):void
		{
			trace(msg);
			if (ExternalInterface.available) {
				try {
					ExternalInterface.call("console.log", msg.toString());
				} catch (x:Error) {
					trace(x);
				}
			}
		}
		
		static public function rad_trace(...rest):void
		{
			var s:String = "";
			for each (var x:Object in rest) {
				s = s + " ";
				if (typeof(x) == "number") {
					s = s + to_deg(Number(x)).toFixed(1);
				} else {
					s = s + x;
				}
			}
			Trace(s);
		}
		
		static public function clipRadian(rad:Number):Number
		{
			var x:Number = Math.cos(rad);
			var y:Number = Math.sin(rad);
			return Math.atan2(y, x);
		}
	}
}