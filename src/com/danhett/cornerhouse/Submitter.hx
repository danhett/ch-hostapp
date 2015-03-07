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

import com.danhett.App;
import StringTools;
import haxe.crypto.Base64;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.TimerEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLRequestHeader;
import openfl.utils.Timer;
import haxe.io.Bytes;

class Submitter extends EventDispatcher 
{
	private var loader:URLLoader;
	private var req:URLRequest;

	public function new() 
	{
		super();

		loader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.TEXT;
       	loader.addEventListener(Event.COMPLETE, onComplete);
    	loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
    	loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatusEvent);
	}

	public function submit(msg:Dynamic):Void
	{
		req = new URLRequest("http://scribble.ricklab.net/message");
		req.data = "token=54eee71d33085" 
				 + "&messageType=tweet"
				 + "&submitter=" + StringTools.urlEncode(msg.submitter)
				 + "&submitDate=" + StringTools.urlEncode(msg.submitDate)
				 + "&message=" + StringTools.urlEncode(msg.message)
				 + "&email=";
		req.method = URLRequestMethod.POST;
		req.contentType = "application/x-www-form-urlencoded;charset=UTF-8";

		loader.load(req);
	}

	private function onComplete(e:Event):Void
	{
		App.Instance().log("SUCCESS: Tweet submitted successfully to database.");
	}

	private function onIOError(e:IOErrorEvent):Void
	{
		App.Instance().log("ERROR: IOError when submitting tweet to database.");
	}

	private function onHTTPStatusEvent(e:HTTPStatusEvent):Void
	{
		if(e.status != 201 && e.status != 400) // i.e. if it didn't succeed
			App.Instance().log("Message HTTP status: " + e.status);

		if(e.status == 400)
			App.Instance().log("Profanity found in message. Pushing to DB but not printing.");
	}
}




