package info.smoche.alternativa
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	
	use namespace alternativa3d;
	/**
	 * モノクロ表示するテクスチャマテリアル / アルファブレンド対応。
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	public class LuminanceAndAlphaTextureMaterial extends NonMipmapTextureMaterial
	{
		public function LuminanceAndAlphaTextureMaterial(texture:TextureResource, alpha:Number, context3d:Context3D)
		{
			super(texture, alpha, context3d);
		}
		
		override protected function loadProgram():void 
		{
			super.loadProgram();
			
			_fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, [
				"tex ft0, v0, fs0 <2d,linear,repeat>", // ft0 = sampler2d(fs0, v0[uv])
				// lum = 0.299r
				"mul ft0.x, ft0.x, fc0.x",
				// lum += 0.587g
				"mul ft0.y, ft0.y, fc0.y",
				"add ft0.x, ft0.x, ft0.y",
				// lum += 0.114b
				"mul ft0.z, ft0.z, fc0.z",
				"add ft0.x, ft0.x, ft0.z",
				// g = lum, b = lum
				"mov ft0.y, ft0.x",
				"mov ft0.z, ft0.x",
				// a = <_alpha>
				"mov ft0.w, fc0.w",
				"mov oc, ft0",
			].join("\n"));
		}
		
		override protected function setupExtraUniforms(drawUnit:DrawUnit):void 
		{
			super.setupExtraUniforms(drawUnit);
			drawUnit.setFragmentConstantsFromNumbers(0, 0.299, 0.587, 0.114, alpha);	// = fc0
		}
	}
}
