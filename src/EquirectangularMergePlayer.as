package  
{
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.GeoSphere;
	import alternativa.engine3d.primitives.Plane;
	import alternativa.engine3d.resources.TextureResource;
	import com.sitedaniel.view.components.LoadIndicator;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.JPEGEncoderOptions;
	import flash.display.Loader;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DClearMask;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.ui.MouseCursorData;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import info.smoche.alternativa.BitmapTextureResourceLoader;
	import info.smoche.alternativa.NonMipmapBitmapTextureResource;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	import info.smoche.alternativa.RenderTextureResource;
	import info.smoche.stage3d.AGALGeometry;
	import info.smoche.stage3d.AGALProgram;
	import info.smoche.ThetaEXIF;
	import info.smoche.TiltFilter;
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
		
		protected var _adjustMaterial:AdjustTextuteMaterial;
		protected var _adjustMesh:Mesh;
		protected var _adjusting:Boolean = false;
		protected var _adjust_yaw:Number = 0;
		
		[Embed(source = "resources/Floppy.png")] protected static const FLOPPY_N:Class;
		[Embed(source = "resources/Floppy_a.png")] protected static const FLOPPY_A:Class;
		[Embed(source = "resources/Folder.png")] protected static const FOLDER_N:Class;
		[Embed(source = "resources/Folder_a.png")] protected static const FOLDER_A:Class;
		[Embed(source = "resources/Folder2.png")] protected static const FOLDER2_N:Class;
		[Embed(source = "resources/Folder2_a.png")] protected static const FOLDER2_A:Class;
		[Embed(source = "resources/check.png")] protected static const CHECK:Class;
		[Embed(source = "resources/brush.png")] protected static const BRUSH:Class;
		[Embed(source = "resources/erase.png")] protected static const ERASE:Class;
		
		/* TiltFilter実験 */
		protected var _tilt:TiltFilterAS;
		protected var _source:BitmapData;
		protected var _tiltResult:Bitmap;
		//protected var _tiltTexture:NonMipmapBitmapTextureResource;
		//protected var _tiltMaterial:AGALTiltMaterial
		protected function tilt(yaw:Number, pitch:Number, roll:Number):void
		{
			if (_tiltResult) {
				_parent.removeChild(_tiltResult);
			}
			var START:Date = new Date();
			if (0) {
				// use AS3 version
				_tiltResult = new Bitmap(TiltFilter.tilt(yaw, pitch, roll, _source));
			} else {
				// use CrossBridge version
				var t:BitmapData = TiltFilter.tilt(yaw, pitch, roll, _source);
				_tiltResult = new Bitmap(t);
			}
			//Utils.Trace([_source.width, _source.height, (new Date()).getTime() - START.getTime()]);
			
			_tiltResult.x = 40;
			_tiltResult.y = 150;
			_parent.addChild(_tiltResult);
			
			//_tiltMaterial.setCompass(yaw, pitch, roll);
		}
		
		//protected var _plane:Plane;
		public function EquirectangularMergePlayer(width_:Number, height_:Number, parent:Sprite, options:Dictionary = null):void
		{
			super(width_, height_, parent, options);
			initBrush();
			initMouseCursor();
			initImageIoUI();
			initAdjustUI();
			
			/* TiltFilter実験 */
			//_tiltTexture = new NonMipmapBitmapTextureResource(new BitmapData(2, 1, true, 0));
			//_plane = new Plane(2, 2);
			//_plane.setMaterialToAllSurfaces(new NonMipmapTextureMaterial(_tiltTexture, 1, _stage3D.context3D));
			//_plane.rotationZ = Math.PI / 2;
			//_plane.rotationX = Math.PI / 2;
			//_plane.x = 300;
			//_rootContainer.addChild(_plane);
			//uploadResources();
			
			// Setup Javascrit interfaces
			if (ExternalInterface.available) {
				try {
					ExternalInterface.addCallback("load_paint_image", function(sourceUrl:String, yaw_offset:Number = 0):void {
						load2(sourceUrl, yaw_offset);
					});
				} catch (x:Error) {
					Utils.Trace(x);
				}
			}
		}
		
		protected function initImageIoUI():void
		{
			var base:BitmapData = null;
			var altb:BitmapData = null;
			var checkBase:Bitmap = new CHECK() as Bitmap;
			var checkAltb:Bitmap = new CHECK() as Bitmap;
			
			var onLoad:Function = function():void {
				if (base && altb) {
					var timer:Timer = new Timer(100, 1);
					timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
						applyBitmapToTexture(base);
						applyBitmapToPaint(altb);
						base = altb = null;
						checkBase.visible = checkAltb.visible = false;
					});
					timer.start();
				}
			}
			
			var bmp0:Bitmap = new FOLDER_N() as Bitmap;
			var bmp1:Bitmap = new FOLDER_A() as Bitmap;
			var button:SimpleButton = new SimpleButton(bmp0, bmp0, bmp1, bmp0);
			button.addEventListener(MouseEvent.CLICK, function(e:Event):void {
				loadImageFor(function(bitmap:BitmapData):void {
					base = bitmap;
					checkBase.visible = true;
					onLoad();
				});
			});
			_parent.addChild(button);
			checkBase.visible  = false;
			_parent.addChild(checkBase);
			
			bmp0 = new FOLDER2_N() as Bitmap;
			bmp1 = new FOLDER2_A() as Bitmap;
			button = new SimpleButton(bmp0, bmp0, bmp1, bmp0);
			button.addEventListener(MouseEvent.CLICK, function(e:Event):void {
				loadImageFor(function(bitmap:BitmapData):void {
					altb = bitmap;
					checkAltb.visible = true;
					onLoad();
				});
			});
			button.x = button.width;
			_parent.addChild(button);
			checkAltb.x = button.width;
			checkAltb.visible  = false;
			_parent.addChild(checkAltb);
			
			bmp0 = new FLOPPY_N() as Bitmap;
			bmp1 = new FLOPPY_A() as Bitmap;
			button = new SimpleButton(bmp0, bmp0, bmp1, bmp0);
			button.addEventListener(MouseEvent.CLICK, onSaveImage);
			button.x = button.width * 2;
			_parent.addChild(button);
			
			var box:TextField = new TextField();
			box.width = 200;
			box.height = button.height;
			box.wordWrap = true;
			box.background = true;
			box.backgroundColor = 0xc0c0c0;
			box.border = true;
			box.borderColor = 0x808080;
			box.mouseEnabled = false;
			box.text = "1. Load image (1)\n2. Load image (2)\n3. Paint with SHIFT/ALT + mouse.\n4. Save it.";
			box.x = button.width * 3;
			_parent.addChild(box);
		}
		
		protected function initAdjustUI():void
		{
			var adjust_pitch:Number = 0;
			var adjust_roll:Number = 0;
			var sliderY:FlatSlider = new FlatSlider( -90, 90, 0, 270);
			var sliderR:FlatSlider = new FlatSlider( -90, 90, 0, 270);
			var sliderP:VFlatSlider = new VFlatSlider( -90, 90, 0, 270);
			sliderY.y = 64;
			sliderR.y = 64 + 40;
			sliderP.y = 64 + 40 * 2;
			_parent.addChild(sliderY);
			_parent.addChild(sliderR);	sliderR.visible = true;
			_parent.addChild(sliderP);	sliderP.visible = true;
			
			var enable_controller:Function = function():void {
				_controller.enable();
			}
			var disable_controler:Function = function():void {
				_controller.disable();
			}
			
			sliderY.onEditStart = disable_controler;
			sliderY.onChanged = function(value:Number):void {
				_adjust_yaw = Utils.to_rad( -value);
				_adjustMaterial.yaw_offset = _adjust_yaw;
				_worldMesh.mesh().visible = false;
				if (_adjustMesh) _adjustMesh.visible = true;
				
				tilt(_adjust_yaw, adjust_pitch, adjust_roll);
			}
			sliderY.onEditEnd = function():void {
				_worldMesh.mesh().visible = true;
				if (_adjustMesh) _adjustMesh.visible = false;
				enable_controller();
			}
			
			sliderP.onEditStart = disable_controler;
			sliderP.onChanged = function(value:Number):void {
				adjust_pitch = Utils.to_rad( -value);
				tilt(_adjust_yaw, adjust_pitch, adjust_roll);
			}
			sliderP.onEditEnd = enable_controller;
			
			sliderR.onEditStart = disable_controler;
			sliderR.onChanged = function(value:Number):void {
				adjust_roll = Utils.to_rad( -value);
				tilt(_adjust_yaw, adjust_pitch, adjust_roll);
			}
			sliderR.onEditEnd = enable_controller;
		}
		
		protected function initMouseCursor():void
		{
			var brush:MouseCursorData = new MouseCursorData();
			brush.data = Vector.<BitmapData>([(new BRUSH() as Bitmap).bitmapData]);
			var eraee:MouseCursorData = new MouseCursorData();
			eraee.data = Vector.<BitmapData>([(new ERASE() as Bitmap).bitmapData]);
			
			Mouse.registerCursor("application:brush", brush);
			Mouse.registerCursor("application:erase", eraee);
		}
		
		protected function updateMouseImage(e:MouseEvent3D):void
		{
			if (e.shiftKey) {
				Mouse.cursor = "application:brush";
			} else if (e.altKey) {
				Mouse.cursor = "application:erase";
			} else {
				Mouse.cursor = MouseCursor.AUTO;
			}	
		}
		
		protected function loadImageFor(callback:Function):void
		{
			var fr:FileReference = new FileReference();
			fr.addEventListener(Event.COMPLETE, function(e:Event):void {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
					try {
						var bitmap:BitmapData = (e.target.content as Bitmap).bitmapData;
						callback(bitmap);
					} catch (e:SecurityError) {
						Utils.Trace(e);
					}
				});
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {
					Utils.Trace(e);
				});
				loader.loadBytes(fr.data);
			});
			fr.addEventListener(Event.SELECT, function(e:Event):void {
				fr.load();
			});
			try {
				fr.browse([new FileFilter("Image(*.jpg,*.png)", "*.jpg;*.png")]);
			} catch (e:Error) {
				Utils.Trace(["FileReference#browse", e]);
			}
		}
		
		protected function onSaveImage(e:Event):void
		{
			var w:Number = _parent.stage.stageWidth;
			var h:Number = _parent.stage.stageHeight;
			_indicator = new LoadIndicator(_parent, w / 2, h / 2, w / 4, 30, w / 6, 4, 0xffffff, 2);
			
			var bmp:BitmapData = textureToImage();
			var bytes:ByteArray = bmp.encode(new Rectangle(0, 0, bmp.width, bmp.height), new JPEGEncoderOptions());
			var fr:FileReference = new FileReference();
			var fin:Function = function(e:Event):void {
				_indicator.destroy();
				_indicator = null;
			};
			fr.addEventListener(Event.COMPLETE, fin);
			fr.addEventListener(Event.CANCEL, fin);
			fr.save(bytes, "Equirectangular.jpg");
		}
		
		protected var _brush:AGALGeometry;
		protected var _copyBrush:AGALGeometry;
		protected var _brushProgram:AGALProgram;
		protected function initBrush():void
		{
			var ctx:Context3D = _stage3D.context3D;
			
			// 楕円ブラシ
			var verts:Vector.<Number> = Vector.<Number>([0, 0, 0]);
			var indexes:Vector.<uint> = Vector.<uint>([]);
			var faces:Number = 16;
			for (var i:Number = 0; i < faces; i++) {
				var s:Number = i * Math.PI * 2 / faces;
				var x:Number = Math.cos(s) * 0.02 / 2;
				var y:Number = Math.sin(s) * 0.02;
				verts.push(x, y, 0);
				if (i < faces - 1) {
					indexes.push(0, i + 1, i + 2);
				} else {
					indexes.push(0, i + 1, 1);
				}
			}
			_brush = new AGALGeometry(ctx, verts, indexes, false);
			
			// 全面コピー用のブラシ
			verts = Vector.<Number>([
			//  x, y, z,
				0, 0, 0,
				1, 0, 0,
				1, 1, 0,
				0, 1, 0,
			]);
			indexes = Vector.<uint>([
				0, 1, 2,
				0, 2, 3,
			]);
			_copyBrush = new AGALGeometry(ctx, verts, indexes, false);
			
			// ブラシプログラム
			// texcel(x:0~1, y:0~1)で位置を指定
			_brushProgram = new AGALProgram(ctx, [
				"#texcel=0",
				"#make_uv=1", 			// [1, 1, x_mag, y_mag]
				"#make_pos=2", 			// [0.5, 0.5, 2]
				
				// vert /= mag, vert += texcel [vt0=vert]
				"mov vt0, va0",
				"div vt0.x, vt0.x, vc1.z",
				"div vt0.y, vt0.y, vc1.w",
				"add vt0, vt0, vc0",
				
				// uv = 1 - vert
				"mov vt1, vt0",
				"sub vt1.xy, vc1.xy, vt0.xy",
				"mov v0, vt1",
				
				// xy = (vert - 0.5)*2
				"sub vt0.xy, vt0.xy, vc2.xy",
				"mul vt0.xy, vt0.xy, vc2.z",
				"mov op, vt0",
			], [
				"#texture=0",
				"#offset=0",
				"add ft0, v0, fc0",
				"tex oc, ft0, fs0 <2d,linear,repeat>",
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
			updateMouseImage(e);
			if (!_painting || (!e.shiftKey && !e.altKey)) return;
			
			var texel:Point = mouseEvent3DToTexcel(e);
			var y_mag:Number = Math.PI / 3 / _camera.fov;
			var x_mag:Number = Math.cos(Math.PI * (texel.y - 0.5)) * y_mag;
			if (x_mag < 0.001) x_mag = 0.001;
			
			var prog:AGALProgram = _brushProgram;
			prog.context(function(ctx:Context3D):void {
				ctx.setRenderToTexture(_renderTexture.texture());
				ctx.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				ctx.clear(0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH|Context3DClearMask.STENCIL);
				
				prog.setTexture("texture", ((e.shiftKey)? _paintTexture: _baseTexture).texture());
				prog.setNumbers("make_uv",  1, 1, x_mag, y_mag);
				prog.setNumbers("make_pos", 0.5, 0.5, 2);
				prog.setNumbers("texcel", 1 - texel.x, 1 - texel.y, 0, 0);
				prog.setNumbers("offset", (e.shiftKey)? _adjust_yaw:0);
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
				ctx.clear(0, 0, 0, 0);
				
				prog.setTexture("texture", _baseTexture.texture());
				prog.setNumbers("make_uv", 1, 1, 1, 1);
				prog.setNumbers("make_pos", 0.5, 0.5, 2);
				prog.setNumbers("texcel", 0, 0);
				prog.drawGeometry(_copyBrush);
				
				ctx.setRenderToBackBuffer();
			});
		}
		
		protected function textureToImage():BitmapData
		{
			var result:BitmapData = new BitmapData(_baseBitmap.width, _baseBitmap.height, false, 0);
			var prog:AGALProgram = _brushProgram;
			prog.context(function(ctx:Context3D):void {
				ctx.configureBackBuffer(_baseBitmap.width, _baseBitmap.height, 4);
				ctx.setRenderToBackBuffer();
				ctx.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				ctx.clear(0, 0, 0, 0);
				prog.setTexture("texture", _renderTexture.texture());
				prog.setNumbers("make_uv", 1, 1, 1, 1);
				prog.setNumbers("make_pos", 0.5, 0.5, 2);
				prog.setNumbers("texcel", 0, 0);
				prog.drawGeometry(_copyBrush);
				ctx.drawToBitmapData(result);
				
				ctx.configureBackBuffer(_parent.stage.stageWidth, _parent.stage.stageHeight, 4);
			});
			return result;
		}
		
		protected function startPaint(e:MouseEvent3D):void
		{
			updateMouseImage(e);
			_painting = true;
			if (e.shiftKey || e.ctrlKey || e.altKey) {
				_controller.disable();
				paintBrush(e);
			}
		}
		protected function endPaint(e:MouseEvent3D):void
		{
			updateMouseImage(e);
			_painting = false;
			_controller.enable();
		}
		
		protected function setupMaterial():void
		{
			if (_source) _source.dispose();
			if (1) {
				_source = NonMipmapBitmapTextureResource.resizeImage(_baseBitmap.clone(), 1024, 512);
			} else {
				_source = _baseBitmap.clone();
			}
			
			//if (_tiltTexture) {
				//_tiltTexture.dispose();
			//}
			//_tiltTexture = new NonMipmapBitmapTextureResource(_baseBitmap.clone());
			//_tiltMaterial = new AGALTiltMaterial(_tiltTexture, _stage3D.context3D);
			//_plane.setMaterialToAllSurfaces(_tiltMaterial);
			
			var stub:BitmapData = new BitmapData(_baseBitmap.width, _baseBitmap.height, false, 0);
			if (_renderTexture) {
				_renderTexture.dispose();
				_baseTexture.dispose();
				_paintTexture.dispose();
			}
			_renderTexture = new NonMipmapBitmapTextureResource(stub.clone());
			_baseTexture = new NonMipmapBitmapTextureResource(_baseBitmap.clone());
			_paintTexture = new NonMipmapBitmapTextureResource(_paintBitmap.clone());
			_paintMaterial = new PaintTextureMaterial(
									_renderTexture,
									Vector.<TextureResource>([_baseTexture, _paintTexture]),
									_stage3D.context3D);
			_worldMesh.mesh().setMaterialToAllSurfaces(_paintMaterial);
			
			if (_adjustMesh) {
				_rootContainer.removeChild(_adjustMesh)
			}
			_adjustMaterial = new AdjustTextuteMaterial(_renderTexture, _paintTexture, 0.5, _stage3D.context3D);
			_adjustMesh = new GeoSphere(800, 8, true, _adjustMaterial);
			_adjustMesh.visible = false;
			_rootContainer.addChild(_adjustMesh);
			
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
				_controller.onShift(function(v:Boolean):void {
					var e:MouseEvent3D = new MouseEvent3D("FromKey");
					e.shiftKey = v;
					e.altKey = false;
					updateMouseImage(e);
				})
				_controller.onAlt(function(v:Boolean):void {
					var e:MouseEvent3D = new MouseEvent3D("FromKey")
					e.shiftKey = false;
					e.altKey = v;
					updateMouseImage(e);
				})
			}
		}
		
		override protected function applyBitmapToTexture(bitmap:BitmapData):void 
		{
			if (_baseBitmap) _baseBitmap.dispose();
			_baseBitmap = bitmap;
			if (_paintBitmap) setupMaterial();
		}
		
		protected function applyBitmapToPaint(bitmap:BitmapData):void
		{
			if (_paintBitmap) _paintBitmap.dispose();
			_paintBitmap = bitmap;
			if (_baseBitmap) setupMaterial();
		}
		
		public function load2(url:String, yaw_offset:Number = 0):void
		{
			BitmapTextureResourceLoader.loadBitmapFromURL(url, function(bitmap:BitmapData, exif:ThetaEXIF):void {
				applyBitmapToPaint(bitmap);
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