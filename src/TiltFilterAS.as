package  
{
	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	public class TiltFilterAS
	{
		protected var _yaw:Number;
		protected var _tilt:Matrix3D;
		protected var m11:Number, m12:Number, m13:Number;
		protected var m21:Number, m22:Number, m23:Number;
		protected var m31:Number, m32:Number, m33:Number;
		
		public function TiltFilterAS(yaw:Number, pitch:Number, roll:Number)
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
			_yaw = yaw;
		}
		
		private var _width:uint;
		private var _height:uint;
		
		// http://en.wikipedia.org/wiki/Nearest-neighbor_interpolation
		static protected function RGB(weight:Number, rgb:uint):Object
		{
			return {
				r: (rgb >> 16) * weight,
				g: ((rgb >> 8) & 255) * weight,
				b: (rgb & 255) * weight
			};
		}
		static protected function RGB_Add(v1:Object, v2:Object):void
		{
			v1.r += v2.r;
			v1.g += v2.g;
			v1.b += v2.b;
		}
		static protected function RGB_dec(v:Object):uint
		{
			return ((v.r & 255) << 16) | ((v.g & 255) << 8) | (v.b & 255);
		}
		
		protected function pixelAtThetaPi(source:BitmapData, theta:Number, phi:Number):uint
		{
			var x:Number = (phi * _width / (2 * Math.PI) + _width) % _width;
			var y:Number = _height / 2 - theta * _height / Math.PI;
			var ix:Number = uint(x), iy:Number = uint(y);
			var ix1:Number = (ix + 1) % _width;
			var ax:Number = x - ix,  ay:Number = y - iy;
			
			var color:Object = RGB((1 - ax) * (1 - ay), source.getPixel(ix,  iy    ));
			RGB_Add(color,     RGB(     ax  * (1 - ay), source.getPixel(ix1, iy    )));
			RGB_Add(color,     RGB((1 - ax) *      ay , source.getPixel(ix,  iy + 1)));
			RGB_Add(color,     RGB(     ax  *      ay , source.getPixel(ix1, iy + 1)));
			
			return RGB_dec(color);
		}
		
		public function apply(source:BitmapData):BitmapData
		{
			_width = source.width;
			_height = source.height;
			var dest:BitmapData = new BitmapData(_width, _height);
			
			dest.lock();
			
			var dx:int = _width * _yaw / (2 * Math.PI);
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
					dest.setPixel((uint)(j + dx) % _width, i, pixelAtThetaPi(source, theta, phi));
				}
			}
			
			dest.unlock();
			return dest;
		}
		
		static public function tilt(yaw:Number, pitch:Number, roll:Number, source:BitmapData):BitmapData
		{
			var self:TiltFilterAS = new TiltFilterAS(yaw, pitch, roll);
			return self.apply(source);
		}
	}
}