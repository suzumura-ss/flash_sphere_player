package info.smoche.utils 
{
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	public class Matrix3x3
	{
		public var m11:Number, m12:Number, m13:Number;
		public var m21:Number, m22:Number, m23:Number;
		public var m31:Number, m32:Number, m33:Number;
		
		public function Matrix3x3(a11:Number = 1, a12:Number = 0, a13:Number = 0, a21:Number = 0, a22:Number = 1, a23:Number = 0, a31:Number = 0, a32:Number = 0, a33:Number = 1)
		{
			m11 = a11;	m12 = a12;	m13 = a13;
			m21 = a21;	m22 = a22;	m23 = a23;
			m31 = a31;	m32 = a32;	m33 = a33;
		}
		
		public function identity():void
		{
			m11 = 1;	m12 = 0;	m13 = 0;
			m21 = 0;	m22 = 1;	m23 = 0;
			m31 = 0;	m32 = 0;	m33 = 1;
		}
		
		public function mul_m(mat:Matrix3x3):Matrix3x3
		{
			var ret:Matrix3x3;
			
			ret.m11 = m11 * mat.m11 + m12 * mat.m21 + m13 * mat.m31;
			ret.m12 = m11 * mat.m12 + m12 * mat.m22 + m13 * mat.m32;
			ret.m13 = m11 * mat.m13 + m12 * mat.m23 + m13 * mat.m33;
			
			ret.m21 = m21 * mat.m11 + m22 * mat.m21 + m23 * mat.m31;
			ret.m22 = m21 * mat.m12 + m22 * mat.m22 + m23 * mat.m32;
			ret.m23 = m21 * mat.m13 + m22 * mat.m23 + m23 * mat.m33;
			
			ret.m31 = m31 * mat.m11 + m32 * mat.m21 + m33 * mat.m31;
			ret.m32 = m31 * mat.m12 + m32 * mat.m22 + m33 * mat.m32;
			ret.m33 = m31 * mat.m13 + m32 * mat.m23 + m33 * mat.m33;
			
			return ret;
		}
		
		public function mul_v(vec:Vector3):Vector3
		{
			var ret:Vector3;
			ret.x = m11 * vec.x + m12 * vec.y + m13 * vec.z;
			ret.y = m21 * vec.x + m22 * vec.y + m23 * vec.z;
			ret.z = m31 * vec.x + m32 * vec.y + m33 * vec.z;
			return ret;
		}
	}
}