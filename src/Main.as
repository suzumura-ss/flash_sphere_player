package 
{
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import info.smoche.utils.Utils;
	
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / Twitter:@suzumura_ss
	 */
	
	[SWF(width = "640", height = "480", frameRate = "30", backgroundColor = "#000000")]
	
	public class Main extends Sprite 
	{
		protected var _player:SphereWalkerPlayer;
		protected var _stage3D:Stage3D;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		public function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			_stage3D = stage.stage3Ds[0];
			_stage3D.addEventListener(Event.CONTEXT3D_CREATE, onStage3DCreate);
			_stage3D.requestContext3D();
		}
		
		protected function onStage3DCreate(e:Event):void
		{
			_stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onStage3DCreate);
			
			var htmlParams:Object = LoaderInfo(root.loaderInfo).parameters;
			var sourceUrl:String = htmlParams["source"] || "forest.jpg";
			var opt:Dictionary = new Dictionary();
			opt["showDiagram"] = (htmlParams["showDiagram"]=="true") || false;
			opt["hideLogo"] = (htmlParams["hideLogo"] == "true") || false;
			opt["cubic"] = htmlParams["cubic"] || false;
			opt["wheelControl"] = (htmlParams["wheelControl"] == "true") || false;
			opt["angle"] = Number(htmlParams["angle"]) || 60;
			opt["angleMax"] = Number(htmlParams["angleMax"]) || 120;
			opt["angleMin"] = Number(htmlParams["angleMin"]) || 30;
			opt["onLoadImageCompleted"] = htmlParams["on_ready"];
			opt["walkSpeed"] = htmlParams["walkSpeed"];
			opt["onWalked"] = htmlParams["on_walked"];
			
			var yaw_offset:Number = Number(htmlParams["yaw_offset"] || "0");
			var y:Number = Number(htmlParams["yaw"] || "0");
			var p:Number = Number(htmlParams["pitch"] || "0");
			
			_player = new SphereWalkerPlayer(stage.stageWidth, stage.stageHeight, this, opt);
			_player.load(sourceUrl, yaw_offset);
			_player.rotate(y, p);
			
			if (ExternalInterface.available) {
				try {
					ExternalInterface.addCallback("mousewheel", function(delta:Number):void {
						var e:MouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL, false, false, 0, 0, null, false, false, false, false, delta);
						_player.onMouseWheel(e);
					});
					ExternalInterface.addCallback("rotate", function(yaw:Number, pitch:Number):void {
						_player.rotate(yaw, pitch);
					});
					ExternalInterface.addCallback("load_image", function(sourceUrl:String, yaw_offset:Number):void {
						_player.load(sourceUrl, yaw_offset);
					});
					ExternalInterface.addCallback("append_gate", function(name:String, url:String, tilt_yaw:Number, yaw:Number, pitch:Number, distance:Number):void {
						_player.append_gate(name, url, tilt_yaw, yaw, pitch, distance);
					});
					ExternalInterface.addCallback("remove_gate", function(name:String):void {
						_player.remove_gate(name);
					});
				} catch (x:Error) {
					Utils.Trace(x);
				}
			}
		}
	}
}
