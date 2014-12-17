package org.mongodb;

import haxe.Int64;

class Cursor
{
	public function new(collection:Collection, query:Dynamic, returnFields:Dynamic, skip:Int, number:Int)
	{
		this.collection = collection;
		this.query = query;
		this.returnFields = returnFields;
		noSkip = skip;
		noReturn = number;
		noLimit = 0;

		cnx = collection.db.mongo.cnx;
		cursorId = null;  // marks that no query was executed yet
		finished = false;
		documents = [];
		retCnt = 0;
	}

	private inline function checkResponse()
	{
		trace("checkResponse: " + untyped [finished, cursorId, documents.length, noLimit, noReturn, retCnt]);
		cursorId = cnx.response(documents);
		if (documents.length == 0)
		{
			trace("done");
			finished = true;
			if (cursorId != null)
			{
				trace("killing cursor");
				cnx.killCursors([cursorId]);
				cursorId = null;
			}
		}
		retCnt += documents.length;
	}

	private inline function getMore():Void
	{
		trace("getMore: " + untyped [finished, cursorId, documents.length, noLimit, noReturn, retCnt]);

		if (finished)
			return;

		if (cursorId == null)
		{
			// the query was not submitted yet
			cnx.query(collection.fullname, query, returnFields, noSkip, noReturn);
			checkResponse();
		}
		else if (noLimit == 0 || noLimit < retCnt)
		{
			// just try to get more results
			var noRet;
			if (noLimit == 0)
			{
				noRet = noReturn;
			}
			else
			{
				noRet = noLimit - retCnt;
				if (noRet > noReturn)
					noRet = noReturn;
			}
			trace(noRet);
			cnx.getMore(collection.fullname, cursorId, noRet);
			checkResponse();
			trace(retCnt);
		}
	}

	public function hasNext():Bool
	{
		trace("hasNext: " + untyped [finished, cursorId, documents.length, noLimit, noReturn, retCnt]);
		if (documents.length == 0)
		{
			getMore();
		}
		return !finished && documents.length != 0;
	}

	public function next():Dynamic
	{
		trace("next: " + untyped [finished, cursorId, documents.length, noLimit, noReturn, retCnt]);
		if (documents.length == 0)
		{
			getMore();
		}
		return documents.shift();
	}
	
	public function limit(number:Int):Cursor
	{
		if (cursorId != null)
			throw "Cursor.limit() must be used before retrieving anything";
		noReturn = noLimit = number;
		return this;
	}

	public function skip(number:Int):Cursor
	{
		if (cursorId != null)
			throw "Cursor.skip() must be used before retrieving anything";
		noSkip = number;
		return this;
	}

	public function sort(spec:Dynamic):Cursor
	{
		if (cursorId != null)
			throw "Cursor.sort() must be used before retrieving anything";
		addQueryElement("$orderby", spec);
		return this;
	}

	public function toArray():Array<Dynamic>
	{
		if (cursorId != null)
			throw "Cursor.toArray() must be used before retrieving anything";
		var ret = [];
		for (x in this)
			ret.push(x);
		return ret;
	}

	private function addQueryElement(name:String, el:Dynamic):Void
	{
		if (query == null)
			query = {};
		if (!Reflect.hasField(query, "$query"))
			query = { "$query" : query };
		Reflect.setField(query, name, el);
	}

	public var collection(default, null):Collection;
	private var query:Dynamic;
	private var returnFields:Dynamic;
	private var noSkip:Int;
	private var noReturn:Int;
	private var noLimit:Int;

	private var cnx:Protocol;
	private var cursorId:Int64;
	private var documents:Array<Dynamic>;
	private var finished:Bool;
	private var retCnt:Int;
}

