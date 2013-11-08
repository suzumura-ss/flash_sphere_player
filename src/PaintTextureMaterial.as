package  
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	
	use namespace alternativa3d;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class PaintTextureMaterial extends NonMipmapTextureMaterial 
	{
		protected var _brushTextures:Vector.<TextureResource>;
		
		/**
		 * 
		 * @param	renderTexture	再生表示するテクスチャ
		 * @param	brushTextures	ブラシテクスチャ
		 * @param	context3d
		 */
		public function PaintTextureMaterial(renderTexture:TextureResource, brushTextures:Vector.<TextureResource>, context3d:Context3D)
		{
			super(renderTexture, 1.0, context3d);
			_brushTextures = brushTextures;
		}
		
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void
		{
			super.fillResources(resources, resourceType);
			for each (var m:TextureResource in _brushTextures) {
				if (m != null) {
					resources[m] = true;
				}
			}
		}
	}
}