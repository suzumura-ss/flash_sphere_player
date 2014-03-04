package  
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Dictionary;
	import info.smoche.utils.Utils;
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	public class EquirectangularVideoPlayer extends EquirectangularPlayer 
	{
		protected var _video:Video;
		
		public function EquirectangularVideoPlayer(width_:Number, height_:Number, parent:Sprite, options:Dictionary = null):void
		{
			super(width_, height_, parent, options);
		}
		
		override public function load(url:String, yaw_offset:Number):void 
		{
			_parent.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			var connection:NetConnection = new NetConnection();
			connection.connect(null);
			connection.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent):void {
				Utils.Trace(["connection.NetStatusEvent: ",  e.info]);
			});
			connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent):void {
				Utils.Trace(["connection.SecurityErrorEvent: ", e.text]);
			});
			
			var stream:NetStream = new NetStream(connection);
			stream.client = this;
			stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			
			_video = new Video(2048, 1024);
			_video.attachNetStream(stream);
			_video.addEventListener(Event.ENTER_FRAME, function(e:Event):void {
				var v:Video = e.target as Video;
				var bitmap:BitmapData = new BitmapData(v.width, v.height);
				bitmap.draw(v);
				applyBitmapToTexture(bitmap);
				uploadResources();
			});
			stream.play(url);
			
			var js:String = _options["onLoadImageCompleted"];
			if (ExternalInterface.available && js) {
				ExternalInterface.call(js, url);
			}
			_parent.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function onMetaData(e:Object):void
		{
			trace("video.onMetaData width: " + e.width +", height:" + e.height + ", duration:" + Math.floor(e.duration) + "sec");
			if (_indicator) {
				_indicator.destroy();
				_indicator = null;
			}
		}
		
		public function onPlayStatus(e:Object):void
		{
			trace("onPlayStatus: ", e);
		}
		
		private function netStatusHandler(e:NetStatusEvent):void
		{
			switch(e.info.level) {
			case "error":
				Utils.Trace(["netStatusHandler:[error] ", e.info]);
				break;
			case "status":
				if (e.info.code == "NetStream.Play.Stop") {
					e.target.seek(0);
				} else {
					trace("netStatusHandler:[status] ", e.info);
				}
				break;
			default:
				trace("netStatusHandler: ", e, e.info);
				break;
			}
		}
	}
}