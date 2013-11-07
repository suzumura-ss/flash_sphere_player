package  
{
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.GeoSphere;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.BitmapTextureResourceLoader;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	import info.smoche.alternativa.RenderTextureResource;
	import info.smoche.utils.Utils;
	
	/*
	 * 
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	public class EquirectangularMergePlayer extends EquirectangularPlayer 
	{
		protected var _baseBitmap:BitmapData = new BitmapData(1, 1, false, 0);
		protected var _paintBitmap:BitmapData = new BitmapData(1, 1, false, 0);
		protected var _maskBitmap:BitmapData;
		protected var _maskTexture:NonMipmapBitmapTextureResource;
		protected var _mergeMaterial:MergeTextureMaterial;
		protected var _beginPaint:Boolean = false;
		protected var _painting:Boolean = false;
		
		public function EquirectangularMergePlayer(width_:Number, height_:Number, parent:Sprite, options:Dictionary = null):void
		{
			super(width_, height_, parent, options);
			
			_maskBitmap = new BitmapData(512, 256, false, 0);
			_maskTexture = new NonMipmapBitmapTextureResource(_maskBitmap.clone(), true, false);
			
			var m:Mesh = new GeoSphere(10);
			m.setMaterialToAllSurfaces(new FillMaterial(0xff8080));
			m.x = 800;
			_rootContainer.addChild(m);
			
			// Setup Javascrit interfaces
			if (ExternalInterface.available) {
				try {
					ExternalInterface.addCallback("load_paint_image", function(sourceUrl:String, yaw_offset:Number):void {
						load2(sourceUrl, yaw_offset);
					});
				} catch (x:Error) {
					Utils.Trace(x);
				}
			}
		}
		
		protected function paintMask(e:MouseEvent3D):void
		{
			if (!_painting) return;
			
			if (e.shiftKey) {
				var yaw:Number = 1 - (Math.atan2(e.localY, e.localX) / Math.PI / 2 + 0.5);
				var r:Number = Math.sqrt(e.localX * e.localX + e.localY * e.localY);
				var pitch:Number = 1 - ( Math.atan2(e.localZ, r) / Math.PI + 0.5);
				
				var s:Shape = new Shape();
				var g:Graphics = s.graphics;
				g.lineStyle(0, 0xffffff);
				g.beginFill(0xffffff);
				g.drawEllipse(40, 20, 40, 20);
				g.endFill();
				trace(yaw.toFixed(2), pitch.toFixed(2), s.width, s.height);
				var m:Matrix = new Matrix();
				m.translate(_maskBitmap.width * yaw - s.width * 1.5, _maskBitmap.height * pitch - s.height * 1.5);
				_maskBitmap.draw(s, m);
				applyMaskBitmap();
			}
		}
		protected function startPaint(e:MouseEvent3D):void
		{
			_painting = true;
			if (e.shiftKey || e.ctrlKey || e.altKey) {
				_controller.disable();
				paintMask(e);
			}
		}
		protected function endPaint(e:MouseEvent3D):void
		{
			_painting = false;
			_controller.enable();
		}
		
		protected function applyMaskBitmap():void
		{
			_maskTexture = new NonMipmapBitmapTextureResource(_maskBitmap.clone(), true);
			_mergeMaterial.updateMaskTexture(_maskTexture);
			uploadResources();
		}
		
		protected function applyTextures():void
		{
			var baseTexture:NonMipmapBitmapTextureResource = new NonMipmapBitmapTextureResource(_baseBitmap.clone(), true);
			var paintTexture:NonMipmapBitmapTextureResource = new NonMipmapBitmapTextureResource(_paintBitmap.clone(), true);
			_maskTexture = new NonMipmapBitmapTextureResource(_maskBitmap.clone(), true);
			_mergeMaterial = new MergeTextureMaterial(baseTexture, paintTexture, _maskTexture, _stage3D.context3D);
			_worldMesh.mesh().setMaterialToAllSurfaces(_mergeMaterial);
			uploadResources();
			if (!_beginPaint) {
				_beginPaint = true;
				var m:Mesh = _worldMesh.mesh();
				m.addEventListener(MouseEvent3D.MOUSE_DOWN, startPaint);
				m.addEventListener(MouseEvent3D.MOUSE_MOVE, paintMask);
				m.addEventListener(MouseEvent3D.MOUSE_UP, endPaint);
				m.addEventListener(MouseEvent3D.MOUSE_OUT, endPaint);
				m.addEventListener(MouseEvent3D.MOUSE_OVER, endPaint);
			}
		}
		
		override protected function applyBitmapToTexture(bitmap:BitmapData):void 
		{
			_baseBitmap.dispose();
			_baseBitmap = bitmap;
			applyTextures();
		}
		
		public function load2(url:String, yaw_offset:Number):void
		{
			BitmapTextureResourceLoader.loadBitmapFromURL(url, function(bitmap:BitmapData):void {
				_paintBitmap.dispose();
				_paintBitmap = bitmap;
				applyTextures();
				var js:String = _options["onLoadImageCompleted"];
				if (ExternalInterface.available && js) {
					ExternalInterface.call(js, url);
				}
			}, function(e:Object):void {
				Utils.Trace(e);
			});
		}
	}
}