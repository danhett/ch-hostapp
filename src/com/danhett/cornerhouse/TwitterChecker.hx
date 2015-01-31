package com.danhett.cornerhouse;

import StringTools;
import haxe.crypto.Base64;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IOErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;
import openfl.net.URLRequestHeader;
import haxe.io.Bytes;

class TwitterChecker extends EventDispatcher 
{
	private var key:String;
	private var secret:String;
	private var bearerToken:String;

	public function new() 
	{
		super();
	}

	public function setupTwitter(_key:String, _secret:String):Void
	{
		trace("Setting up twitter...");

		key = StringTools.urlEncode(_key);
		secret = StringTools.urlEncode(_secret);

		var ld:URLLoader = new URLLoader();
		var variables = new URLVariables();

		var bytes:Bytes = Bytes.ofString(key + ":" + secret);

		var authHeader:URLRequestHeader = new URLRequestHeader("Authorization", "Basic " + Base64.encode(bytes));
		
		var req:URLRequest = new URLRequest("https://api.twitter.com/oauth2/token");
    	req.method = URLRequestMethod.POST;
    	req.requestHeaders.push(authHeader);
       	req.contentType = "application/x-www-form-urlencoded;charset=UTF-8";
    	req.data = "grant_type=client_credentials";

    	// TODO - add handling for bad HTTP statuses and whatever else
    	ld.addEventListener(Event.COMPLETE, onComplete);

    	ld.load(req);
	}

	private function onComplete(e:Event):Void
	{
		bearerToken = haxe.Json.parse(e.target.data).access_token;
		trace("Token: " + bearerToken);

		getTweetList();
	}

	private function getTweetList():Void
	{
		var ld:URLLoader = new URLLoader();
		var variables = new URLVariables();

		var req:URLRequest = new URLRequest("https://api.twitter.com/1.1/search/tweets.json?q=%40cornerhouse");
		var authHeader:URLRequestHeader = new URLRequestHeader("Authorization", "Bearer " + bearerToken);
    	req.requestHeaders.push(authHeader);

    	// TODO - add handling for bad HTTP statuses and whatever else
    	ld.addEventListener(Event.COMPLETE, showTweets);
    	
    	ld.load(req);
	}

	private function showTweets(e:Event):Void
	{
		trace(e.target.data);
	}
}




