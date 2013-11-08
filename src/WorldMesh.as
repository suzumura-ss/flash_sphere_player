package
{
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.GeoSphere;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / Twitter:@suzumura_ss
	 */
	
	public class WorldMesh
	{
		protected var _self:Mesh = new GeoSphere(1000, 60, true);
		protected var _option:Dictionary;
		protected var _material:NonMipmapTextureMaterial;
		
		public function WorldMesh(option:Dictionary = null)
		{
			_option = option || new Dictionary();
		}
		
		public function applyTexture(bitmap:BitmapData, context3D:Context3D):void
		{
			var r:NonMipmapBitmapTextureResource = new NonMipmapBitmapTextureResource(bitmap, true);
			_material = new NonMipmapTextureMaterial(r, 1.0, context3D);
			_self.setMaterialToAllSurfaces(_material);
		}
		
		public function mesh():Mesh
		{
			return _self;
		}
		
		public function alpha(alpha:Number):void
		{
			_material.alpha = alpha;
		}
	}
}