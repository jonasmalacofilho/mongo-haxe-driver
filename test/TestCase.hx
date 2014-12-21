class TestCase extends haxe.unit.TestCase
{
	// rough/simplified assertSame
	public function assertSame(exp:Dynamic, got:Dynamic, ?c:haxe.PosInfos):Void
	{
		function checkField(field)
		{
			// get fields and shadow exp and got
			var exp = Reflect.field(exp, field);
			var got = Reflect.field(got, field);
			// if either is a function, so must the other; otherwise, recurse
			if (Reflect.isFunction(exp) || Reflect.isFunction(got))  // isFunction(null) == false
				assertEquals(Reflect.isFunction(exp), Reflect.isFunction(got), c)
			else
				assertSame(exp, got, c);
		}

		switch (Type.typeof(exp))
		{
			case TObject:
				for (f in Reflect.fields(exp))
					checkField(f);
			case TClass(c):
				for (f in Type.getInstanceFields(c))
					checkField(f);
			case all:
				assertEquals(exp, got, c);
		}
	}
}

