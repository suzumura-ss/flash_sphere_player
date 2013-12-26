package info.smoche.ThetaEXIF 
{
	import flash.utils.ByteArray;
	import info.smoche.ThetaEXIF.ExifParser;
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	public class Entry 
	{
		public var code:uint;
		public var type:uint;
		public var length:uint;
		public var data:ByteArray;
		public var offset:uint;
		public function Entry(code:uint, type:uint, length:uint, data:ByteArray, bigEndian:Boolean)
		{
			this.code = code;
			this.type = type;
			this.length = length;
			this.data = data;
			this.offset = (data == null)? 0: ExifParser.to_uint32e(data, bigEndian)[0];
		}
	}
}