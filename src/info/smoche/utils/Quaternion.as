package info.smoche.utils
{
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
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
			var _w:Number = w * q.w - x * q.x - y * q.y - z * q.z;
			var _x:Number = w * q.x + x * q.w + y * q.z - z * q.y;
			var _y:Number = w * q.y - x * q.z + y * q.w + z * q.x;
			var _z:Number = w * q.z + x * q.y - y * q.x + z * q.w;
			return new Quaternion(_w, _x, _y, _z);
		}
		
		public function conjugate():Quaternion
		{
			return new Quaternion(w, -x, -y, -z);
		}
		
		public function scale(s:Number):Quaternion
		{
			return new Quaternion(w * s, x * s, y * s, z * s);
		}
		
		public function norm2():Number
		{
			return w * w + x * x + y * y + z * z;
		}
			
		public function norm():Number
		{
			return Math.sqrt(norm2());
		}
		
		public function transform(v:Vector3D):Vector3D
		{
			var _w:Number = -x * v.x - y * v.y - z * v.z;
			var _x:Number =  y * v.z - z * v.y + w * v.x;
			var _y:Number =  z * v.x - x * v.z + w * v.y;
			var _z:Number =  x * v.y - y * v.x + w * v.z;
			
			var vx:Number = _y * -z + _z * y - _w * x + _x * w;
			var vy:Number = _z * -x + _x * z - _w * y + _y * w;
			var vz:Number = _x * -y + _y * x - _w * z + _z * w;
			
			return new Vector3D(vx, vy, vz);
		}
		
		public function toMatrix3D():Matrix3D
		{
			var x2:Number = x * x * 2;
			var y2:Number = y * y * 2;
			var z2:Number = z * z * 2;
			var xy:Number = x * y * 2;
			var yz:Number = y * z * 2;
			var zx:Number = z * x * 2;
			var xw:Number = x * w * 2;
			var yw:Number = y * w * 2;
			var zw:Number = z * w * 2;
			
			return new Matrix3D(Vector.<Number>([
				1 - y2 - z2, xy + zw, zx - yw, 0,
				xy - zw, 1 - z2 - x2, yz + xw, 0,
				zx + yw, yz - xw, 1 - x2 - y2, 0,
				0, 0, 0, 1]));
		}
		
		public function slerp(r:Quaternion, t:Number):Quaternion
		{
			var qr:Number = w * r.w + x * r.x + y * r.y + z * r.z;
			var ss:Number = 1.0 - qr * qr;
			
			if (ss <= 0.0) {
				return clone();
			}
			var sp:Number = Math.sqrt(ss);
			if (sp == 0.0) {
				return clone();	// ありえる
			}
			var ph:Number = Math.acos(qr);
			var pt:Number = ph * t;
			var t1:Number = Math.sin(pt) / sp;
			var t0:Number = Math.sin(ph - pt) / sp;
			var _w:Number = w * t0 + r.w * t1;
			var _x:Number = x * t0 + r.x * t1;
			var _y:Number = y * t0 + r.y * t1;
			var _z:Number = z * t0 + r.z * t1;
			return new Quaternion(_w, _x, _y, _z);
		}
	}
}