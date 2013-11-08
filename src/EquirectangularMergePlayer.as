package  
{
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.GeoSphere;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DClearMask;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
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
		protected var _baseBitmap:BitmapData;
		protected var _paintBitmap:BitmapData;
		protected var _renderTexture:NonMipmapBitmapTextureResource;
		protected var _baseTexture:NonMipmapBitmapTextureResource;
		protected var _paintTexture:NonMipmapBitmapTextureResource;
		protected var _paintMaterial:PaintTextureMaterial;
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
		protected function initBrush():void
		{
			var ctx:Context3D = _stage3D.context3D;
			
			var verts:Vector.<Number> = Vector.<Number>([
			//  x,       y,     z,
				-0.01/2, -0.01, 0,
				 0.01/2, -0.01, 0,
				 0.01/2,  0.01, 0,
				-0.01/2,  0.01, 0,
			]);
			var indexes:Vector.<uint> = Vector.<uint>([
				0, 1, 2,
				0, 2, 3,
			]);
			_brush = new AGALGeometry(ctx, verts, indexes, false);
			
			verts = Vector.<Number>([
			//  x, y, z,
				0, 0, 0,
				1, 0, 0,
				1, 1, 0,
				0, 1, 0,
			]);
			_copyBrush = new AGALGeometry(ctx, verts, indexes, false);
			
			_brushProgram = new AGALProgram(ctx, [
				"#texcel=0",
				"#make_uv=1", 			// [1, 1]
				// uv = (1 - (vert + texcel))
				"add vt0, va0, vc0",
				"sub vt0.xy, vc1.xy, vt0.xy",
				"mov v0, vt0",
				// xy = (vert + texcel - 0.5)*2
				"#make_pos=2", 			// [0.5, 0.5, 2]
				"add vt0, va0, vc0",
				"sub vt0.xy, vt0.xy, vc2.xy",
				"mul vt0.xy, vt0.xy, vc2.z",
				"mov op, vt0",
			], [
				"#texture=0",
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
		
		protected function paintBrush(e:MouseEvent3D):void
		{
			if (!_painting || (!e.shiftKey && !e.ctrlKey)) return;
			
			var texel:Point = mouseEvent3DToTexcel(e);
			var prog:AGALProgram = _brushProgram;
			prog.context(function(ctx:Context3D):void {
				ctx.setRenderToTexture(_renderTexture.texture());
				ctx.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				ctx.clear(0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH|Context3DClearMask.STENCIL);
				
				prog.setTexture("texture", ((e.shiftKey)? _paintTexture: _baseTexture).texture());
				prog.setNumbers("texcel", 1 - texel.x, 1 - texel.y, 0, 0);
				prog.setNumbers("make_uv",  1, 1);
				prog.setNumbers("make_pos", 0.5, 0.5, 2);
				prog.drawGeometry(_brush);
				
				ctx.setRenderToBackBuffer();
			});
		}
		
		protected function loadRenderTextureOnce(e:Event):void
		{
			_parent.removeEventListener(Event.ENTER_FRAME, loadRenderTextureOnce);
			reloadRenderTexture();
		}
		
		protected function reloadRenderTexture():void
		{
			var prog:AGALProgram = _brushProgram;
			prog.context(function(ctx:Context3D):void {
				ctx.setRenderToTexture(_renderTexture.texture());
				ctx.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				ctx.clear(0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH|Context3DClearMask.STENCIL);
				
				prog.setTexture("texture", _baseTexture.texture());
				prog.setNumbers("texcel", 0, 0);
				prog.setNumbers("make_uv",  1, 1);
				prog.setNumbers("make_pos", 0.5, 0.5, 2);
				prog.drawGeometry(_copyBrush);
				
				ctx.setRenderToBackBuffer();
			});
			
			trace("reloaded.");
		}
		
		protected function startPaint(e:MouseEvent3D):void
		{
			_painting = true;
			if (e.shiftKey || e.ctrlKey || e.altKey) {
				_controller.disable();
				paintBrush(e);
			}
		}
		protected function endPaint(e:MouseEvent3D):void
		{
			_painting = false;
			_controller.enable();
		}
		
		protected function setupMaterial():void
		{
			trace("setup material.");
			_renderTexture = new NonMipmapBitmapTextureResource(new BitmapData(_baseBitmap.width, _baseBitmap.height, false, 0));
			_baseTexture = new NonMipmapBitmapTextureResource(_baseBitmap.clone());
			_paintTexture = new NonMipmapBitmapTextureResource(_paintBitmap.clone());
			_paintMaterial = new PaintTextureMaterial(
									_renderTexture,
									Vector.<TextureResource>([_baseTexture, _paintTexture]),
									_stage3D.context3D);
			_worldMesh.mesh().setMaterialToAllSurfaces(_paintMaterial);
			uploadResources();
			_parent.addEventListener(Event.ENTER_FRAME, loadRenderTextureOnce);
			
			if (!_beginPaint) {
				_beginPaint = true;
				var m:Mesh = _worldMesh.mesh();
				m.addEventListener(MouseEvent3D.MOUSE_DOWN, startPaint);
				m.addEventListener(MouseEvent3D.MOUSE_MOVE, paintBrush);
				m.addEventListener(MouseEvent3D.MOUSE_UP, endPaint);
				m.addEventListener(MouseEvent3D.MOUSE_OUT, endPaint);
				m.addEventListener(MouseEvent3D.MOUSE_OVER, endPaint);
			}
		}
		
		override protected function applyBitmapToTexture(bitmap:BitmapData):void 
		{
			if (_baseBitmap) _baseBitmap.dispose();
			_baseBitmap = bitmap;
			if (_paintBitmap) setupMaterial();
		}
		
		public function load2(url:String, yaw_offset:Number):void
		{
			BitmapTextureResourceLoader.loadBitmapFromURL(url, function(bitmap:BitmapData):void {
				if (_paintBitmap) _paintBitmap.dispose();
				_paintBitmap = bitmap;
				if (_baseBitmap) setupMaterial();
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