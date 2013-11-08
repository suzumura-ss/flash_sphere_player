package  
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.textures.TextureBase;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	
	use namespace alternativa3d;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class MergeTextureMaterial extends NonMipmapTextureMaterial 
	{
		protected var _paintTexture:TextureResource;
		protected var _maskTexture:Vector.<TextureResource>;
		protected var _maskIndex:uint = 0;
		
		/**
		 * 
		 * @param	baseTexture		下地のテクスチャ
		 * @param	paintTexture	上書きするテクスチャ
		 * @param	maskTexture		上書きテクスチャを表示する領域(R成分), 最低２枚
		 * @param	context3d
		 */
		public function MergeTextureMaterial(baseTexture:TextureResource, paintTexture:TextureResource, maskTexture:Vector.<TextureResource>, context3d:Context3D)
		{
			super(baseTexture, 1.0, context3d);
			_paintTexture = paintTexture;
			_maskTexture = maskTexture;
		}
		
		public function assignMaskTexture(index:uint):void
		{
			if (index >= _maskTexture.length) {
				throw RangeError("index less than (" + _maskTexture.length +")");
			}
			_maskIndex = index;
		}
		
		override protected function loadProgram():void 
		{
			super.loadProgram();
			
			_fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, [
				"tex ft0, v0, fs0 <2d,linear,repeat>",	// ft0 = <baseTexture>
				"tex ft1, v0, fs1 <2d,linear,repeat>",	// ft1 = <paintTexture>
				"tex ft2, v0, fs2 <2d,linear,repeat>",	// ft2.x = <mask>
				"sub ft2.y, fc0.x, ft2.x",			// ft2.y: 1-mask
				"mul ft0.xyzw, ft0.xyzw, ft2.y",	// ft0 = base*(1-mask)
				"mul ft1.xyzw, ft1.xyzw, ft2.x",	// ft1 = paint*mask
				"add ft0, ft0, ft1",				// ft0 = base*(1-mask)+paint*mask
				"mov ft0.w, fc0.w",					// ft4.alpha = <alpha>
				"mov oc, ft0",
			].join("\n"));
		}
		
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void
		{
			super.fillResources(resources, resourceType);
			if (_paintTexture != null) {
				resources[_paintTexture] = true;
			}
			for each (var m:TextureResource in _maskTexture) {
				if (m != null) {
					resources[m] = true;
				}
			}
		}
		
		override protected function setupExtraUniforms(drawUnit:DrawUnit):void 
		{
			/* vc0[modelViewProjectionMatrix], va0[xyz], va1[uv] は設定済み */
			drawUnit.setFragmentConstantsFromNumbers(0, 1, 0, 0, alpha);	// fc0 = {x:1, y:0, z:0, w:alpha}
			drawUnit.setTextureAt(0, _texture._texture);
			drawUnit.setTextureAt(1, _paintTexture._texture);
			drawUnit.setTextureAt(2, _maskTexture[_maskIndex]._texture);
			drawUnit.blendSource = Context3DBlendFactor.SOURCE_ALPHA;
			drawUnit.blendDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
		}
	}
}