package  
{
	import alternativa.engine3d.objects.Mesh;
	import flash.display.BitmapData;
	import flash.geom.Vector3D;
	import info.smoche.alternativa.BitmapTextureResourceLoader;
	import info.smoche.ThetaEXIF;
	import info.smoche.utils.Utils;

	/**
	 * ...
	 * @author Toshiyuki Suzumura  / Twitter:@suzumura_ss
	 */
	
	public class Gate 
	{
		private var _name:String;
		private var _mesh:Mesh;
		private var _arrow:Arrow;
		private var _pos:Vector3D;
		private var _tilt_yaw:Number;
		private var _yaw:Number;
		private var _pitch:Number;
		private var _distance:Number;
		
		private var _bitmapData:BitmapData;
		
		public function Gate(name:String, url:String, mesh:Mesh, arrow:Arrow, pos:Vector3D, tilt_yaw:Number, yaw:Number, pitch:Number, distance:Number)
		{
			_name = name;
			_mesh = mesh;
			_arrow = arrow;
			_pos = pos;
			_tilt_yaw = tilt_yaw;
			_distance = distance;
			_yaw = yaw;
			_pitch = pitch;
			
			BitmapTextureResourceLoader.loadBitmapFromURL(url, function(bmp:BitmapData, exif:ThetaEXIF):void {
				_bitmapData = bmp;
			}, function(e:Object):void {
				Utils.Trace(e);
			});
		}
		
		public function bitmapData():BitmapData
		{
			return _bitmapData;
		}
		
		public function name():String
		{
			return _name;
		}
		
		public function mesh():Mesh
		{
			return _mesh;
		}
		
		public function arrow():Arrow
		{
			return _arrow;
		}
		
		public function pos():Vector3D
		{
			return _pos;
		}
		
		public function distance():Number
		{
			return _distance;
		}
		
		public function yaw():Number
		{
			return _yaw;
		}
		
		public function pitch():Number
		{
			return _pitch;
		}
		
		public function tilt_yaw():Number
		{
			return _tilt_yaw;
		}
	}
}