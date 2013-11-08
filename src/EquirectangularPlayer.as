package  
{
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.core.View;
	import com.sitedaniel.view.components.LoadIndicator;
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.geom.*;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.BitmapTextureResourceLoader;
	import info.smoche.alternativa.TextureCamera3D;
	import info.smoche.utils.Utils;
	
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / Twitter:@suzumura_ss
	 */
	
	public class EquirectangularPlayer
	{
		protected var _width:Number;
		protected var _height:Number;
		protected var _parent:Sprite;
		protected var _stage3D:Stage3D;
		protected var _camera:TextureCamera3D;
		protected var _rootContainer:Object3D;
		protected var _fixedObjectContainer:Object3D;
		protected var _controller:PanoramaController;
		protected var _indicator:LoadIndicator;
		protected var _worldMesh:WorldMesh;
		protected var _options:Dictionary;
		
		static protected const _IDENTITY:Matrix3D = new Matrix3D();
		
		public function EquirectangularPlayer(width_:Number, height_:Number, parent:Sprite, options:Dictionary = null):void
		{
			_width = width_;
			_height = height_;
			_parent = parent;
			_options = options || new Dictionary();
			_indicator = new LoadIndicator(parent, width_ / 2.0, height_ / 2.0, 50, 30, 30, 4, 0xffffff, 2);
			_IDENTITY.identity();
			
			_stage3D = parent.stage.stage3Ds[0];
			
			// root
			_rootContainer = new Object3D();
			
			// fixed-objects
			_fixedObjectContainer = new Object3D();
			_rootContainer.addChild(_fixedObjectContainer);
			
			// camera
			_camera = new TextureCamera3D(1, 10000);
			_camera.view = new View(_width, _height, false, 0x202020, 0, 4);
			_rootContainer.addChild(_camera);
			
			// view
			if (_options["hideLogo"]) _camera.view.hideLogo();
			_parent.addChild(_camera.view);
			if (_options["showDiagram"]) _parent.addChild(_camera.diagram);
			
			// controller
			_controller = new PanoramaController(_parent.stage, _camera, 200, 3, -0.1, _options);
			
			// world-sphere
			_worldMesh = new WorldMesh(_options);
			_rootContainer.addChild(_worldMesh.mesh());
			_worldMesh.mesh().doubleClickEnabled = true;
			_worldMesh.mesh().addEventListener(MouseEvent3D.DOUBLE_CLICK, function(e:MouseEvent3D):void {
				_controller.lookAt(new Vector3D(e.localX, e.localY, e.localZ));
			});
			
			// upload
			uploadResources();
			
			// Setup Javascrit interfaces
			if (ExternalInterface.available) {
				try {
					ExternalInterface.addCallback("mousewheel", function(delta:Number):void {
						var e:MouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL, false, false, 0, 0, null, false, false, false, false, delta);
						onMouseWheel(e);
					});
					ExternalInterface.addCallback("rotate", function(yaw:Number, pitch:Number):void {
						rotate(Utils.to_rad(yaw), Utils.to_rad(pitch));
					});
					ExternalInterface.addCallback("load_image", function(sourceUrl:String, yaw_offset:Number):void {
						load(sourceUrl, yaw_offset);
					});
				} catch (x:Error) {
					Utils.Trace(x);
				}
			}
		}
		
		public function load(url:String, yaw_offset:Number):void
		{
			_parent.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			BitmapTextureResourceLoader.loadBitmapFromURL(url, function(bmp:BitmapData):void {
				applyBitmapToTexture(bmp);
				_worldMesh.mesh().rotationZ = Utils.to_rad(yaw_offset);
				uploadResources();
				
				if (_indicator) {
					_indicator.destroy();
					_indicator = null;
				}
				
				var js:String = _options["onLoadImageCompleted"];
				if (ExternalInterface.available && js) {
					ExternalInterface.call(js, url);
				}
				_parent.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}, function(e:Object):void {
				Utils.Trace(e);
			});
		}
		
		protected function applyBitmapToTexture(bitmap:BitmapData):void
		{
			_worldMesh.applyTexture(bitmap, _stage3D.context3D);
		}
		
		protected function uploadResources():void
		{
			for each (var res:Resource in _rootContainer.getResources(true)) {
				if (!res.isUploaded) {
					res.upload(_stage3D.context3D);
				}
			}
		}
		
		protected function onEnterFrame(e:Event):void
		{
			_width = _camera.view.width = _parent.stage.stageWidth;
			_height = _camera.view.height = _parent.stage.stageHeight;
			_controller.update();
			
			_fixedObjectContainer.matrix = _IDENTITY;
			_fixedObjectContainer.rotationY = -(_camera.rotationX + 1.56);
			_fixedObjectContainer.rotationZ = _camera.rotationZ + 1.576;
			_camera.render(_stage3D);
		}
		
		public function onMouseWheel(e:MouseEvent):void
		{
			_controller.onMouseWheel(e);
		}
		
		public function rotate(yaw:Number, pitch:Number):void
		{
			_controller.rotate(yaw, pitch);
		}
		
		protected function currentYaw():Number
		{
			return Utils.clipRadian(( Math.PI / 2 + _camera.rotationZ));
		}
		protected function currentPitch():Number
		{
			return Utils.clipRadian((_camera.rotationX + Math.PI / 2));
		}
	}
}