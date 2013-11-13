package  
{
	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	public class TiltFilter 
	{
		protected var _yaw:Number;
		protected var _tilt:Matrix3D;
		protected var m11:Number, m12:Number, m13:Number;
		protected var m21:Number, m22:Number, m23:Number;
		protected var m31:Number, m32:Number, m33:Number;
		
		public function TiltFilter(yaw:Number, pitch:Number, roll:Number)
		{
			var cosP:Number = Math.cos(pitch);
			var sinP:Number = Math.sin(pitch);
			var cosR:Number = Math.cos(roll);
			var sinR:Number = Math.sin(roll);
			
			var xz11:Number =         cosR;
			var xz12:Number =        -sinR;
			var xz13:Number =         0.0;
			var xz21:Number =  cosP * sinR;
			var xz22:Number =  cosP * cosR;
			var xz23:Number = -sinP;
			var xz31:Number =  sinP * sinR;
			var xz32:Number =  sinP * cosR;
			var xz33:Number =  cosP;
			_tilt = new Matrix3D(Vector.<Number>([
				 xz33, -xz32, -xz31, 0,
				-xz23,  xz22,  xz21, 0,
				-xz13,  xz12,  xz11, 0,
				    0,     0,     0, 1,
			]));
			
			m11 =  xz33;
			m12 = -xz32;
			m13 = -xz31;
			m21 = -xz23;
			m22 =  xz22;
			m23 =  xz21;
			m31 = -xz13;
			m32 =  xz12;
			m33 =  xz11;
        
			_yaw = yaw;
		}
		
		private var _width:uint;
		private var _height:uint;
		
		protected function pixelAtThetaPi(source:BitmapData, theta:Number, phi:Number):uint
		{
			var x:uint = Math.floor(phi * _width / (2 * Math.PI) + _width) % _width;
			var y:uint = _height / 2 - theta * _height / Math.PI;
			return source.getPixel32(x, y);
		}
		
		public function apply(source:BitmapData):BitmapData
		{
			_width = source.width;
			_height = source.height;
			var dest:BitmapData = new BitmapData(_width, _height);
			
			dest.lock();
			
			for (var i:Number = 0; i < _height; ++i) {
				var theta0:Number = Math.PI / 2 - Math.PI * i / _height;
				var y0:Number = Math.sin(theta0);
				var cosTheta:Number = Math.cos(theta0);
				
				for (var j:Number = 0; j < _width; ++j) {
					var phi0:Number = Math.PI * 2 * j / _width;
					var x0:Number = cosTheta * Math.cos(phi0);
					var z0:Number = cosTheta * Math.sin(phi0);
					
					var pos:Vector3D = _tilt.transformVector(new Vector3D(x0, y0, z0));
					var theta:Number = Math.asin(pos.y);
					var phi:Number = Math.atan2(pos.z, pos.x);
					
					//var x:Number = m11 * x0 + m12 * y0 + m13 * z0;
					//var y:Number = m21 * x0 + m22 * y0 + m23 * z0;
					//var z:Number = m31 * x0 + m32 * y0 + m33 * z0;
					//var theta:Number = Math.asin(y);
					//var phi:Number = Math.atan2(z, x);
					
					dest.setPixel32(j, i, pixelAtThetaPi(source, theta, phi));
				}
			}
			
			dest.unlock();
			return dest;
		}
		
		static public function tilt(yaw:Number, pitch:Number, roll:Number, source:BitmapData):BitmapData
		{
			var self:TiltFilter = new TiltFilter(yaw, pitch, roll);
			return self.apply(source);
		}
	}
}