/*
The MIT License (MIT)

Copyright (c) 2015 Dan Hett
See: https://github.com/danhett/ch-hostapp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

package com.danhett.cornerhouse;

import haxe.xml.Fast;
import openfl.events.Event;
import openfl.events.EventDispatcher;

class Config extends EventDispatcher 
{
	public var LIVE:Bool;
	public var MONGO_URL:String;
	public var MONGO_PORT:Int;
	public var LOGIN:String;
	public var PASS:String;
	public var SECONDS:Int;
	public var PRINT_SECONDS:Int;
	public var TWITTER_QUERY_SECONDS:Int;
	public var TWITTER_HASHTAG:String;
	public var CONSUMER_KEY:String;
	public var CONSUMER_SECRET:String;

	private var fast:Fast;

	public function new() 
	{
		super();
	}

	public function loadConfig(path:String):Void
	{
		var xml = Xml.parse(sys.io.File.getContent(path));
		fast = new Fast(xml.firstElement());

		LIVE = fast.node.isLive.innerData == "true" ? true : false;

		// Divert to the correct database depending on if we're live or not
		if(LIVE)
		{
			MONGO_URL = fast.node.live_db.innerData;
			MONGO_PORT = Std.parseInt(fast.node.live_port.innerData);
			LOGIN = fast.node.live_username.innerData;
			PASS = fast.node.live_password.innerData;
		}
		else
		{
			MONGO_URL = fast.node.test_db.innerData;
			MONGO_PORT = Std.parseInt(fast.node.test_port.innerData);
			LOGIN = fast.node.test_username.innerData;
			PASS = fast.node.test_password.innerData;
		}
		
		SECONDS = Std.parseInt(fast.node.seconds.innerData);
		PRINT_SECONDS = Std.parseInt(fast.node.printSeconds.innerData);

		TWITTER_QUERY_SECONDS = Std.parseInt(fast.node.twitterQuerySeconds.innerData);
		TWITTER_HASHTAG = fast.node.twitterHashtag.innerData;
		CONSUMER_KEY = fast.node.consumerKey.innerData;
		CONSUMER_SECRET = fast.node.consumerSecret.innerData;

		this.dispatchEvent(new Event(Event.COMPLETE));
	}
}