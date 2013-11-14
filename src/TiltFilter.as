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
			_yaw = yaw;
		}
		
		private var _width:uint;
		private var _height:uint;
		/*
  ([x]+1-x) ([y]+1-y) Src([x],   [y])
+ ([x]+1-x) (y-[y])   Src([x]+1, [y])
+ (x-[x])   ([y]+1-y) Src([x],   [y]+1)
+ (x-[x])   (y-[y])   Src([x]+1, [y]+1)
w11 = [x]+1-x,  w12 = [y]+1-y
w21 = x-[x]  ,  w22 = y-[y]
  w11 * w12 * Src([x],   [y]  )
+ w11 * w22 * Src([x]+1, [y]  )
+ w21 * w12 * Src([x],   [y]+1)
+ w21 * w22 * Src([x]+1, [y]+1)
http://imagingsolution.net/imaging/interpolation/
http://en.wikipedia.org/wiki/Nearest-neighbor_interpolation
		 */
		protected function average_color(rgb0:uint, rgb1:uint, w0:Number):uint
		{
			var w1:Number = 1 - w0;
			var r0:uint = rgb0 >> 16, g0:uint = (rgb0 >> 8) & 255, b0:uint = rgb0 & 255;
			var r1:uint = rgb1 >> 16, g1:uint = (rgb1 >> 8) & 255, b1:uint = rgb1 & 255;
			var r:Number = r0 * w0 + r1 * w1;
			var g:Number = g0 * w0 + g1 * w1;
			var b:Number = b0 * w0 + b1 * w1;
			var c:uint = (r << 16) | (g << 8) | b;
			return c;
		}
		protected function sampler(source:BitmapData, x0:Number, y0:Number, x1:Number, y1:Number, w0:Number):uint
		{
			var rgb0:uint = source.getPixel(x0 % _width, y0);
			var rgb1:uint = source.getPixel(x1 % _width, y1);
			return average_color(rgb0, rgb1, w0);
		}
		
		protected function pixelAtThetaPi(source:BitmapData, theta:Number, phi:Number):uint
		{
			var x0:Number = phi * _width / (2 * Math.PI) + _width;
			var y0:Number = _height / 2 - theta * _height / Math.PI;
			
			var rx:Number = x0 - Math.floor(x0);
			var x1:Number, wx:Number;
			if (rx < 0.5) {
				x1 = x0 - 1;
				wx = 0.5 + rx;
			} else {
				x1 = x0 + 1;
				wx = 1.5 - rx;
			}
			var cu:uint = sampler(source, x0, y0, x1, y0, wx);
			
			var ry:Number = y0 - Math.floor(y0);
			var y1:Number, wy:Number;
			if (ry < 0.5) {
				y1 = y0 - 1;
				wy = 0.5 + ry;
			} else {
				y1 = y0 + 1;
				wy = 1.5 - ry;
			}
			var cd:uint = sampler(source, x0, y1, x1, y1, wx);
			
			return average_color(cu, cd, wy);
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
			var self:TiltFilter = new TiltFilter(yaw, pitch, roll);
			return self.apply(source);
		}
	}
}