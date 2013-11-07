package info.smoche.alternativa
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Point;
	
	use namespace alternativa3d;
	
	/**
	 * 描画用テクスチャリソース
	 * 		Mipmapを持ちません。
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	public class RenderTextureResource extends TextureResource
	{
		protected var _size:Point;
		protected var _context3D:Context3D;
		
		public function RenderTextureResource(size:Point)
		{
			_size = size;
		}
		
		public static function createFromTexture(texture:TextureBase):RenderTextureResource
		{
			var t:RenderTextureResource = new RenderTextureResource(null);
			t._texture = texture;
			return t;
		}
		
		override public function upload(context3D:Context3D):void
		{
			_context3D = context3D;
			if (_size) {
				if (_texture != null) {
					_texture.dispose();
				}
				_texture = context3D.createTexture(_size.x, _size.y, Context3DTextureFormat.BGRA, false);
			}
		}
		
		public function attach(enableDepthAndStencil:Boolean=false, antiAlias:int=0, surfaceSelector:int=0):void
		{
			_context3D.setRenderToTexture(_texture, enableDepthAndStencil, antiAlias, surfaceSelector);
		}
		
		public function texture():TextureBase
		{
			return _texture;
		}
	}
}