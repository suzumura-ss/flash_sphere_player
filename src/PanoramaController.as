package  
{
	import alternativa.engine3d.controllers.SimpleObjectController;
	import alternativa.engine3d.core.Camera3D;
	import flash.display.InteractiveObject;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import info.smoche.utils.Utils;

	/**
	 * ...
	 * @author Toshiyuki Suzumura  / Twitter:@suzumura_ss
	 */
	
	public class PanoramaController extends SimpleObjectController 
	{
		protected var _camera:Camera3D;
		protected var _lookAtWithRotation:LookAt3D = new LookAt3D();
		protected var _angle:Number;
		protected var _angleMax:Number;
		protected var _angleMin:Number;
		
		public function PanoramaController(eventSource:InteractiveObject, camera:Camera3D, speed:Number, speedMultiplier:Number=3, mouseSensitivity:Number=1, options:Dictionary = null) 
		{
			super(eventSource, camera, speed, speedMultiplier, mouseSensitivity);
			var center:Number = -Math.PI / 2.0;
			this.maxPitch = center + Math.PI / 2.0;
			this.minPitch = center - Math.PI / 2.0;
			this.lookAt(_lookAtWithRotation);
			
			_camera = camera;
			_angle = options["angle"] || 60;
			_angleMax = options["angleMax"] || 120;
			_angleMin = options["angleMin"] || 30;
			if (options["wheelControl"]) {
				eventSource.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			_camera.fov = Utils.to_rad(_angle);
		}
		
		protected var _onShift:Function = super.moveUp;
		public function onShift(callback:Function):void {
			this.bindKey(Keyboard.SHIFT, SimpleObjectController.ACTION_UP);
			_onShift = callback;
		}
		override public function moveUp(value:Boolean):void 
		{
			_onShift(value);
		}
		
		protected var _onAlt:Function = super.moveDown;
		public function onAlt(callback:Function):void {
			this.bindKey(Keyboard.ALTERNATE, SimpleObjectController.ACTION_DOWN);
			_onAlt = callback;
		}
		override public function moveDown(value:Boolean):void 
		{
			_onAlt(value);
		}
		
		public function onMouseWheel(e:MouseEvent):void
		{
			_angle += (e.delta > 0) ? 1: -1;
			_angle = Math.max(Math.min(_angle, _angleMax), _angleMin);
			_camera.fov = Utils.to_rad(_angle);
		}
		
		public function angle(a:Number):void
		{
			_angle = a;
			_camera.fov = Utils.to_rad(_angle);
		}
		
		public function rotate(yaw:Number, pitch:Number):void
		{
			_lookAtWithRotation.yaw = yaw;
			_lookAtWithRotation.pitch = pitch;
			lookAt(_lookAtWithRotation);
		}
		
		override public function lookAt(point:Vector3D):void 
		{
			_lookAtWithRotation.lookAt(point);
			super.lookAt(_lookAtWithRotation);
		}
	}
}