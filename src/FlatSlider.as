package  
{
	import alternativa.engine3d.controllers.SimpleObjectController;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class FlatSlider extends Sprite 
	{
		[Embed(source = "resources/circle.png")] protected static const CIRCLE:Class;
		
		protected var _width:Number
		protected var _min:Number;
		protected var _max:Number;
		protected var _current:Number;
		
		public var onChanged:Function = function(value:Number):void {}
		public var onEditEnd:Function = function():void {}
		
		protected function buttonBitmap():Bitmap
		{
			return new CIRCLE() as Bitmap;
		}
		
		protected function lineBitmap():Bitmap
		{
			return new Bitmap(new BitmapData(_width + 32, 32, false, 0x86c351));
		}
		
		protected function textLabel():TextField
		{
			var l:TextField = new TextField();
			l.text = "0.00";
			l.width = 50;
			l.height = 20;
			l.x = (_width + 32 - l.width) / 2;
			l.y = (32 - l.height) / 2;
			l.mouseEnabled = false;
			return l;
		}
		
		protected function toValue(e:MouseEvent):Number
		{
			return (e.localX - 16) * (_max - _min) / _width + _min;
		}
		
		protected function updateButton(button:SimpleButton, label:TextField):void
		{
			label.text = _current.toFixed(2);
			button.x = (_current - _min) * _width / (_max - _min);
		}
		
		public function FlatSlider(min:Number, max:Number, init:Number, width:Number, controller:SimpleObjectController)
		{
			super();
			
			_min = min;
			_max = max;
			_current = init;
			_width = width;
			
			var bmp:Bitmap = lineBitmap();
			var line:SimpleButton = new SimpleButton(bmp, bmp, bmp, bmp);
			line.alpha = 0.5;
			addChild(line);
			
			bmp = buttonBitmap();
			var button:SimpleButton = new SimpleButton(bmp, bmp, bmp, bmp);
			button.mouseEnabled = false;
			addChild(button);
			
			var label:TextField = textLabel();
			addChild(label);
			
			updateButton(button, label);
			
			var dragging:Boolean = false;
			var e:MouseEvent;
			var move:Function = function(e:MouseEvent):void {
				if (dragging) {
					_current = Math.min(_max, Math.max(_min, toValue(e)));
					updateButton(button, label);
					onChanged(_current);
				}
			}
			var start:Function = function(e:MouseEvent):void {
				dragging = true;
				controller.disable();
				move(e);
			}
			var end:Function = function(e:MouseEvent):void {
				dragging = false;
				controller.enable();
				onEditEnd();
			}
			line.addEventListener(MouseEvent.MOUSE_DOWN, start);
			line.addEventListener(MouseEvent.MOUSE_MOVE, move);
			line.addEventListener(MouseEvent.MOUSE_UP, end);
			line.addEventListener(MouseEvent.MOUSE_OUT, end);
			line.addEventListener(MouseEvent.MOUSE_OVER, end);
		}
	}
}