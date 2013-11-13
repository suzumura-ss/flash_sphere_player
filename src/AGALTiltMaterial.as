package  
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	import info.smoche.stage3d.AGALGeometry;
	import info.smoche.stage3d.AGALProgram;
	import info.smoche.utils.Utils;
	
	use namespace alternativa3d;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class AGALTiltMaterial extends NonMipmapTextureMaterial
	{
		protected var _mathResource:NonMipmapBitmapTextureResource;
		protected const _tilt:Transform3D = new Transform3D();
		protected var _yaw:Number;
		protected var _isIdentity:Boolean;
		
		[Embed(source = "resources/math.png")] protected static const MATH:Class;
		
		public function AGALTiltMaterial(texture:TextureResource, context3d:Context3D)
		{
			super(texture, 1.0, context3d);
			_mathResource = new NonMipmapBitmapTextureResource((new MATH() as Bitmap).bitmapData);
			setCompass(0, 0, 0);
		}
		
		
		public function setCompass(yaw:Number, pitch:Number, roll:Number):void
		{
			if (yaw == 0 && pitch == 0 && roll == 0) {
				_isIdentity = true;
				_tilt.identity();
				_yaw = 0;
				return;
			}
			
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
			_tilt.initFromVector(Vector.<Number>([
				 xz33, -xz32, -xz31, 0,
				-xz23,  xz22,  xz21, 0,
				-xz13,  xz12,  xz11, 0,
			]));
			_yaw = yaw;
		}
		
		override protected function loadProgram():void 
		{
			_vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, [
				"mov op, va0",	// position
				"mov v0, va1",	// texcoord
			].join("\n"));
			
			_fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, [
				// http://www.saltgames.com/2011/stage-3d-shader-cheatsheet/
				// fragment shader
				"#texture=0",
				"#tex_math=1",	// fs1: [R,G]=atan2(x,z), [B,A]=asin(y)
				"#M_PI=0",		// fc0: [M_PI2=PI/2, M_PI, M_2PI=PI*2]
				"#ONE=1",		// fc1: [1, 2, 256, 0.5]
				"#TILT=2",		// fc2-4: [_tiltMatrix/3x3]
				
				// highp float phi0[ft0.x]   = M_2PI * v_texcoord.x[v0.x];
				"mul ft0.x, fc0.z, v0.x",
				
				// highp float theta0[ft0.y] = M_PI2 - M_PI * v_texcoord.y[v0.y];
				"mul ft0.y, fc0.y, v0.y",
				"sub ft0.y, fc0.x, ft0.y",
				
				// highp float cosTheta[ft0.z] = cos(theta0[ft0.x]);
				"cos ft0.z, ft0.x",
				
				// highp vec3 p[ft0] = tilt[fc2-4]
				//					 * vec3[ft1](cosTheta[ft0.z] * cos(phi0[ft0.x]),
				//						                           sin(theta0[ft0.y]),
				//								 cosTheta[ft0.z] * sin(phi0[ft0.x]));
				"cos ft1.x, ft0.x",
				"sin ft1.y, ft0.y",
				"sin ft1.z, ft0.x",
				"mul ft1.xz, ft1.xz, ft0.z",
				"m33 ft0.xyz, ft1.xyz, fc2",
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
				
				"tex ft1, ft0.xz, fs1 <2d,clamp,linear>",	// (r,g) = atan2(x,z), fs1=atan2(-PI<=u=PI, -PI<=v=PI)
				"div ft1.y, ft1.y, fc1.z",					// x = r+g/256
				"add ft1.x, ft1.x, ft1.y",
				
				"tex ft0, ft0.yy, fs1 <2d,clamp,linear>",	// (b,a) = 0.5-asin(y), fs2=0.5-asin(-PI/2<=u=PI/2), v=0
				"mov ft1.y, ft0.z",							// y = b
				
				// gl_FragColor[oc] = texture2D(texture[fs0], q[ft.0]);
				"tex oc, ft1.xy, fs0 <2d,clamp,linear>",
			].join("\n"));
		}
		
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void 
		{
			super.fillResources(resources, resourceType);
			if (_mathResource) {
				resources[_mathResource] = true;
			}
		}
		
		override protected function setupExtraUniforms(drawUnit:DrawUnit):void 
		{
			super.setupExtraUniforms(drawUnit);
			drawUnit.setTextureAt(1, _mathResource._texture);
			drawUnit.setFragmentConstantsFromNumbers(0, Math.PI / 2, Math.PI, Math.PI * 2);
			drawUnit.setFragmentConstantsFromNumbers(1, 1, 2, 256, 0.5);
			drawUnit.setFragmentConstantsFromTransform(2, _tilt);
		}
	}
}