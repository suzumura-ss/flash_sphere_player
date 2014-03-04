package info.smoche.alternativa
{
	import alternativa.engine3d.resources.BitmapTextureResource;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import info.smoche.libWebp.Decode.WebP_decode;
	import info.smoche.ThetaEXIF;
	import info.smoche.utils.Utils;
	import mx.utils.Base64Decoder;
	/**
	 * BitmapTextureResourceローダー
	 * 		URLで指定したファイルをロードします
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	
	public class BitmapTextureResourceLoader 
	{
		static public var flipH:Boolean = false;		// 水平反転させる場合は true
		static public var useMipmap:Boolean = false;	// Mipmapを生成する場合は true
		
		public function BitmapTextureResourceLoader()
		{
		}
		
		static public function loadBitmapFromURL(url:String, result:Function, onerror:Function):void
		{
			var current_flipH:Boolean = flipH;
			var exif:ThetaEXIF;
			var onLoadByteArray:Function = function(bytes:ByteArray):void {
				exif = new ThetaEXIF(bytes);
			};
			var onFailed:Function = function(e:Event):void {
				if (onerror!=null) onerror(e);
			};
			var onSuccess:Function = function(bitmap:BitmapData):void {
				try {
					if (current_flipH) {
						bitmap = NonMipmapBitmapTextureResource.flipImage(bitmap);
					}
					result(bitmap, exif);
				} catch (e:SecurityError) {
					onFailed(e);
					return;
				}
			};
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
				var bitmap:BitmapData = (e.target.content as Bitmap).bitmapData;
				onSuccess(bitmap);
			});
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onFailed);
			
			var v:Array = url.split(":");
			if (v[0] == "javascript") {
				var method:String = v[1];
				try {
					url = ExternalInterface.call(method);
				} catch (e:Error) {
					onerror(e);
					return;
				}
				if (url) {
					v = url.split(":");
				} else {
					onerror("method '" + method + "' returned empty string.");
					return;
				}
			}
			if (v[0] == "data") {
				try {
					var decoder:Base64Decoder = new Base64Decoder();
					decoder.decode(url.split(",")[1]);
					var png:ByteArray = decoder.flush();
					onLoadByteArray(png);
					loader.loadBytes(png);
				} catch (e:Error) {
					onFailed(e);
				}
			} else if (url.length > 0) {
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
				urlLoader.addEventListener(Event.COMPLETE, function(e:Event):void {
					var bytes:ByteArray = urlLoader.data as ByteArray;
					onLoadByteArray(bytes);
					if (url.substr(url.length - 5) == ".webp") {
						var bitmap:BitmapData = WebP_decode(bytes);
						onSuccess(bitmap);
					} else {
						loader.loadBytes(bytes);
					}
				});
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onFailed);
				urlLoader.load(new URLRequest(url));
			} else {
				onerror("Empty data.");
			}
		}
		
		/**
		 * URLから画像をロードしてテクスチャを生成します
		 * @param	url
		 * 		"javascript:method_name" の場合、method_name() をコールバックしてその文字列を利用します。
		 * 		"data:..." の場合、"data:image/png;base64,"の後ろをBase64エンコードされたPNG画像とみなしてロードします。
		 * 		それ以外の場合はHTTPリクエストで画像を取得します。
		 * @param	result
		 * 		画像を取得してテクスチャリソースを生成できたらコールバックします。
		 * 		useMipmap = true のときは BitmapTextureResource と　ThetaEXIF を、
		 * 		useMipmap = false のときは NonMipmapBitmapTextureResource と　ThetaEXIF を引数にとります。
		 * @param	onerror
		 * 		エラーが起きた場合にコールバックします。
		 * 		文字列か Errorクラスを引数にとります。
		 */
		static public function loadURL(url:String, result:Function, onerror:Function):void
		{
			var current_mipmap:Boolean = useMipmap;
			loadBitmapFromURL(url, function(bitmap:BitmapData, exif:ThetaEXIF):void {
				if (current_mipmap) {
					result(new BitmapTextureResource(bitmap, true), exif);
				} else {
					result(new NonMipmapBitmapTextureResource(bitmap), exif);
				}
			}, onerror);
		}
	}
}