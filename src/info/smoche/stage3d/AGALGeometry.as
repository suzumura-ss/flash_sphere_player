package info.smoche.stage3d 
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	/**
	 * ...
	 * @author ...
	 */
	public class AGALGeometry 
	{
		protected var _context3D:Context3D;
		protected var _vertexBuffer:VertexBuffer3D;
		protected var _indexBuffer:IndexBuffer3D;
		
		public var vertexName:String = "_position";
		public var vertexOffset:int = 0;
		public var vertexFormat:String = Context3DVertexBufferFormat.FLOAT_3;
		
		public var texcoordName:String = "_texcoord";
		public var texcoordOffset:int = -1;
		public var texcoordFormat:String = Context3DVertexBufferFormat.FLOAT_2;
		
		public var normalName:String = "_normal";
		public var normalOffset:int = -1;
		public var normalFormat:String = Context3DVertexBufferFormat.FLOAT_3;
		
		public var colorName:String = "_color";
		public var colorOffset:int = -1;
		public var colorFormat:String = Context3DVertexBufferFormat.FLOAT_4;
		
		
		public function AGALGeometry(context3D:Context3D, verts:Vector.<Number>, index:Vector.<uint>, hasTexcoord:Boolean = true, hasNormal:Boolean = false, hasColor:Boolean = false)
		{
			_context3D = context3D;
			
			var unit:int = 3;
			if (hasTexcoord) {
				texcoordOffset = unit;
				unit += 2;
			}
			if (hasNormal) {
				normalOffset = unit;
				unit += 3;
			}
			if (hasColor) {
				colorOffset = unit;
				unit += 4;
			}
			_vertexBuffer = _context3D.createVertexBuffer(verts.length / unit, unit);
			_vertexBuffer.uploadFromVector(verts, 0, verts.length / unit);
			_indexBuffer = _context3D.createIndexBuffer(index.length);
			_indexBuffer.uploadFromVector(index, 0, index.length);
		}
		
		protected function attach(program:AGALProgram):void
		{
			var u:Uniform;
			
			u = program.findUniform(vertexName);
			_context3D.setVertexBufferAt(u.index, _vertexBuffer, vertexOffset, vertexFormat);
			if (texcoordOffset > 0) {
				u = program.findUniform(texcoordName);
				_context3D.setVertexBufferAt(u.index, _vertexBuffer, texcoordOffset, texcoordFormat);
			}
			if (normalOffset > 0) {
				u = program.findUniform(normalName);
				_context3D.setVertexBufferAt(u.index, _vertexBuffer, normalOffset, normalFormat);
			}
			if (colorOffset > 0) {
				u = program.findUniform(colorName);
				_context3D.setVertexBufferAt(u.index, _vertexBuffer, colorOffset, colorFormat);
			}
		}
		
		public function draw(program:AGALProgram):void
		{
			attach(program);
			_context3D.drawTriangles(_indexBuffer);
		}
	}
}
