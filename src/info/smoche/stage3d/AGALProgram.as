package info.smoche.stage3d 
{
	import com.adobe.utils.AGALMiniAssembler;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	/**
	 * ...
	 * @author ...
	 */
	public class AGALProgram
	{
		protected var _program:Program3D;
		protected var _context3D:Context3D;
		protected var _uniforms:Dictionary = new Dictionary();
		
		public function AGALProgram(context3D:Context3D, vertexSource:Object, fragmentSource:Object)
		{
			_program = context3D.createProgram();
			_context3D = context3D;
			
			initUniformsDict();
			var vsh:ByteArray = complile(Context3DProgramType.VERTEX, vertexSource);
			var fsh:ByteArray = complile(Context3DProgramType.FRAGMENT, fragmentSource);
			_program.upload(vsh, fsh);
		}
		
		public function attach():Context3D
		{
			_context3D.setProgram(_program);
			return _context3D;
		}
		
		public function context(callback:Function):void
		{
			_context3D.setProgram(_program);
			callback(_context3D);
		}
		
		public function setMatrix3D(name:String, val:Matrix3D, transposedMatrix:Boolean=true):void
		{
			var u:Uniform = findUniform(name);
			_context3D.setProgramConstantsFromMatrix(u.type, u.index, val, transposedMatrix);
		}
		
		public function setVector(name:String, val:Vector.<Number>, startIndex:int = 0, length:int = -1):void
		{
			var u:Uniform = findUniform(name);
			if (startIndex==0) {
				_context3D.setProgramConstantsFromVector(u.type, u.index, val, length);
			} else if (length < 0) {
				_context3D.setProgramConstantsFromVector(u.type, u.index, val.slice(startIndex));
			} else {
				_context3D.setProgramConstantsFromVector(u.type, u.index, val.slice(startIndex, startIndex + length));
			}
		}
		
		public function setNumbers(name:String, x:Number, y:Number = 0, z:Number = 0, w:Number = 0):void
		{
			var u:Uniform = findUniform(name);
			_context3D.setProgramConstantsFromVector(u.type, u.index, Vector.<Number>([x, y, z, w]));
		}
		
		public function setTexture(name:String, texture:TextureBase):void
		{
			var u:Uniform = findUniform(name);
			_context3D.setTextureAt(u.index, texture);
		}
		
		public function drawGeometry(geom:AGALGeometry):void
		{
			geom.draw(this);
		}
		
		protected static const uPosition:Uniform = new Uniform(Context3DProgramType.VERTEX, 0);
		protected static const uTexcoord:Uniform = new Uniform(Context3DProgramType.VERTEX, 1);
		protected static const uNormal:Uniform = new Uniform(Context3DProgramType.VERTEX, 2);
		protected static const uColor:Uniform = new Uniform(Context3DProgramType.VERTEX, 3);
		protected static const uProjection:Uniform = new Uniform(Context3DProgramType.VERTEX, 0);
		
		protected function initUniformsDict():void
		{
			_uniforms["_position"] = uPosition;
			_uniforms["_texcoord"] = uTexcoord;
			_uniforms["_normal"] = uNormal;
			_uniforms["_color"] = uColor;
			_uniforms["modelViewProjectionMatrix"] = uProjection;
		}
		
		protected function complile(programType:String, source:Object):ByteArray
		{
			if (getQualifiedClassName(source) == "String") {
				source = source.split("\n");
			}
			var line:String = source.map(function(item:String, index:int, array:Array):String {
				if (item.match(/^#/)) {
					var arg:Array = item.split(/[#=]/).map(function(i:String, n:int, a:Array):String {
						return i.replace(/[ \t]/g, "");
					});
					if (_uniforms[arg[1]]) {
						throw "Uniform name is duplicated: " + arg[1];
					}
					_uniforms[arg[1]] = new Uniform(programType, arg[2]);
					item = "";
				}
				return item.replace(/^[ ]+/, "");
			}).join("\n");
			var asm:AGALMiniAssembler = new AGALMiniAssembler();
			asm.assemble(programType, line);
			return asm.agalcode;
		}
		
		public function findUniform(name:String):Uniform
		{
			var r:Uniform = _uniforms[name];
			if (r == null) throw "Invalid uniform name: " + name;
			return r;
		}
	}
}
