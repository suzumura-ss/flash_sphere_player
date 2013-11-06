package info.smoche.alternativa
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix;
	
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
		}
		
		override public function upload(context3D:Context3D):void
		{
			if (_texture != null) {
				_texture.dispose();
			}
			if (_resizeForGPU) {
				_data = resizeImage2n(_data);
			}
			if (_flipH) {
				_data = flipImage(_data);
				_flipH = false;
			}
			_texture = context3D.createTexture(_data.width, _data.height, Context3DTextureFormat.BGRA, false);
			Texture(_texture).uploadFromBitmapData(_data, 0);
		}
		
		static public function resizeImage2n(source:BitmapData):BitmapData
		{
			var wLog2Num:Number = Math.log(source.width)/Math.LN2;
			var hLog2Num:Number = Math.log(source.height)/Math.LN2;
			var wLog2:int = Math.ceil(wLog2Num);
			var hLog2:int = Math.ceil(hLog2Num);
			if (wLog2 != wLog2Num || hLog2 != hLog2Num || wLog2 > 11 || hLog2 > 11) {
				wLog2 = (wLog2 > 11) ? 11 : wLog2;
				hLog2 = (hLog2 > 11) ? 11 : hLog2;
				var bitmap:BitmapData = new BitmapData(1 << wLog2, 1 << hLog2, source.transparent, 0);
				const mat:Matrix = new Matrix(1, 0, 0, 1);
				mat.a = (1 << wLog2)/source.width;
				mat.d = (1 << hLog2)/source.height;
				bitmap.draw(source, mat, null, null, null, true);
				source.dispose();
				return bitmap;
			}
			return source;
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