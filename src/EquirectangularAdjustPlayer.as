package  
{
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.objects.Mesh;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import info.smoche.utils.Utils;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class EquirectangularAdjustPlayer extends EquirectangularPlayer 
	{
		protected var _enable_controller:Boolean = true;
		protected var _dragStart:Point = null;
		protected var _tilt:Matrix3D = new Matrix3D();
		protected var _label:TextField = new TextField();
		protected var _yaw_slider:FlatSlider = new FlatSlider( -90, 90, 0, 300);
		protected var _guideCircle:Sprite;
		
		public function EquirectangularAdjustPlayer(width_:Number, height_:Number, parent:Sprite, options:Dictionary = null)
		{
			var wheelControl:Boolean = options["wheelControl"] || false;
			options["wheelControl"] = false;
			super(width_, height_, parent, options);
			
			// カメラ設定：デフォルトのコントローラは無効、WorldMeshを前方に。
			_controller.disable();
			_camera.fov = Utils.to_rad(120);
			_worldMesh.mesh().x = 1300;
			
			// UI初期化
			_label.width = 400;
			_label.height = 64;
			_label.defaultTextFormat = new TextFormat("Courier New", 12, 0xffffff, true);
			_label.textColor = uint( -1);
			_label.mouseEnabled = false;
			_parent.addChild(_label);
			
			_yaw_slider.y = 50;
			_yaw_slider.onEditStart = onYawEditStart;
			_yaw_slider.onChanged = onYawChanged;
			_yaw_slider.onEditEnd = onYawEditEnd;
			_parent.addChild(_yaw_slider);
			
			var x:Number = 0;
			var b:SimpleButton;
			(b = appendResetButton(" O ", _parent, x)).addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_tilt.identity();
				applyTilt();
			});
			x += b.width + 8;
			(b = appendResetButton(" X+90 ", _parent, x)).addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_tilt.identity();
				_tilt.appendRotation(90, Vector3D.X_AXIS);
				applyTilt();
			});
			x += b.width + 8;
			(b = appendResetButton(" X-90 ", _parent, x)).addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_tilt.identity();
				_tilt.appendRotation( -90, Vector3D.X_AXIS);
				applyTilt();
			});
			x += b.width + 8;
			(b = appendResetButton(" Y+90 ", _parent, x)).addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_tilt.identity();
				_tilt.appendRotation(90, Vector3D.Y_AXIS);
				applyTilt();
			});
			x += b.width + 8;
			(b = appendResetButton(" Y-90 ", _parent, x)).addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_tilt.identity();
				_tilt.appendRotation( -90, Vector3D.Y_AXIS);
				applyTilt();
			});
			x += b.width + 8;
			(b = appendResetButton(" Z+90 ", _parent, x)).addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_tilt.identity();
				_tilt.appendRotation(90, Vector3D.Z_AXIS);
				applyTilt();
			});
			x += b.width + 8;
			(b = appendResetButton(" Z-90 ", _parent, x)).addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				_tilt.identity();
				_tilt.appendRotation( -90, Vector3D.Z_AXIS);
				applyTilt();
			});
			x += b.width + 8;
			
			// ガイドライン
			_guideCircle = new Sprite();
			_guideCircle.mouseEnabled = false;
			var g:Graphics = _guideCircle.graphics;
			g.beginFill(0, 0);
			g.lineStyle(1, uint( -1), 0.8);
			const size:Number = 2000;
			for (var r:Number = size; r > 100; r /= 1.5) {
				g.drawCircle(size, size, r);
			}
			g.drawRect(0, size, size * 2, 0);
			g.drawRect(size, 0, 0, size * 2);
			g.endFill();
			updateGuide();
			_parent.stage.addEventListener(Event.RESIZE, updateGuide);
			_parent.addChild(_guideCircle);
			
			// マウスイベントの初期化
			if (wheelControl) {
				_parent.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			_parent.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			_parent.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			_parent.stage.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			_parent.stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseUp);
			_parent.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			// Sphere方位初期化
			_tilt.identity();
			//_tilt.appendRotation(90, Vector3D.Y_AXIS);
			applyTilt();
		}
		
		static protected function appendResetButton(text:String, parent:Sprite, x:Number):SimpleButton
		{
			var tf:TextField = new TextField();
			tf.defaultTextFormat = new TextFormat("Courier New", 12, 0, true);
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.text = text;
			var b1:Bitmap = new Bitmap(new BitmapData(tf.width, tf.height, false, 0xc0c0c0));
			b1.bitmapData.draw(tf);
			var b2:Bitmap = new Bitmap(new BitmapData(tf.width, tf.height, false, 0x808080));
			b2.bitmapData.draw(tf);
			var reset:SimpleButton = new SimpleButton(b1, b1, b2, b2);
			reset.y = 90;
			reset.x = x;
			parent.addChild(reset);
			return reset;
		}
		
		protected function updateGuide(e:Event = null):void
		{
			_guideCircle.x = (_parent.stage.stageWidth - _guideCircle.width) / 2;
			_guideCircle.y = (_parent.stage.stageHeight - _guideCircle.height) / 2;
		}
		
		protected function updateLabel():void
		{
			var Q:Vector3D = _tilt.transformVector(new Vector3D(0, 0, 1));
			var p:Number = Math.atan2(Q.x, Q.z);
			var r:Number = Math.atan2( -Q.y, Q.z);
			_label.text = "( " + Q.x.toFixed(2)
						+ ", " + Q.y.toFixed(2)
						+ ", " + Q.z.toFixed(2) + " ) "
						+ "p: " + Utils.to_deg(p).toFixed(1) + ", "
						+ "r: " + Utils.to_deg(r).toFixed(1) + "\n"
		}
		
		protected function applyTilt():void
		{
			var mat:Matrix3D = _tilt.clone();
			mat.appendTranslation(1300, 0, 0);
			_worldMesh.mesh().matrix = mat;
			updateLabel();
		}
		
		override public function onMouseWheel(e:MouseEvent):void 
		{
			if (!_enable_controller) return;
			_worldMesh.mesh().x += (e.delta > 0)? 10: -10;
			trace(_worldMesh.mesh().x);
		}
		
		protected function onMouseDown(e:MouseEvent):void
		{
			if (!_enable_controller) return;
			_dragStart = new Point(e.localX, e.localY);
			onMouseMove(e);
		}
		
		protected function onMouseUp(e:MouseEvent):void
		{
			if (!_enable_controller) return;
			_dragStart = null;
		}
		
		protected function onMouseMove(e:MouseEvent):void
		{
			if (!_enable_controller) return;
			if (!_dragStart) return;
			var dX:Number = _dragStart.x - e.localX;
			var dY:Number = _dragStart.y - e.localY;
			
			_tilt.appendRotation( dX * Math.PI * 100 / _parent.stage.stageWidth, Vector3D.Z_AXIS);
			_tilt.appendRotation( -dY * Math.PI * 100 / _parent.stage.stageHeight, Vector3D.Y_AXIS);
			applyTilt();
			_dragStart.x = e.localX;
			_dragStart.y = e.localY;
		}
		
		private var _last_yaw:Number;
		protected function onYawEditStart():void
		{
			_enable_controller = false;
			_last_yaw = 0;
		}
		protected function onYawEditEnd():void
		{
			_enable_controller = true;
			_yaw_slider.value = 0;
		}
		protected function onYawChanged(val:Number):void
		{
			_tilt.appendRotation(val-_last_yaw, Vector3D.X_AXIS);
			applyTilt();
			_last_yaw = val;
		}
	}
}