package  
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.DrawUnit;
	import alternativa.engine3d.resources.TextureResource;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.utils.Dictionary;
	import info.smoche.alternativa.NonMipmapTextureMaterial;
	
	use namespace alternativa3d;
	/**
	 * ...
	 * @author Toshiyuki Suzumura  / @suzumura_ss
	 */
	public class AdjustTextuteMaterial extends NonMipmapTextureMaterial 
	{
		protected var _texture2:TextureResource;
		protected var _yaw_offset:Number = 0;
		
		public function AdjustTextuteMaterial(texture:TextureResource, texture2:TextureResource, alpha:Number, context3d:Context3D)
		{
			super(texture, alpha, context3d);
			_texture2 = texture2;
		}
		
		public function get yaw_offset():Number
		{
			return _yaw_offset;
		}
		public function set yaw_offset(v:Number):void
		{
			_yaw_offset = v;
		}
		
		override alternativa3d function fillResources(resources:Dictionary, resourceType:Class):void 
		{
			super.fillResources(resources, resourceType);
			if (_texture2 != null) {
				resources[_texture2] = true;
			}
		}
		
		override protected function loadProgram():void 
		{
			_vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, [
				"m44 op, va0, vc0", 	// op = va0[pos] * vc0[projection]
				"mov v0, va1", 			// v0 = va1[uv]
			].join("\n"));
			
			_fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, [
				"tex ft0, v0, fs0 <2d,linear,repeat>", 	// oc = sampler2d(fs0, v0[uv]) * fc1.x
				"mul ft0, ft0, fc1.x",
				
				"add ft2, v0, fc0",
				"sub ft2.x, fc1.z, ft2.x",
				"tex ft1, ft2, fs1 <2d,linear,repeat>", //    + sampler2d(fs1, v0[uv]+fc0) * fc1.y
				"mul ft1, ft1, fc1.y",
				
				"add oc, ft0, ft1",
			].join("\n"));
		}
		
		override protected function setupExtraUniforms(drawUnit:DrawUnit):void 
		{
			super.setupExtraUniforms(drawUnit);
			drawUnit.setTextureAt(1, _texture2._texture);
			drawUnit.setFragmentConstantsFromNumbers(0, -_yaw_offset, 0, 0, 0);
			drawUnit.setFragmentConstantsFromNumbers(1, alpha, 1 - alpha, 1.0, 0);
		}
	}
}