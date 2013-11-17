package  
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.SimpleButton;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class VFlatSlider extends FlatSlider 
	{
		
		public function VFlatSlider(min:Number, max:Number, init:Number, width:Number)
		{
			super(min, max, init, width);
		}
		
		override protected function lineBitmap():Bitmap 
		{
			return new Bitmap(new BitmapData(32, _width + 32, false, 0x86c351));
		}
		
		override protected function textLabel():TextField 
		{
			var l:TextField = new TextField();
			l.text = "0.00";
			l.width = 32;
			l.height = 20;
			l.x = 0;
			l.y = (_width + 32 - l.height) / 2;
			l.mouseEnabled = false;
			return l;
		}
		
		override protected function toValue(e:MouseEvent):Number 
		{
			return (e.localY - 16) * (_max - _min) / _width + _min;
		}
		
		override protected function updateButton():void 
		{
			_label.text = _current.toFixed(2);
			_button.y = (_current - _min) * _width / (_max - _min);
		}
	}
}