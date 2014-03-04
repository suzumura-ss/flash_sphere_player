package info.smoche.stage3d 
{
	import flash.display3D.Context3D;
	import info.smoche.utils.Matrix3x3;
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	public class TiltGeometry 
	{
		public const ROWS:Number = 32;
		public const COLS:Number = 16;
		public const ROW_WIDTH:Number = 1.0 / ROWS;
		public const COL_HEIGHT:Number = 1.0 / COLS;
		public const VERTS_R:Number = ROWS + 1;
		public const VERTS_C:Number = COLS + 1;
		
		protected var _context:Context3D;
		protected var _geom:AGALGeometry;
		protected var _tilt:Matrix3x3 = new Matrix3x3;
		protected var _isIdentity:Boolean = true;
		
		static public function makeTiltMatrix(yaw:Number, pitch:Number, roll:Number):Matrix3x3
		{
			var cosP:Number = Math.cos(pitch);
			var sinP:Number = Math.sin(pitch);
			var cosR:Number = Math.cos(roll);
			var sinR:Number = Math.sin(roll);
			
			var rotYp:Matrix3x3 = new Matrix3x3(0, 0, -1, 0, 1, 0, 1, 0, 0);
			var rotP:Matrix3x3 = new Matrix3x3(1, 0, 0, 0, cosP, -sinP, 0, sinP, cosP);
			var rotR:Matrix3x3 = new Matrix3x3(cosR, sinR, 0, -sinR, cosR, 0, 0, 0, 1);
			var rotYn:Matrix3x3 = new Matrix3x3(0, 0, 1, 0, 1, 0, -1, 0, 0);
			
			return rotYp.mul_m(rotR).mul_m(rotP).mul_m(rotYn);
		}
		
		public function TiltGeometry(context:Context3D)
		{
			_context = context;
		}
		
		public function dispose():void
		{
			if (_geom) _geom.dispose();
			_geom = null;
		}
		
		protected function setIdentity():void
		{
			dispose();
			_tilt.identity();
			_isIdentity = true;
			
			var verts:Vector.<Number> = Vector.<Number>([
			//  x,   y, z,	u, v
				-1, -1, 0,	0, 0,
				 1, -1, 0,	0, 1,
				 1,  1, 0,	1, 1,
				-1,  1, 0,	1, 0,
			]);
			
			var indexes:Vector.<uint> = Vector.<uint>([
				0, 1, 2,
				0, 2, 3,
			]);
			_geom = new AGALGeometry(_context, verts, indexes);
		}
		
		public function get isIdentity():Boolean
		{
			return _isIdentity;
		}
		
		public function setTilt(yaw:Number, pitch:Number, roll:Number):void
		{
			if (yaw == 0 && pitch == 0 && roll == 0) {
				setIdentity();
				return;
			}
			_tilt = makeTiltMatrix(yaw, pitch, roll);
			
		}
		
		
		
	}

}