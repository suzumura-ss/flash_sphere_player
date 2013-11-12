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
		
		public function FlatSlider(min:Number, max:Number, init:Number, width:Number, controller:SimpleObjectController)
		{
			super();
			
			var bmp:Bitmap = new CIRCLE() as Bitmap;
			var button:SimpleButton = new SimpleButton(bmp, bmp, bmp, bmp);
			button.mouseEnabled = false;
			
			_min = min;
			_max = max;
			_current = init;
			_width = width;
			
			bmp = new Bitmap(new BitmapData(width + button.width, bmp.height, false, 0x86c351));
			var line:SimpleButton = new SimpleButton(bmp, bmp, bmp, bmp);
			line.alpha = 0.5;
			addChild(line);
			addChild(button);
			
			var label:TextField = new TextField();
			label.text = "0.00";
			label.width = 50;
			label.height = 20;
			label.x = (line.width - label.width) / 2;
			label.y = (line.height - label.height) / 2;
			label.mouseEnabled = false;
			addChild(label);
			
			var update:Function = function():void {
				label.text = _current.toFixed(2);
				button.x = (_current - _min) * _width / (_max - _min);
			}
			update();
			
			var dragging:Boolean = false;
			var e:MouseEvent;
			var move:Function = function(e:MouseEvent):void {
				if (dragging) {
					var v:Number = (e.localX - button.width / 2) * (_max - _min) / _width + _min;
					if (v < _min) {
						v = _min;
					} else if (v > _max) {
						v = _max;
					}
					_current = v;
					update();
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