package  
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.core.Transform3D;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display.Bitmap;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	
	use namespace alternativa3d;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class AGALTiltMaterial extends NonMipmapTextureMaterial
	{
		protected var _mathTextures:Vector.<NonMipmapBitmapTextureResource>
		protected const _tilt:Transform3D = new Transform3D();
		protected var _yaw:Number;
		protected var _isIdentity:Boolean;
		
		[Embed(source = "resources/math_atan.png")] protected static const MATH_ATAN:Class;
		[Embed(source = "resources/math_asin.png")] protected static const MATH_ASIN:Class;
		
		public function AGALTiltMaterial(texture:TextureResource, context3d:Context3D)
		{
			super(texture, 1.0, context3d);
			var atan:NonMipmapBitmapTextureResource = new NonMipmapBitmapTextureResource((new MATH_ATAN() as Bitmap).bitmapData);
			var asin:NonMipmapBitmapTextureResource = new NonMipmapBitmapTextureResource((new MATH_ASIN() as Bitmap).bitmapData);
			_mathTextures = Vector.<NonMipmapBitmapTextureResource>([atan, asin]);
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
				"#M_PI=4",		// vc4: [M_PI2=PI/2, M_PI, M_2PI=PI*2]
				// position
				"mov op, va0",
				// texcoord
				"mul vt0.x, va1.x, vc4.z",	// u = (0..1) => (-PI..PI)
				"sub vt0.x, vt0.x, vc4.y",
				"mul vt0.y, va1.y, vc4.y",	// v = (0..1) => (-PI/2..PI/2)
				"sub vt0.y, vt0.y, vc4.x",
				"mov v0.xy, vt0.xy",
				"mov v0.zw, va0.zw",
			].join("\n"));
			
			_fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, [
				// http://www.saltgames.com/2011/stage-3d-shader-cheatsheet/
				// fragment shader
				"#texture=0",
				"#tex_atan=1",	// fs1: [R,G,B]=(atan2(x,z)/PI+1)/2
				"#tex_asin=2",	// fs2: [R,G,B]=0.5-asin(y)/PI
				"#ONE=0",		// fc0: [1, 2]
				"#RGB2F=1",		// fc1:
				"#TILT=2",		// fc2-4: [_tiltMatrix/3x3]
				
				// highp float phi0  [v0.x] = M_2PI * v_texcoord.x;
				// highp float theta0[v0.y] = M_PI2 - M_PI * v_texcoord.y;
				// highp float cosTheta[ft0.x] = cos(theta0[v0.y]);
				"sin ft0.x, v0.x",	// sin(phi0  [v0.x])
				"cos ft0.y, v0.x",	// cos(phi0  [v0.x])
				"sin ft0.z, v0.y",	// sin(theta0[v0.y])
				"cos ft0.w, v0.y",	// cos(theta0[v0.y])
				
				// highp vec3 p[ft0] = tilt[fc2-4]
				//					 * vec3[ft1](cos(theta0[v0.y]) * cos(phi0  [v0.x]),
				//						                             sin(theta0[v0.y]),
				//								 cos(theta0[v0.y]) * sin(phi0  [v0.x]));
				"mul ft1.x, ft0.w, ft0.y",
				"mov ft1.y, ft0.z",
				"mul ft1.z, ft0.w, ft0.x",
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
				
				"add ft0.xyz, ft0.xyz, fc0.xxx",	//  -1<=x,y,z<=1
				"div ft0.xyz, ft0.xyz, fc0.yyy",	//=> 0<=x,y,z<=1
				"sat ft0,xyz, ft0.xyz",
				
				"tex ft1, ft0.xz, fs1 <2d,clamp,linear>",	// (r,g,b) = atan2(x,z), fs1=atan2(-PI<=u=PI, -PI<=v=PI)
				"mul ft1.xyz, ft1.xyz, fc1.xyz",			// x = r + g/256 + b/65536
				"add ft1.x, ft1.x, ft1.y",
				"add ft1.x, ft1.x, ft1.z",
				
				"tex ft0, ft0.yy, fs2 <2d,clamp,linear>",	// (r,g,b) = 0.5-asin(y), fs2=0.5-asin(-PI/2<=u=PI/2), v=0
				"mul ft0.xyz, ft0.xyz, fc1.xyz",			// y = r + g/256 + b/65536
				"add ft1.y, ft0.x, ft0.y",
				"add ft1.y, ft1.y, ft0.z",
				
				// gl_FragColor[oc] = texture2D(texture[fs0], q[ft.0]);
				"sat ft1.y, ft1.y",
				"tex oc, ft1.xy, fs0 <2d,repeat,linear>",
			].join("\n"));
		}
		
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void 
		{
			super.fillResources(resources, resourceType);
			for each (var m:TextureResource in _mathTextures) {
				if (m != null) {
					resources[m] = true;
				}
			}
		}
		
		override protected function setupExtraUniforms(drawUnit:DrawUnit):void 
		{
			super.setupExtraUniforms(drawUnit);
			drawUnit.setTextureAt(1, _mathTextures[0]._texture);
			drawUnit.setTextureAt(2, _mathTextures[1]._texture);
			drawUnit.setVertexConstantsFromNumbers(4,  Math.PI / 2, Math.PI, Math.PI * 2);
			drawUnit.setFragmentConstantsFromNumbers(0, 1, 2, 0);
			drawUnit.setFragmentConstantsFromNumbers(1, 255 * 256 * 256 / 16777214.5, 255 * 256 / 16777214.5, 255 / 16777214.5);
			drawUnit.setFragmentConstantsFromTransform(2, _tilt);
		}
	}
}