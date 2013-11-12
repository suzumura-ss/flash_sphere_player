package info.smoche.alternativa
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	use namespace alternativa3d;
	/**
	 * Mipmapを生成しないBitmapテクスチャリソース
	 * 注意：通常のTextureResourceはMipmapを要求します。
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	public class NonMipmapBitmapTextureResource extends TextureResource 
	{
		protected var _data:BitmapData;
		protected var _flipH:Boolean = false;
		protected var _resizeForGPU:Boolean = true;
		protected const _size:Point = new Point();
		protected var _context3D:Context3D;

		/**
		 * 
		 * @param	bitmapData		ロードするBitmapData
		 * @param	flipH			左右に反転させる場合は true
		 * @param	resizeForGPU	2^nにリサイズする場合は true
		 */
		public function NonMipmapBitmapTextureResource(bitmapData:BitmapData, flipH:Boolean = false, resizeForGPU:Boolean = true)
		{
			_data = bitmapData;
			_flipH = flipH;
			_resizeForGPU = resizeForGPU;
			_size.x = bitmapData.width;
			_size.y = bitmapData.height;
		}
		
		public function attach(enableDepthAndStencil:Boolean=false, antiAlias:int=0, surfaceSelector:int=0):void
		{
			_context3D.setRenderToTexture(_texture, enableDepthAndStencil, antiAlias, surfaceSelector);
		}
		
		public function texture():TextureBase
		{
			return _texture;
		}
		
		public function attachBitmap(bitmap:BitmapData, flipH:Boolean = false):void
		{
			if ((_data.width != bitmap.width) || (_data.height != bitmap.height)) {
				bitmap = resizeImage(bitmap, _data.width, _data.height);
			}
			if (flipH) {
				bitmap = flipImage(bitmap);
			}
			Texture(_texture).uploadFromBitmapData(bitmap, 0);
			_data.dispose();
			_data = bitmap;
		}
		
		override public function upload(context3D:Context3D):void
		{
			_context3D = context3D;
			
			if (_texture != null) {
				_texture.dispose();
			}
			if (_resizeForGPU) {
				_data = resizeImage2n(_data);
				_size.x = _data.width;
				_size.y = _data.height;
			}
			if (_flipH) {
				_data = flipImage(_data);
				_flipH = false;
			}
			_texture = context3D.createTexture(_data.width, _data.height, Context3DTextureFormat.BGRA, true);
			Texture(_texture).uploadFromBitmapData(_data, 0);
		}
		
		static public var MAX_SIZE:uint = 11; // 2^11
		static public function resizeImage2n(source:BitmapData):BitmapData
		{
			var wLog2Num:Number = Math.log(source.width)/Math.LN2;
			var hLog2Num:Number = Math.log(source.height)/Math.LN2;
			var wLog2:int = Math.ceil(wLog2Num);
			var hLog2:int = Math.ceil(hLog2Num);
			if (wLog2 != wLog2Num || hLog2 != hLog2Num || wLog2 > 11 || hLog2 > 11) {
				wLog2 = (wLog2 > MAX_SIZE) ? MAX_SIZE : wLog2;
				hLog2 = (hLog2 > MAX_SIZE) ? MAX_SIZE : hLog2;
				return resizeImage(source, 1 << wLog2, 1 << hLog2);
			}
			return source;
		}
		
		static public function resizeImage(source:BitmapData, width:Number, height:Number):BitmapData
		{
			var bitmap:BitmapData = new BitmapData(width, height, source.transparent, 0);
			const mat:Matrix = new Matrix(1, 0, 0, 1);
			mat.a = width/source.width;
			mat.d = height/source.height;
			bitmap.draw(source, mat, null, null, null, true);
			source.dispose();
			return bitmap;
		}
		
		static public function flipImage(source:BitmapData):BitmapData
		{
			var bitmap:BitmapData = new BitmapData(source.width, source.height);
			var mat:Matrix = new Matrix( -1, 0, 0, 1, source.width, 0);
			bitmap.draw(source, mat);
			source.dispose();
			return bitmap;
		}
	}
}