package info.smoche.ThetaEXIF 
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import info.smoche.ThetaEXIF;
	import info.smoche.ThetaEXIF.Entry;
	import info.smoche.utils.Utils;
	/**
	 * ...
	 * @author Toshiyuki Suzumura
	 */
	public class ExifParser 
	{
		protected static const BYTE:uint = 1;
		protected static const ASCII:uint = 2;
		protected static const SHORT:uint = 3;
		protected static const LONG:uint = 4;
		protected static const RATIONAL:uint = 5;
		protected static const UNDEF:uint = 7;
		protected static const SLONG:uint = 9;
		protected static const SRATILNAL:uint = 10;
		protected static const SOI:uint = 0xffd8;
		protected static const EOI:uint = 0xffd9;
		protected static const SOS:uint = 0xffda;
		protected static const APPX:uint = 0xffe0;
		protected static const APP1:uint = 0xffe1;
		protected static const APP1_EXIF:uint = 0x8769;
		protected static const EXIF_MAKERNODE:uint = 0x927c;
		protected static const RICOH_RDC:uint = 0x0001;
		protected static const RICOH_ANALYZESCHEME:uint = 0x2001;
		protected static const RICOH_ANALYZESCHEME_KEY:String = "[Ricoh Camera Info]";
		protected static const RICOH_CPUVER:uint = 0x0002;
		protected static const RICOH_CAMERA_SERIAL:uint = 0x0005;
		protected static const RICOH_THETA:uint = 0x4001;
		protected static const THETA_ZENITH:uint = 0x0003;
		protected static const THETA_COMPASS:uint = 0x0004;
		protected static const THETA_ABNORMAL_ACCELEATION:uint = 0x0005;
		
		static protected function byteCompare(a:ByteArray, b:Object):Boolean
		{
			var x:ByteArray = new ByteArray();
			for each (var bi:Object in b) {
				if (bi is String) {
					x.writeMultiByte(String(bi), "iso-8859-1");
				} else {
					x.writeByte(int(bi));
				}
			}
			if (a.length != x.length) return false;
			a.position = 0;
			x.position = 0;
			var r:Boolean = true;
			for (var i:uint; i < a.length; i++) {
				if (a.readByte() != x.readByte()) {
					r = false;
					break;
				}
			}
			a.position = 0;
			return r;
		}
		
		static protected function toHex(val:uint, column:int = 0):String
		{
			var r:String = val.toString(16);
			if (column > 0) {
				return ("0000000000000000" + r).substr(16 + r.length - column, column);
			}
			return r;
		}
		
		protected var _cursor_stack:Vector.<uint> = new Vector.<uint>;
		protected var _cursor:uint;
		protected var _bigEndian:Boolean;
		protected var _data:ByteArray;
		
		protected function pushCursor(pos:int = -1):void
		{
			_cursor_stack.push(_cursor);
			if (pos >= 0) _cursor = pos;
		}
		protected function popCursor():void
		{
			_cursor = _cursor_stack.pop();
		}
		
		protected function read(len:uint, ofs:int = -1):ByteArray
		{
			var r:ByteArray;
			if (ofs == -1) {
				r = read(len, _cursor);
				_cursor += len;
			} else {
				r = new ByteArray();
				_data.position = ofs;
				_data.readBytes(r, 0, len);
			}
			return r;
		}
		
		
		static public function to_uint16e(bytes:ByteArray, bigEndian:Boolean):Vector.<uint>
		{
			var r:Vector.<uint> = new Vector.<uint>;
			bytes.position = 0;
			bytes.endian = (bigEndian)? Endian.BIG_ENDIAN: Endian.LITTLE_ENDIAN;
			for (var i:int = 0; i < bytes.length; i += 2) {
				var v:uint = bytes.readUnsignedShort();
				r.push(v);
			}
			return r;
		}
		protected function to_uint16(bytes:ByteArray):Vector.<uint>
		{
			return to_uint16e(bytes, _bigEndian);
		}
		
		static public function to_int32e(bytes:ByteArray, bigEndian:Boolean):Vector.<int>
		{
			var r:Vector.<int> = new Vector.<int>;
			bytes.position = 0;
			bytes.endian = (bigEndian)? Endian.BIG_ENDIAN: Endian.LITTLE_ENDIAN;
			for (var i:int = 0; i < bytes.length; i += 4) {
				var v:uint = bytes.readUnsignedInt();
				r.push(int(v));
			}
			return r;
		}
		protected function to_int32(bytes:ByteArray):Vector.<int>
		{
			return to_int32e(bytes, _bigEndian);
		}
		
		static public function to_uint32e(bytes:ByteArray, bigEndian:Boolean):Vector.<uint>
		{
			var r:Vector.<uint> = new Vector.<uint>;
			bytes.position = 0;
			bytes.endian = (bigEndian)? Endian.BIG_ENDIAN: Endian.LITTLE_ENDIAN;
			for (var i:int = 0; i < bytes.length; i += 4) {
				var v:uint = bytes.readUnsignedInt();
				r.push(v);
			}
			return r;
		}
		protected function to_uint32(bytes:ByteArray):Vector.<uint>
		{
			return to_uint32e(bytes, _bigEndian);
		}
		
		protected function to_rational(arr:Vector.<uint>):Vector.<Number>
		{
			var n:Number = NaN;
			var r:Vector.<Number> = new Vector.<Number>
			for each(var v:uint in arr) {
				if (isNaN(n)) {
					n = v;
				} else {
					r.push(n / Number(v));
					n = NaN;
				}
			}
			if (!isNaN(n)) throw "Not even members.";
			return r;
		}
		
		protected function to_srational(arr:Vector.<int>):Vector.<Number>
		{
			var n:Number = NaN;
			var r:Vector.<Number> = new Vector.<Number>
			for each(var v:int in arr) {
				if (isNaN(n)) {
					n = v;
				} else {
					r.push(n / Number(v));
					n = NaN;
				}
			}
			if (!isNaN(n)) throw "Not even members.";
			return r;
		}
		
		protected function readWord():uint
		{
			return to_uint16(read(2))[0];
		}
		protected function readDword():uint
		{
			return to_uint32(read(4))[0];
		}
		
		protected var _currentEntry:Entry;
		protected function readEntry():Entry
		{
			_currentEntry = new Entry(readWord(), readWord(), readDword(), read(4), _bigEndian);
			return _currentEntry;
		}
		
		protected var _ifd0Address:uint = 0;
		protected var _baseAddress:uint = 0;
		protected function seekToIFD0():void
		{
			if (_ifd0Address > 0) {
				_cursor = _ifd0Address;
				return;
			}
			_bigEndian = true;
			_cursor = 0;
			var mark:uint = readWord();
			if (mark != SOI) throw "SOI not found.";
			
			for (var i:uint; i < 32; i++) {
				mark = readWord();
				if (mark == APP1) {
					var len:uint = readWord();
					var ba:ByteArray = read(6);
					if (!byteCompare(ba, ["Exif", 0, 0])) {
						_cursor += len - 2 - 6;
						continue;
					}
					_baseAddress = _cursor;
					ba = read(2);
					_bigEndian = byteCompare(ba, ["MM"]);
					var v:uint = readWord();
					if (v != 0x002a) {
						throw "Invalid TIFF ID(0x" + toHex(v, 4) + ")";
					}
					v = readDword();
					_ifd0Address = _cursor + v - 8;
					return;
				}
				if (mark == SOI) throw "Invalid SOI found.";
				if (mark == EOI) throw "Invalid EOI found.";
				if (mark == SOS) throw "Invalid SOS found.";
				if (mark == 0xffff) continue;
				if ((0xff00 <= mark) && (mark <= 0xfffe)) {
					len = readWord();
					_cursor += len - 2;
					continue;
				}
				throw "Unknown marker: 0x" + toHex(mark, 4);
			}
			throw "APP1 not found.";
		}
		
		protected function eachTag(count:uint, block:Function):Boolean
		{
			for (var i:uint = 0; i < count; i++) {
				var r:Boolean = block(readEntry());
				if (!r) return false;
			}
			return true;
		}
		
		protected function findTag(count:uint, tag:uint):Entry
		{
			var r:Entry = null;
			pushCursor();
			eachTag(count, function(e:Entry):Boolean {
				if (e.code == tag) {
					r = e;
					return false;
				}
				return true;
			});
			popCursor();
			return r;
		}
		
		protected var _exifAddress:uint = 0;
		protected function seekToExifIFD():void
		{
			if (_exifAddress > 0) {
				_cursor = _exifAddress;
				return;
			}
			seekToIFD0();
			var e:Entry = findTag(readWord(), APP1_EXIF);
			if (e == null) throw "APP1-EXIF is not found.";
			_cursor = _exifAddress = _baseAddress + e.offset;
		}
		
		protected var _makernoteAddress:uint = 0;
		protected function seekToMakernote():void
		{
			if (_makernoteAddress > 0) {
				_cursor = _makernoteAddress;
				return;
			}
			seekToExifIFD();
			var e:Entry = findTag(readWord(), EXIF_MAKERNODE);
			if (e == null) throw "EXIF-MakerNote is not found.";
			_cursor = _makernoteAddress = _baseAddress + e.offset;
		}
		
		protected var _ricohAddress:uint = 0;
		protected function seekToRicohMakernote():void
		{
			if (_ricohAddress > 0) {
				_cursor = _ricohAddress;
				return;
			}
			seekToMakernote();
			if (!byteCompare(read(8), ["Ricoh", 0, 0, 0])) throw "Not a RICOH image.";
			pushCursor();
			var count:uint = readWord();
			var e:Entry = findTag(count, RICOH_RDC);
			if (e == null) throw "RDC is not found.";
			if (!byteCompare(e.data, ["Rdc", 0])) throw "Invalid RDC.";
			e = findTag(count, RICOH_ANALYZESCHEME);
			if (e == null) throw "AnalyzeScheme is not found.";
			if (!byteCompare(read(20, e.offset + _baseAddress), [RICOH_ANALYZESCHEME_KEY, 0])) {
				throw "\"" + RICOH_ANALYZESCHEME_KEY + "\" is not found.";
			}
			popCursor();
			_ricohAddress = _cursor;
		}
		
		protected var _thetaAddress:uint = 0;
		protected function seekToTheta():void
		{
			if (_thetaAddress > 0) {
				_cursor = _thetaAddress;
				return;
			}
			seekToRicohMakernote();
			var e:Entry = findTag(readWord(), RICOH_THETA);
			if (e == null) throw "THETA-tag is not found.";
			_cursor = _thetaAddress = _baseAddress + e.offset;
		}
		
		protected function readData():Object
		{
			var e:Entry = _currentEntry;
			var unitLength:uint = 1;
			switch (e.type) {
			case UNDEF:
			case BYTE:
			case ASCII:
				break;
			case SHORT:
				unitLength = 2;
				break;
			case LONG:
			case SLONG:
				unitLength = 4;
				break;
			case RATIONAL:
			case SRATILNAL:
				unitLength = 8;
				break;
			default:
				throw "Unknown type:0x" + toHex(e.type, 4);
			}
			
			var dataLen:uint = unitLength * e.length;
			var data:ByteArray;
			if (dataLen <= 4) {
				data = new ByteArray();
				e.data.position = 0;
				e.data.readBytes(data, 0, dataLen);
			} else {
				data = read(dataLen, _baseAddress + e.offset);
			}
			
			switch (e.type) {
			case UNDEF:
			case BYTE:
			case ASCII:
				break;
			case SHORT:
				return this.to_uint16(data);
			case LONG:
				return this.to_uint32(data);
			case SLONG:
				return to_int32(data);
			case RATIONAL:
				return to_rational(to_uint32(data));
			case SRATILNAL:
				return to_srational(to_int32(data));
			}
			
			return data;
		}
		
		protected function dumpCurrent():void
		{
			pushCursor();
			Utils.Trace("0x" + toHex(_cursor));
			var count:uint = readWord();
			for (var i:uint = 0; i < count; i++) {
				var e:Entry = readEntry();
				var u:Object = readData();
				var s:Object = (e.type != UNDEF)? u: "<binary>";
				Utils.Trace("(" + i + ") " + toHex(e.code, 4) + " " + toHex(e.type, 4) + " " + e.length + " " + toHex(e.offset, 8) + " " + s);
			}
			popCursor();
		}
		
		protected function find(count:uint, tag:uint, block:Function):void
		{
			var e:Entry = findTag(count, tag);
			block(readData());
		}
		
		public function parseTags(r:ThetaEXIF):void
		{
			seekToRicohMakernote();
			var count:uint = readWord();
			find(count, RICOH_CPUVER, function(e:Object):void {
				r.cpu_version = String(e);
			});
			find(count, RICOH_CAMERA_SERIAL, function(e:Object):void {
				r.serial = String(e);
			});
			seekToTheta();
			count = readWord();
			find(count, THETA_ZENITH, function(e:Object):void {
				r.roll = e[0];
				r.pitch = e[1];
			});
			find(count, THETA_COMPASS, function(e:Object):void {
				r.yaw = e[0];
			});
			find(count, THETA_ABNORMAL_ACCELEATION, function(e:Object):void {
				r.abnormal_acceleation = e[0];
			});
		}
		
		public function ExifParser(bytes:ByteArray)
		{
			_data = new ByteArray();
			bytes.position = 0;
			bytes.readBytes(_data, 0, 65536);
		}
	}
}