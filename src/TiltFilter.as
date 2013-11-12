package  
{
	import flash.display.Bitmap;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import info.smoche.stage3d.AGALProgram;
	import info.smoche.utils.Utils;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class TiltFilter 
	{
		protected var _context3D:Context3D;
		protected var _agalProgram:AGALProgram;
		protected var _mathTable:Texture;
		protected var _tiltMatrix:Matrix3D;
		protected var _yaw_rad:Number;
		protected var _isIdentity:Boolean;
		
		[Embed(source = "resources/math.png")] protected static const MATH:Class;
		
		public function TiltFilter(context3D:Context3D)
		{
			_context3D = context3D;
			loadProgram();
		}
		
		public function setCompass(yaw_deg:Number, pitch_deg:Number, roll_deg:Number):void
		{
			_yaw_rad = Utils.to_rad(yaw_deg);
			_tiltMatrix = new Matrix3D();
			_tiltMatrix.identity();
			_isIdentity = (yaw_deg == 0) && (pitch_deg== 0) && (roll_deg == 0);
			if (_isIdentity) {
				return;
			}
			_tiltMatrix.appendRotation(roll_deg, Vector3D.Z_AXIS);
			_tiltMatrix.appendRotation(pitch_deg, Vector3D.X_AXIS);
		}
		
		protected function loadProgram():void
		{
			_agalProgram = new AGALProgram(_context3D, [
				// vertex shader
				"mov op, va0",	// position
				"mov v0, va1",	// texcoord
			], [
				// http://www.saltgames.com/2011/stage-3d-shader-cheatsheet/
				// fragment shader
				"#texture=0",
				"#tex_math=1",	// fs1: [R,G]=atan2(x,z), [B,A]=asin(y)
				"#M_PI=0",		// fc0: [M_PI2=PI/2, M_PI, M_2PI=PI*2]
				"#ONE=1",		// fc1: [1.0, 2.0, 256.0]
				"#TILT=2",		// fc2-5: [_tiltMatrix/4x4] 
				
				// highp float phi0[ft0.x]   = M_2PI * v_texcoord.x[v0.x];
				"mul ft0.x, fc0.z, v0.x",
				// highp float theta0[ft0.y] = M_PI2 - M_PI * v_texcoord.y[v0.y];
				"mul ft0.y, fc0.y, v0.y",
				"sub ft0.y, fc0.x, ft0.y",
				// highp float cosTheta[ft0.z] = cos(theta0[ft0.x]);
				"cos ft0.z, ft0.x",
				// highp vec3 p[ft0] = tilt[fc2-5]
				//					 * vec3[ft1](cosTheta[ft0.z] * cos(phi0[ft0.x]),
				"cos ft1.x, ft0.x",
				"mul ft1.x, ft0.z, ft1.x",
				//						         sin(theta0[ft0.y]),
				"sin ft1.y, ft0.y",
				//								 cosTheta[ft0.z] * sin(phi0[ft0.x]));
				"sin ft1.z, ft0.x",
				"mul ft1.z, ft0.z, ft1.z",
				"mov ft1.w, fc1.x", // w = 1
				"m33 ft0.xyz, fc2, ft1", 
				//=> -1<=x<=1, -1<=y<=1, -1<=z<=1
				
				// highp float phi[ft0.x] = atan(p.z[ft0.z], p.x[ft0.x]);
				// highp float theta[ft0.y] = asin(p.y[ft0.y]);
				// (z,x) => -PI  <=phi  <=PI
				//  y    => -PI/2<=theta<=PI/2
				// highp vec2 q[ft.0] = vec2(mod(phi[ft0.x] / M_2PI, 1.0),
				//					         0.5 - theta[ft0.y] / M_PI);
				// phi   => 0<=x<=1
				// theta => 0<=y<=1
				//---
				// 0<=x,z<=1 => x = atan2(z:<0~1=-PI~PI>, x:<0~1:-PI~PI>)/(2*PI)
				// 0<=y<=1   => y = 0.5 - asin(y:<0~1=-PI/2~PI/2>)/PI
				"add ft0.xyz, ft0.xyz, fc1.xxx",	//  -1<=x,y,z<=1
				"div ft0.xyz, ft0.xyz, fc1.yyy",	//=> 0<=x,y,z<=1
				"sat ft0,xyz, ft0.xyz",
				"sub ft0.w, ft0.x, ft0.x",			// w = 0
				"tex ft1, ft0.xz, fs1 <2d,clamp,linear>",	// (r,g) = atan2(x,z), fs1=atan2(-PI<=u=PI, -PI<=v=PI)
				"div ft1.y, ft1.y, fc1.z",					// x = r+g/256
				"add ft0.x, ft1.x, ft1.y",
				"tex ft1, ft0.yw, fs1 <2d,clamp,linear>", 	// (b,a) = [B,A]asin(y),    fs2=asin(-PI/2<=u=PI/2), v=0
				"mov ft0.y, ft1.z",							// y = b
				
				// gl_FragColor[oc] = texture2D(texture[fs0], q[ft.0]);
				"tex oc, ft0.xy, fs0 <2d,clamp,linear>",
			]);
			
			var math:Bitmap = new MATH() as Bitmap;
			_mathTable = _context3D.createTexture(math.width, math.height, Context3DTextureFormat.BGRA, false);
			_mathTable.uploadFromBitmapData(math.bitmapData, 0);
		}
	}
}