package info.smoche.alternativa
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Vector3D;
	
	use namespace alternativa3d;
	/**
	 * テクスチャにレンダリングできるCamera3D
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	public class TextureCamera3D extends Camera3D 
	{
		public const clearColor:Vector3D = new Vector3D();
		
		public function TextureCamera3D(nearClipping:Number, farClipping:Number)
		{
			super(nearClipping, farClipping);
		}
		
		/**
		 * Camera3DのもつContext3Dを返します
		 * nullの場合があります。
		 * @return
		 */
		public function context3D():Context3D
		{
			return super.context3D;
		}
		
		/**
		 * テクスチャへレンダリングします
		 * clearColorでclearします。
		 * @param	stage3D
		 * @param	texture					レンダリング先のTexture
		 * @param	enableDepthAndStencil
		 */
		public function renderToTexture(stage3D:Stage3D, texture:TextureBase, enableDepthAndStencil:Boolean=false):void
		{
			var ctx:Context3D = context3D();
			if (ctx) {
				ctx.setRenderToTexture(texture, enableDepthAndStencil);
				ctx.clear(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
				render(stage3D);
				ctx.setRenderToBackBuffer();
			}
		}
	}
}