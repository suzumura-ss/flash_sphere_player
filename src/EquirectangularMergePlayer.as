package  
{
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.GeoSphere;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.textures.TextureBase;
	import flash.display3D.VertexBuffer3D;
	import flash.events.KeyboardEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.BitmapTextureResourceLoader;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	import info.smoche.stage3d.AGALGeometry;
	import info.smoche.stage3d.AGALProgram;
	import info.smoche.utils.Utils;
	
	/*
	 * 
	 * @author Toshiyuki Suzumura / @suzumura_ss
	 */
	public class EquirectangularMergePlayer extends EquirectangularPlayer 
	{
		protected var _baseBitmap:BitmapData = new BitmapData(1, 1, false, 0);
		protected var _paintBitmap:BitmapData = new BitmapData(1, 1, false, 0);
		protected var _maskTexture:Vector.<NonMipmapBitmapTextureResource>;
		protected var _maskIndex:uint = 0;
		protected var _mergeMaterial:MergeTextureMaterial;
		protected var _beginPaint:Boolean = false;
		protected var _painting:Boolean = false;
		
		public function EquirectangularMergePlayer(width_:Number, height_:Number, parent:Sprite, options:Dictionary = null):void
		{
			super(width_, height_, parent, options);
			
			initBrush();
			
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
		
		protected var _brush:AGALGeometry;
		protected var _copyBrush:AGALGeometry;
		protected var _brushProgram:AGALProgram;
		protected var _copyProgram:AGALProgram;
		protected function initBrush():void
		{
			var ctx:Context3D = _stage3D.context3D;
			
			var verts:Vector.<Number> = Vector.<Number>([
			//     x,    y,  z,	u, v
				-0.1, -0.05, 0,	0, 0,
				 0.1, -0.05, 0,	1, 0,
				 0.1,  0.05, 0,	1, 1,
				-0.1,  0.05, 0,	0, 1,
			]);
			var indexes:Vector.<uint> = Vector.<uint>([
				0, 1, 2,
				0, 2, 3,
			]);
			_brush = new AGALGeometry(ctx, verts, indexes);
			_brushProgram = new AGALProgram(ctx, [
				"#position=0",
				"add op, va0, vc0",
			], [
				"#color=0",
				"mov oc, fc0",
			]);
			
			verts = Vector.<Number>([
			//   x,  y, z,	u, v
				-1, -1, 0,	0, 0,
				 1, -1, 0,	1, 0,
				 1,  0, 0,	1, 1,
				-1,  0, 0,	0, 1,
			]);
			indexes = Vector.<uint>([
				0, 1, 2,
				0, 2, 3,
			]);
			_copyBrush = new AGALGeometry(ctx, verts, indexes);
			_copyProgram = new AGALProgram(ctx, [
				"#position=0",
				"add op, va0, vc0",
				"mov v0, va1",
			], [
				"#texture=0",
				"#color=0",
				"tex oc, v0, fs0 <2d,linear,repeat>",
			]);
		}
		
		static protected function mouseEvent3DToTexcel(e:MouseEvent3D):Point
		{
			var yaw:Number = 1 - (Math.atan2(e.localY, e.localX) / Math.PI / 2 + 0.5);
			var r:Number = Math.sqrt(e.localX * e.localX + e.localY * e.localY);
			var pitch:Number = 1 - ( Math.atan2(e.localZ, r) / Math.PI + 0.5);
			
			return new Point(yaw, pitch);
		}
		
		protected function paintMask(e:MouseEvent3D):void
		{
			if (!_painting || !e.shiftKey) return;
			var texel:Point = mouseEvent3DToTexcel(e);
			
			var ctx:Context3D;
			
			var prog:AGALProgram = _copyProgram;
			prog.context(function(ctx:Context3D):void {
				ctx.setRenderToTexture(_maskTexture[_maskIndex].texture());
				ctx.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				ctx.clear(0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH|Context3DClearMask.STENCIL);
				
				prog.setTexture("texture", _maskTexture[1 - _maskIndex].texture());
				prog.setNumbers("position", 1 - texel.x * 2, 1 - texel.y * 2, 0, 0);
				prog.setNumbers("color", 1, 0, 0, 0);
				prog.drawGeometry(_brush);
				
				ctx.setRenderToBackBuffer();
			});
			
			//_copyProgram.context(function(ctx:Context3D):void {
				//ctx.setRenderToTexture(_maskTexture[_maskIndex].texture());
				//ctx.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				//ctx.clear(0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH|Context3DClearMask.STENCIL);
				//
				//_copyProgram.setNumbers("position", 1 - texel.x * 2, 1 - texel.y * 2, 0, 0);
				//_copyProgram.setNumbers("color", 1, 0, 0, 0);
				//ctx.setTextureAt(0, _maskTexture[1].texture());
				//_copyProgram.drawGeometry(_brush);
				//
				//ctx.setRenderToBackBuffer();
			//})
			
			//_brushProgram.context(function(ctx:Context3D):void {
				//ctx.setRenderToTexture(_maskTexture[_maskIndex].texture());
				//ctx.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				//ctx.clear(0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH|Context3DClearMask.STENCIL);
				//
				//_brushProgram.setNumbers("position", 1 - texel.x * 2, 1 - texel.y * 2, 0, 0);
				//_brushProgram.setNumbers("color", 1, 0, 0, 0);
				//_brushProgram.drawGeometry(_brush);
				//
				//ctx.setRenderToBackBuffer();
			//});
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
		
		protected function applyTextures():void
		{
			var baseTexture:NonMipmapBitmapTextureResource = new NonMipmapBitmapTextureResource(_baseBitmap.clone(), true);
			var paintTexture:NonMipmapBitmapTextureResource = new NonMipmapBitmapTextureResource(_paintBitmap.clone(), true);
			_maskTexture = Vector.<NonMipmapBitmapTextureResource>([
				new NonMipmapBitmapTextureResource(new BitmapData(256, 256, false, 0)),
				new NonMipmapBitmapTextureResource(new BitmapData(256, 256, false, 0x800000)),
			]);
			_mergeMaterial = new MergeTextureMaterial(baseTexture, paintTexture, Vector.<TextureResource>(_maskTexture), _stage3D.context3D);
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