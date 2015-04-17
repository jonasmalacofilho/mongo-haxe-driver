package org.bsonspec;

import haxe.crypto.BaseCode;
import haxe.io.*;

@:forward abstract ObjectID(ObjectIDImpl) from ObjectIDImpl to ObjectIDImpl
{
	public function new(?input:Input)
	{
		this = new ObjectIDImpl(input);
	}

	@:from public static function fromString(hex:String)
	{
		var bhex = Bytes.ofString(hex.toLowerCase());
		var dec = new BaseCode(Bytes.ofString("0123456789abcdef"));
		var bytes = dec.decodeBytes(bhex);
		return new ObjectID(new BytesInput(bytes));
	}
}

class ObjectIDImpl
{

	public function new(?input:Input)
	{
		if (input == null)
		{
			// generate a new id
			var out:BytesOutput = new BytesOutput();
#if haxe3
			out.writeInt32(Math.floor(Date.now().getTime() / 1000)); // seconds
#else
			out.writeInt32(haxe.Int32.ofInt(Math.floor(Date.now().getTime() / 1000))); // seconds
#end
			out.writeBytes(machine, 0, 3);
			out.writeUInt16(pid);
			out.writeUInt24(sequence++);
			if (sequence > 0xFFFFFF) sequence = 0;
			bytes = out.getBytes();
		}
		else
		{
			bytes = Bytes.alloc(12);
			input.readBytes(bytes, 0, 12);
		}
	}

	public function toString():String
	{
		return 'ObjectID("' + bytes.toHex() + '")';
	}

	public function valueOf():String
	{
		return bytes.toHex();
	}

	public var bytes(default, null):Bytes;
	private static var sequence:Int = 0;

	// machine host name
#if (neko || php || cpp)
	private static var machine:Bytes = Bytes.ofString(sys.net.Host.localhost());
#else
	private static var machine:Bytes = Bytes.ofString("flash");
#end
	private static var pid = Std.random(65536);

}

