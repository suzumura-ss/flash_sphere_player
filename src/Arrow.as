package  
{
	import alternativa.engine3d.core.Camera3D;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	public class Arrow extends Sprite
	{
		protected var _yaw:Number;
		protected var _pitch:Number;
		protected var _width:Number;
		protected var _height:Number;
		
		[Embed(source = "arrow.png")] protected static const ARROW:Class;
		
		public function Arrow(yaw:Number, pitch:Number)
		{
			super();
			
			_yaw = Utils.clipRadian(Utils.to_rad(yaw));
			_pitch = Utils.clipRadian(Utils.to_rad(pitch));
			
			var bmp:Bitmap = new ARROW() as Bitmap;
			_width = bmp.width / 2;
			_height = bmp.height / 2;
			bmp.x = -_width;
			bmp.y = -_height;
			this.addChild(bmp);
		}
		
		public function moveForCamera(camera:Camera3D, stageWidth:Number, stageHeight:Number):void
		{
			var a:Number = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
			var fovY:Number = (camera.fov * ((stageWidth + _width*4) / a)) / 2;
			var fovP:Number = (camera.fov * ((stageHeight + _height*4) / a)) / 2;
			
			var dYaw:Number = Utils.clipRadian(_yaw - ( -Math.PI / 2 - camera.rotationZ));
			var dPitch:Number = Utils.clipRadian(_pitch - (camera.rotationX + Math.PI / 2));
			var insight:Boolean = (Math.abs(dYaw) < fovY && Math.abs(dPitch) < fovP);
			this.visible = !insight;
			
			if (insight) return;
			
			var x:Number = (dYaw / fovY + 1) * stageWidth / 2;
			var y:Number = (1 - dPitch / fovP) * stageHeight / 2;
			
			var u:Number = Math.abs(dYaw / Math.PI);
			y += u * stageHeight / 4;
			
			
			if (x < _width) x = _width;
			if (x > stageWidth - _width) x = stageWidth - _width;
			if (y < _height) y = _height;
			if (y > stageHeight - _height) y = stageHeight - _height;
			
			this.x = x;
			this.y = y;
			
			var r:Number = Utils.to_deg(Math.atan2(y - stageHeight / 2, x - stageWidth / 2));
			this.rotation = r + 90;
		}
	}
}