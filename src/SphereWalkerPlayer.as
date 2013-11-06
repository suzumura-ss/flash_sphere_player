package  
{
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Sprite3D;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / Twitter:@suzumura_ss
	 */
	
	public class SphereWalkerPlayer extends EquirectangularPlayer
	{
		protected var _nextMesh:WorldMesh;
		protected var _gates:Dictionary = new Dictionary;
		protected var _gatesRoot:Object3D;
		protected var _arrowsRoot:Sprite;
		protected var _targetGate:Gate;
		protected var _movingAlpha:Number;
		protected var _movingSpeed:Number = 0.05;
		
		public function SphereWalkerPlayer(width_:Number, height_:Number, parent:Sprite, options:Dictionary = null)
		{
			super(width_, height_, parent, options);
			
			_movingSpeed = _options["walkSpeed"] || 0.05;
			
			_gatesRoot = new Object3D();
			_rootContainer.addChild(_gatesRoot);
			
			_arrowsRoot = new Sprite();
			_parent.addChild(_arrowsRoot);
			
			_nextMesh = new WorldMesh(_options);
			_nextMesh.mesh().visible = false;
			_rootContainer.addChild(_nextMesh.mesh());
			
			_parent.addEventListener(Event.ENTER_FRAME, onEnterFrameForGateAnimation);
			
			_parent.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):void {
				if (e.buttonDown) updateArrows();
			});
			
			if (!ExternalInterface.available) {
				append_gate("name0", "forest2.jpg", 0, 0, 0, 2);
				//append_gate("name1", "forest2.jpg", 0, 180, 0, 2);
			}
		}
		
		protected function onGateClicked(e:MouseEvent3D, g:Gate):void
		{
			_gatesRoot.visible = false;
			_arrowsRoot.visible = false;
			
			_movingAlpha = 0.0;
			
			_targetGate = g;
			_nextMesh.applyTexture(g.bitmapData().clone(), _stage3D.context3D);
			_nextMesh.mesh().rotationZ = Utils.to_rad(g.tilt_yaw());
			_nextMesh.alpha(1.0);
			_nextMesh.mesh().visible = true;
			uploadResources();
			
			_controller.disable();
			_parent.addEventListener(Event.ENTER_FRAME, onEnterFrameForMoveSphere);
		}
		
		protected function onEnterFrameForGateAnimation(e:Event):void
		{
			for each(var g:Gate in _gates) {
				var m:Mesh = g.mesh();
				m.rotationX += 0.02;
				m.rotationZ += 0.02;
			}
		}
		
		protected function onEnterFrameForMoveSphere(e:Event):void
		{
			_movingAlpha += _movingSpeed;
			if (_movingAlpha > 1.0) {
				_parent.removeEventListener(Event.ENTER_FRAME, onEnterFrameForMoveSphere);
				_controller.enable();
				setup_next_sphere();
				return;
			}
			
			_nextMesh.alpha(1.0);
			_worldMesh.alpha(1.0 - _movingAlpha * 2.0);
			
			// _alpha: 0.0 -> 1.0
			var j:Number = -_targetGate.distance() * _movingAlpha * 256;
			_worldMesh.mesh().x = _targetGate.pos().x * j;
			_worldMesh.mesh().y = _targetGate.pos().y * j;
			_worldMesh.mesh().z = _targetGate.pos().z * j;
			
			var k:Number = _targetGate.distance() * (1.0 - _movingAlpha) * 256;
			_nextMesh.mesh().x = _targetGate.pos().x * k;
			_nextMesh.mesh().y = _targetGate.pos().y * k;
			_nextMesh.mesh().z = _targetGate.pos().z * k;
		}
		
		protected function currentYaw():Number
		{
			return Utils.clipRadian(( Math.PI / 2 + _camera.rotationZ));
		}
		protected function currentPitch():Number
		{
			return Utils.clipRadian((_camera.rotationX + Math.PI / 2));
		}
		
		protected function updateArrows():void
		{
			for each(var g:Gate in _gates) {
				g.arrow().moveForCamera(_camera, _parent.stage.stageWidth, _parent.stage.stageHeight);
			}
		}
		
		protected function setup_next_sphere():void
		{
			var g:Gate = _targetGate;
			_targetGate = null;
			
			_worldMesh.applyTexture(g.bitmapData(), _stage3D.context3D);
			_worldMesh.mesh().rotationZ = Utils.to_rad(g.tilt_yaw());
			
			for each (var m:WorldMesh in [_worldMesh, _nextMesh]) {
				m.alpha(1);
				m.mesh().x = 0;
				m.mesh().y = 0;
				m.mesh().z = 0;
			}
			_worldMesh.mesh().visible = true;
			_nextMesh.mesh().visible = false;
			
			uploadResources();
			remove_all_gates();
			_gatesRoot.visible = true;
			_arrowsRoot.visible = true;
			
			var js:String = _options["onWalked"];
			if (ExternalInterface.available && js) {
				ExternalInterface.call(js, g.name(), g.yaw(), g.pitch());
			}
		}
		
		public function append_gate(name:String, url:String, tilt_yaw:Number, yaw:Number, pitch:Number, distance:Number):void
		{
			var pos:LookAt3D = new LookAt3D(Utils.to_rad(-yaw), Utils.to_rad(pitch));
			var box:Box = new Box();
			var fm:FillMaterial = new FillMaterial(0x86c351, 1);
			box.setMaterialToAllSurfaces(fm);
			var wire:WireFrame = WireFrame.createEdges(box, 0xFFFFFF, 1, 2)
			wire.scaleX = wire.scaleY = wire.scaleZ = 1.1;
			box.addChild(wire);
			box.x = pos.x * 900;
			box.y = pos.y * 900;
			box.z = pos.z * 900;
			_gatesRoot.addChild(box);
			
			var arrow:Arrow = new Arrow(yaw, pitch);
			arrow.moveForCamera(_camera, _parent.stage.stageWidth, _parent.stage.stageHeight);
			_arrowsRoot.addChild(arrow);
			
			var g:Gate = new Gate(name, url, box, arrow, pos, tilt_yaw, yaw, pitch, distance);
			g.mesh().addEventListener(MouseEvent3D.CLICK, function(e:MouseEvent3D):void {
				onGateClicked(e, g);
			});
			_gates[name] = g;
			
			arrow.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				rotate(-Utils.to_rad(yaw), Utils.to_rad(pitch));
				updateArrows();
			});
			
			uploadResources();
		}
		
		public function remove_gate(name:String):void
		{
			var m:Mesh = _gates[name].mesh();
			if (m) {
				_gatesRoot.removeChild(m);
			}
			var a:Arrow = _gates[name].arrow();
			if (a) {
				_arrowsRoot.removeChild(a);
			}
			_gates[name] = null;
		}
		
		public function remove_all_gates():void
		{
			for each(var g:Gate in _gates) {
				_gatesRoot.removeChild(g.mesh());
				_arrowsRoot.removeChild(g.arrow());
			}
			_gates = new Dictionary();
		}
	}
}