package  
{
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.GeoSphere;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import info.smoche.utils.Quaternion;
	import info.smoche.utils.Utils;

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
		
		protected var _locus:Object3D;
		
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
				append_gate("name0", "forest2.jpg", 0, 30, 0, 2);
				append_gate("name1", "forest2.jpg", 0, 50, -60, 2);
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
			initLocus();
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
		
		protected function updateArrows():void
		{
			for each(var g:Gate in _gates) {
				g.arrow().moveForCamera(_camera, _parent.stage.stageWidth, _parent.stage.stageHeight);
			}

			var y:Quaternion = Quaternion.Rotate(AxisZ, currentYaw());
			var p:Quaternion = Quaternion.Rotate(AxisY, currentPitch());
			var Q:Quaternion = y.mul(p);
			var P:Quaternion = new Quaternion(0, 1, 0, 0);
			var S:Quaternion = Q.conjugate().mul(P).mul(Q);
			//trace(S.x.toFixed(2), S.y.toFixed(2), S.z.toFixed(2));
		}
		
		protected function initLocus():void
		{
			if (_locus) {
				_rootContainer.removeChild(_locus);
			}
			_locus = new Object3D();
			_rootContainer.addChild(_locus);
		}
		
		protected static const AxisX:Vector3D = new Vector3D(1, 0, 0);
		protected static const AxisY:Vector3D = new Vector3D(0, 1, 0);
		protected static const AxisZ:Vector3D = new Vector3D(0, 0, 1);
		protected var _startQ:Quaternion;
		protected var _endQ:Quaternion;
		protected var _step:Number;
		protected var _speed:Number;
		protected function startRotate(gate:Gate):void
		{
			initLocus();
			var p:Quaternion, y:Quaternion;
			
			// start Quat
			y = Quaternion.Rotate(AxisZ, currentYaw());
			p = Quaternion.Rotate(AxisY, currentPitch());
			_startQ = y.mul(p);
			
			// end Quat
			var yaw:Number = Utils.to_rad(gate.yaw());
			var pitch:Number = Utils.to_rad(gate.pitch());
			y = Quaternion.Rotate(AxisZ, -yaw);
			p = Quaternion.Rotate(AxisY, pitch);
			_endQ = y.mul(p);
			
			// distance
			var P:Quaternion = new Quaternion(0, 1, 0, 0);
			var S:Quaternion = _startQ.mul(P).mul(_startQ.conjugate());
			var E:Quaternion = _endQ.mul(P).mul(_endQ.conjugate());
			_speed = 1.0 / S.sub(E).length() / 20; // 移動速度（ほぼ）一定
			
			// 中間点を計算して
			var mid:Quaternion = _startQ.slerp(_endQ, 0.5);
			var Q:Quaternion = mid.mul(P).mul(mid.conjugate());
			var s:Vector3D = S.toVector3D();
			var e:Vector3D = E.toVector3D();
			var q:Vector3D = Q.toVector3D();
			var se:Number = Math.acos(s.dotProduct(e));
			var qe:Number = Math.acos(q.dotProduct(e));
			// 中間点が外側にある場合は終了位置へのQuatを逆転
			if (Math.abs(se / 2 - qe) > 0.01) {
				_endQ = _endQ.neg();
			}
			
			// 中間点を再計算
			mid = _startQ.slerp(_endQ, 0.5);
			Q = mid.mul(P).mul(mid.conjugate());
			s = S.toVector3D();
			e = E.toVector3D();
			q = Q.toVector3D();
			se = Math.acos(s.dotProduct(e));
			var cros:Vector3D = s.crossProduct(q);
			// 矢印の方向と回転が逆の場合は終了位置へのQuatを逆転
			Utils.Trace([cros, gate.arrow().x, _parent.stage.stageWidth]);
			if ((gate.arrow().rightClipped() && cros.z > 0) || (gate.arrow().leftClipped() && cros.z < 0)) {
				_endQ = _endQ.neg();
			}
			
			// run
			_step = 0.0;
			_parent.addEventListener(Event.ENTER_FRAME, onEnterFrameForRotate);
		}
		
		protected function onEnterFrameForRotate(e:Event):void
		{
			_step += _speed;
			if (_step < 1.0) {
				var q:Quaternion = _startQ.slerp(_endQ, _step);
				rotate(q.yaw(), q.pitch());
				
				var P:Quaternion = new Quaternion(0, 1, 0, 0);
				var S:Quaternion = q.mul(P).mul(q.conjugate());
				//trace(S.x.toFixed(2), S.y.toFixed(2), S.z.toFixed(2));
				
				var m:Mesh = new GeoSphere(10);
				m.setMaterialToAllSurfaces(new FillMaterial(0xff4040));
				m.x = S.x*900;
				m.y = S.y*900;
				m.z = -S.z*900;
				_locus.addChild(m);
			} else {
				rotate(_endQ.yaw(), _endQ.pitch());
				_parent.removeEventListener(Event.ENTER_FRAME, onEnterFrameForRotate);
			}
			uploadResources();
			updateArrows();
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
			
			remove_all_gates();
			initLocus();
			_gatesRoot.visible = true;
			_arrowsRoot.visible = true;
			uploadResources();
			
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
				startRotate(g);
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