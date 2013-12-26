package info.smoche
{
	import flash.utils.ByteArray;
	import info.smoche.ThetaEXIF.ExifParser;
	import info.smoche.utils.Utils;
	
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	
	public class ThetaEXIF
	{
		public var yaw:Number = NaN;
		public var pitch:Number = NaN;
		public var roll:Number = NaN;
		public var cpu_version:String = null;
		public var serial:String = null;
		public var abnormal_acceleation:Number = NaN;
		
		public function ThetaEXIF(bytes:ByteArray)
		{
			var p:ExifParser = new ExifParser(bytes);
			try {
				p.parseTags(this);
			}
			catch (e:Object) {
				Utils.Trace(e);
			}
		}
		
		public function toString():String
		{
			var s:String = "<ThetaEXIF";
			s += " yaw=" + yaw;
			s += " pitch=" + pitch;
			s += " roll=" + roll;
			s += " abnormal_acceleation=" + abnormal_acceleation;
			s += " cpu_version=" + (cpu_version ? "\"" + cpu_version + "\"" : "(null)");
			s += " serial=" + (serial ? "\"" + serial + "\"" : "(null)");
			s += " >";
			return s;
		}
	}
}
