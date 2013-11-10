package 
{
	import flash.display.*;
	import flash.display3D.Context3DProfile;
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
		protected var _player:EquirectangularPlayer;
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
			_stage3D.requestContext3D("auto", Context3DProfile.BASELINE_EXTENDED);
		}
		
		protected function onStage3DCreate(e:Event):void
		{
			_stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onStage3DCreate);
			
			var htmlParams:Object = LoaderInfo(root.loaderInfo).parameters;
			var sourceUrl:String = htmlParams["source"] || "forest.jpg";
			var playerMode:String = htmlParams["mode"] || "sphere_walker";
			var opt:Dictionary = new Dictionary();
			opt["showDiagram"] = (htmlParams["showDiagram"]=="true") || true;
			opt["hideLogo"] = (htmlParams["hideLogo"] == "true") || false;
			opt["cubic"] = htmlParams["cubic"] || false;
			opt["wheelControl"] = (htmlParams["wheelControl"] == "true") || true;
			opt["angle"] = Number(htmlParams["angle"]) || 60;
			opt["angleMax"] = Number(htmlParams["angleMax"]) || 120;
			opt["angleMin"] = Number(htmlParams["angleMin"]) || 30;
			opt["onLoadImageCompleted"] = htmlParams["on_ready"];
			opt["walkSpeed"] = htmlParams["walkSpeed"];
			opt["onWalked"] = htmlParams["on_walked"];
			
			var yaw_offset:Number = Number(htmlParams["yaw_offset"] || "0");
			var y:Number = -Utils.to_rad(Number(htmlParams["yaw"] || "0"));
			var p:Number = Utils.to_rad(Number(htmlParams["pitch"] || "0"));
			
			switch (playerMode) {
			case "sphere_walker":
				_player = new SphereWalkerPlayer(stage.stageWidth, stage.stageHeight, this, opt);
				break;
			case "sphere_merge":
				_player = new EquirectangularMergePlayer(stage.stageWidth, stage.stageHeight, this, opt);
				if (!ExternalInterface.available) {
					// for debug
					(_player as EquirectangularMergePlayer).load2("forest2.jpg", 0);
				}
				break;
			default:
				_player = new EquirectangularPlayer(stage.stageWidth, stage.stageHeight, this, opt);
				break;
			}
			_player.load(sourceUrl, yaw_offset);
			_player.rotate(y, p);
			
			var tilt:TiltFilter = new TiltFilter(_stage3D.context3D);
		}
	}
}
