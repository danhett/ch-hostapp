package com.danhett.cornerhouse;

import haxe.xml.Fast;
import openfl.events.Event;
import openfl.events.EventDispatcher;

class Config extends EventDispatcher 
{
	public var MONGO_URL:String;
	public var MONGO_PORT:Int;
	public var LOGIN:String;
	public var PASS:String;
	public var SECONDS:Int;

	private var fast:Fast;

	public function new() 
	{
		super();
	}

	public function loadConfig(path:String):Void
	{
		var xml = Xml.parse(sys.io.File.getContent(path));
		fast = new Fast(xml.firstElement());

		MONGO_URL = fast.node.db.innerData;
		MONGO_PORT = Std.parseInt(fast.node.port.innerData);
		LOGIN = fast.node.username.innerData;
		PASS = fast.node.password.innerData;
		SECONDS = Std.parseInt(fast.node.seconds.innerData);

		this.dispatchEvent(new Event(Event.COMPLETE));
	}
}