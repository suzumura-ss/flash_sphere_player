package info.smoche.utils
{
	import flash.geom.Vector3D;
	
	/**
	 * ...
	 * @author ...
	 */
	public class Quaternion
	{
		public var w:Number;
		public var x:Number;
		public var y:Number;
		public var z:Number;
		
		public function Quaternion(w:Number = 1, x:Number = 0, y:Number = 0, z:Number = 0)
		{
			this.w = w;
			this.x = x;
			this.y = y;
			this.z = z;
		}
		
		static public function Rotate(v:Vector3D, rad:Number):Quaternion
		{
			rad /= 2;
			var s:Number = Math.sin(rad);
			return new Quaternion(Math.cos(rad), v.x * s, v.y * s, v.z * s);
		}
		
		public function clone():Quaternion
		{
			return new Quaternion(w, x, y, z);
		}
		
		public function neg():Quaternion
		{
			return new Quaternion(-w, -x, -y, -z);
		}
		
		public function add(q:Quaternion):Quaternion
		{
			return new Quaternion(w + q.w, x + q.x, y + q.y, z + q.z);
		}
		
		public function sub(q:Quaternion):Quaternion
		{
			return this.add(q.neg());
		}
		
		public function mul(q:Quaternion):Quaternion
		{
			var _x:Number = x * q.w + w * q.x + y * q.z - z * q.y;
			var _y:Number = y * q.w + w * q.y + z * q.x - x * q.z;
			var _z:Number = z * q.w + w * q.z + x * q.y - y * q.x;
			var _w:Number = w * q.w - x * q.x - y * q.y - z * q.z;
			return new Quaternion(_w, _x, _y, _z);
		}
		
		public function mulV(v:Vector3D):Vector3D
		{
			// calculate quat * vec
			var ix:Number = w * v.x + y * v.z - z * v.y;
			var iy:Number = w * v.y + z * v.x - x * v.z;
			var iz:Number = w * v.z + x * v.y - y * v.x;
			var iw:Number = -x * v.x - y * v.y - z * v.z;
			
			// calculate result * inverse quat
			var _x:Number = ix * w + iw * -x + iy * -z - iz * -y;
			var _y:Number = iy * w + iw * -y + iz * -x - ix * -z;
			var _z:Number = iz * w + iw * -z + ix * -y - iy * -x;
			
			return new Vector3D(_x, _y, _z);
		}
		
		public function conjugate():Quaternion
		{
			return new Quaternion(w, -x, -y, -z);
		}
		
		public function scale(s:Number):Quaternion
		{
			return new Quaternion(w * s, x * s, y * s, z * s);
		}
		
		public function length2():Number
		{
			return w * w + x * x + y * y + z * z;
		}
		
		public function length():Number
		{
			return Math.sqrt(length2());
		}
		
		public function normalize():Quaternion
		{
			var l:Number = length();
			return new Quaternion(w / l, x / l, y / l, z / l);
		}
		
		public function roll():Number
		{
			return Math.atan2(2 * (y * z + w * x), w * w - x * x - y * y + z * z);
		}
		
		public function pitch():Number
		{
			return Math.asin( -2 * (x * z - w * y));
		}
		
		public function yaw():Number
		{
			return Math.atan2(2 * (x * y + w * z), w * w + x * x - y * y - z * z);
		}
		
		public function toVector3D():Vector3D
		{
			return new Vector3D(x, y, z);
		}
		
		public function slerp(r:Quaternion, slerp:Number):Quaternion
		{
			var cosHalfTheta:Number =  x * r.x + y * r.y + z * r.z + w * r.w;
			if (Math.abs(cosHalfTheta) >= 1.0) {
				return clone();
			}
			
			var _x:Number, _y:Number, _z:Number, _w:Number;
			var halfTheta:Number = Math.acos(cosHalfTheta);
			var sinHalfTheta:Number = Math.sqrt(1.0 - cosHalfTheta * cosHalfTheta);
	        if (Math.abs(sinHalfTheta) < 0.001) {
				_w = (w * 0.5 + r.w * 0.5);
				_x = (x * 0.5 + r.x * 0.5);
				_y = (y * 0.5 + r.y * 0.5);
				_z = (z * 0.5 + r.z * 0.5);
				return new Quaternion(_w, _x, _y, _z);
	        }
			
			var ratioA:Number = Math.sin((1 - slerp) * halfTheta) / sinHalfTheta;
			var ratioB:Number = Math.sin(slerp * halfTheta) / sinHalfTheta;
			_w = (w * ratioA + r.w * ratioB);
			_x = (x * ratioA + r.x * ratioB);
			_y = (y * ratioA + r.y * ratioB);
			_z = (z * ratioA + r.z * ratioB);
			return new Quaternion(_w, _x, _y, _z);
		}
	}
}